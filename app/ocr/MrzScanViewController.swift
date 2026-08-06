//
//  MrzScanViewController.swift
//  libjeid-ios-app
//
//  Copyright © 2026 Open Source Solution Technology Corporation
//  All rights reserved.
//

import AVFoundation
import UIKit
import Vision
import os

/// MRZ読み取り結果を受け取るデリゲート。
protocol MrzScanViewControllerDelegate: AnyObject {
    /// MRZの読み取りに成功したときに呼ばれます。
    ///
    /// - Parameters:
    ///   - controller: 読み取りを行った画面
    ///   - documentNumber: パスポート番号
    ///   - birthDate: 生年月日(MRZと同じYYMMDDの6桁)
    ///   - expirationDate: 有効期限(MRZと同じYYMMDDの6桁)
    func mrzScanViewController(
        _ controller: MrzScanViewController,
        didScan documentNumber: String,
        birthDate: String,
        expirationDate: String)
}

/// パスポートのMRZをカメラで読み取る全画面モーダル。
///
/// 認識にはVisionフレームワークを用いる。処理はすべて端末内で行われ、
/// 券面画像が外部へ送出されることはない。
///
/// チェックデジット検証を通った結果が2フレーム分一致したところで確定する。
/// Android版(MrzScanFragment)と同じ判定・同じ画面構成とする。
class MrzScanViewController: UIViewController,
    AVCaptureVideoDataOutputSampleBufferDelegate
{
    weak var delegate: MrzScanViewControllerDelegate?

    /// 解析対象とする領域(プレビュー表示範囲に対する比率)。
    /// ガイド枠(幅0.90、高さ0.16)より広く取り、多少のずれを許容する。
    private static let roiWidthRatio = CGFloat(0.96)
    private static let roiHeightRatio = CGFloat(0.30)

    /// この時間内に読み取れない場合はヒントを表示する。
    private static let hintDelaySeconds = TimeInterval(15)

    /// 端末のログ(`log stream` / `idevicesyslog`)へ出すためのロガー。
    /// `print()` は標準出力にしか出ずデバッガ接続なしでは見えないため使わない。
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "jp.co.osstech.jeidreader",
        category: "MrzScan")

    private var previewView: UIView!
    private var overlayView: MrzGuideOverlayView!
    private var statusLabel: UILabel!
    private var torchButton: UIButton!

    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private let videoOutput = AVCaptureVideoDataOutput()
    /// フレーム解析を行う直列キュー。キュー上の処理は逐次実行されるため、
    /// Visionのリクエストと `pendingResult` はこのキューに閉じて扱う。
    private let analysisQueue = DispatchQueue(
        label: "jp.co.osstech.jeidreader.mrzscan")
    private let textRequest = VNRecognizeTextRequest()
    private var captureDevice: AVCaptureDevice?
    private var torchEnabled = false
    /// カメラの開始処理を一度だけ行うためのフラグ。
    private var hasStarted = false

    /// 検証を通過した直前のフレームの結果。2フレームの一致を確認するために保持する。
    /// 解析キュー上でのみ参照・更新する。
    private var pendingResult: MrzScanResult?

    /// メインスレッドと解析キューの双方から触る状態を保護する。
    private let stateLock = NSLock()
    private var unsafeCompleted = false
    private var unsafePreviewSize = CGSize.zero

    /// 結果を返した後、または画面を閉じた後にフレームの処理を止めるためのフラグ。
    private var completed: Bool {
        get {
            stateLock.lock()
            defer { stateLock.unlock() }
            return unsafeCompleted
        }
        set {
            stateLock.lock()
            unsafeCompleted = newValue
            stateLock.unlock()
        }
    }

    /// プレビューの表示寸法。解析範囲の算出に使う。
    private var previewSize: CGSize {
        get {
            stateLock.lock()
            defer { stateLock.unlock() }
            return unsafePreviewSize
        }
        set {
            stateLock.lock()
            unsafePreviewSize = newValue
            stateLock.unlock()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .fullScreen
        textRequest.recognitionLevel = .accurate
        // MRZは辞書に無い文字列のため、言語補正は誤りの元になる
        textRequest.usesLanguageCorrection = false
        textRequest.recognitionLanguages = ["en-US"]
    }

    // 端末は縦に持ち、パスポートを横向きに置いて写す運用に固定する。
    // MRZは横長なので端末も横に持つほうが1文字あたりの画素は稼げる(長辺を使えるため
    // およそ倍)が、回転を許すとプレビューと撮影バッファの向きを追従させる処理が要る。
    // 縦持ちの解像度でも読めているため、運用を1通りに絞ることを優先している。
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override var preferredInterfaceOrientationForPresentation:
        UIInterfaceOrientation
    {
        return .portrait
    }

    override func loadView() {
        let size = CustomViewUtil.screenSize
        let root = UIView()
        root.backgroundColor = .black

        previewView = UIView()
        previewView.backgroundColor = .black
        previewView.translatesAutoresizingMaskIntoConstraints = false

        overlayView = MrzGuideOverlayView()
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.isHidden = true

        statusLabel = UILabel()
        statusLabel.text = "パスポート下部の2行(MRZ)を枠に合わせてください。"
        statusLabel.textColor = .white
        statusLabel.font = CustomViewUtil.createSmallTextFont(size)
        statusLabel.numberOfLines = 0
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        torchButton = CustomViewUtil.createButton(size)
        torchButton.setTitle("ライトを点ける", for: .normal)
        torchButton.isEnabled = false
        torchButton.addTarget(
            self, action: #selector(pushTorchButton), for: .touchUpInside)

        let manualButton = CustomViewUtil.createButton(size)
        manualButton.setTitle("手入力に戻る", for: .normal)
        manualButton.addTarget(
            self, action: #selector(pushManualButton), for: .touchUpInside)

        let buttonStackView = UIStackView(
            arrangedSubviews: [torchButton, manualButton])
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillEqually
        buttonStackView.spacing = 8
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false

        root.addSubview(previewView)
        previewView.addSubview(overlayView)
        previewView.addSubview(statusLabel)
        root.addSubview(buttonStackView)

        let padding = CGFloat(8)
        let guide = root.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            previewView.topAnchor.constraint(equalTo: root.topAnchor),
            previewView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            previewView.bottomAnchor.constraint(
                equalTo: buttonStackView.topAnchor, constant: -padding),

            overlayView.topAnchor.constraint(equalTo: previewView.topAnchor),
            overlayView.leadingAnchor.constraint(
                equalTo: previewView.leadingAnchor),
            overlayView.trailingAnchor.constraint(
                equalTo: previewView.trailingAnchor),
            overlayView.bottomAnchor.constraint(
                equalTo: previewView.bottomAnchor),

            statusLabel.topAnchor.constraint(
                equalTo: guide.topAnchor, constant: padding * 2),
            statusLabel.leadingAnchor.constraint(
                equalTo: previewView.leadingAnchor, constant: padding * 2),
            statusLabel.trailingAnchor.constraint(
                equalTo: previewView.trailingAnchor, constant: -padding * 2),

            buttonStackView.leadingAnchor.constraint(
                equalTo: guide.leadingAnchor, constant: padding),
            buttonStackView.trailingAnchor.constraint(
                equalTo: guide.trailingAnchor, constant: -padding),
            buttonStackView.bottomAnchor.constraint(
                equalTo: guide.bottomAnchor, constant: -padding),
        ])

        self.view = root
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewView.layer.insertSublayer(previewLayer, at: 0)

        DispatchQueue.main.asyncAfter(
            deadline: .now() + Self.hintDelaySeconds
        ) { [weak self] in
            guard let self = self, !self.completed, self.view.window != nil
            else {
                return
            }
            self.statusLabel.text =
                "読み取れない場合は、明るい場所で券面を平らにして枠いっぱいに写してください。"
                + "手入力に戻ることもできます。"
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 権限が無い場合にアラートを出すため、画面が表示されてから開始する
        if hasStarted {
            return
        }
        hasStarted = true
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            startCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self = self else {
                        return
                    }
                    if granted {
                        self.startCamera()
                    } else {
                        self.showErrorAndDismiss(
                            "カメラの使用が許可されていないため、MRZ読み取りを利用できません")
                    }
                }
            }
        default:
            showErrorAndDismiss(
                "カメラの使用が許可されていないため、MRZ読み取りを利用できません")
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = previewView.bounds
        previewSize = previewView.bounds.size
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopCamera()
    }

    // MARK: - カメラ

    private func startCamera() {
        analysisQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            guard self.configureSession() else {
                self.log("failed to configure capture session")
                DispatchQueue.main.async {
                    self.showErrorAndDismiss("カメラを起動できませんでした")
                }
                return
            }
            self.captureSession.startRunning()
            DispatchQueue.main.async {
                self.overlayView.isHidden = false
                self.torchButton.isEnabled =
                    self.captureDevice?.hasTorch ?? false
                self.previewSize = self.previewView.bounds.size
            }
        }
    }

    private func configureSession() -> Bool {
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }
        // 縦向きへ回転したバッファの横幅は短辺(1080)になる。
        // MRZ44文字がこの幅に収まる解像度として1920x1080を要求する。
        if captureSession.canSetSessionPreset(.hd1920x1080) {
            captureSession.sessionPreset = .hd1920x1080
        } else {
            captureSession.sessionPreset = .high
        }
        guard
            let device = AVCaptureDevice.default(
                .builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: device),
            captureSession.canAddInput(input)
        else {
            return false
        }
        captureSession.addInput(input)
        captureDevice = device

        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String:
                kCVPixelFormatType_32BGRA
        ]
        // 解析が追いつかないフレームは捨て、常に最新のフレームを処理する
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: analysisQueue)
        guard captureSession.canAddOutput(videoOutput) else {
            return false
        }
        captureSession.addOutput(videoOutput)
        // 縦向き固定で撮影し、プレビューの表示範囲とバッファの向きを一致させる
        if let connection = videoOutput.connection(with: .video),
            connection.isVideoOrientationSupported
        {
            connection.videoOrientation = .portrait
        }
        configureFocus(device)
        return true
    }

    /// 券面を至近距離で写すため、近距離側へ絞ってピント合わせを速くする。
    private func configureFocus(_ device: AVCaptureDevice) {
        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            if device.isAutoFocusRangeRestrictionSupported {
                device.autoFocusRangeRestriction = .near
            }
        } catch {
            log("failed to configure focus: \(error)")
        }
    }

    private func stopCamera() {
        completed = true
        setTorch(false)
        let captureSession = self.captureSession
        analysisQueue.async {
            if captureSession.isRunning {
                captureSession.stopRunning()
            }
        }
    }

    private func setTorch(_ enabled: Bool) {
        guard let device = captureDevice, device.hasTorch else {
            return
        }
        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }
            device.torchMode = enabled ? .on : .off
        } catch {
            log("failed to set torch: \(error)")
        }
        torchEnabled = enabled
    }

    @objc private func pushTorchButton(sender: UIButton) {
        setTorch(!torchEnabled)
        torchButton.setTitle(
            torchEnabled ? "ライトを消す" : "ライトを点ける", for: .normal)
    }

    @objc private func pushManualButton(sender: UIButton) {
        stopCamera()
        dismiss(animated: true, completion: nil)
    }

    /// ガイド枠に対応する解析範囲を、バッファの正規化座標で返します。
    ///
    /// `AVCaptureVideoPreviewLayer.metadataOutputRectConverted(fromLayerRect:)`
    /// は使わない。あれが返すのはメタデータ出力の座標系(センサー本来の横向き)
    /// であり、`videoOrientation = .portrait` で縦へ回転済みのバッファとは
    /// 90度ずれるため、解析範囲が縦帯になってMRZを外してしまう。
    ///
    /// - Parameter bufferSize: 解析対象フレームの画素数
    /// - Returns: Visionへ渡す解析範囲(左下原点の正規化座標)
    private func regionOfInterest(bufferSize: CGSize) -> CGRect {
        let unit = CGRect(x: 0, y: 0, width: 1, height: 1)
        let previewSize = self.previewSize
        guard previewSize.width > 0, previewSize.height > 0,
            bufferSize.width > 0, bufferSize.height > 0
        else {
            return unit
        }
        // resizeAspectFill は表示領域が埋まるまでバッファを拡大し、はみ出た分を
        // 中央基準で捨てる。表示されているのはバッファの中央 visible の範囲。
        let scale = max(
            previewSize.width / bufferSize.width,
            previewSize.height / bufferSize.height)
        let visibleX = min(
            CGFloat(1), previewSize.width / (bufferSize.width * scale))
        let visibleY = min(
            CGFloat(1), previewSize.height / (bufferSize.height * scale))
        // 解析範囲も表示領域の中央にあるため、バッファ上でも中央に置けばよい。
        // 中央基準であれば左下原点への反転は結果を変えない。
        let width = Self.roiWidthRatio * visibleX
        let height = Self.roiHeightRatio * visibleY
        return CGRect(
            x: 0.5 - width / 2, y: 0.5 - height / 2,
            width: width, height: height)
    }

    // MARK: - 解析

    /// 1フレームを解析する。解析範囲をVisionへ渡し、チェックデジット検証を通った
    /// 結果が2フレーム分一致したところで確定する。
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        if completed {
            return
        }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        let bufferSize = CGSize(
            width: CVPixelBufferGetWidth(pixelBuffer),
            height: CVPixelBufferGetHeight(pixelBuffer))
        textRequest.regionOfInterest = regionOfInterest(bufferSize: bufferSize)
        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do {
            try handler.perform([textRequest])
        } catch {
            // 1フレームの失敗は次のフレームで回復するため、ログのみとする
            log("recognition failed: \(error)")
            return
        }
        // VNRecognizeTextRequest.results は [VNRecognizedTextObservation]? のため
        // ダウンキャストは不要
        let lines = (textRequest.results ?? []).compactMap {
            $0.topCandidates(1).first?.string
        }
        guard let result = MrzTd3Parser.parse(lines) else {
            return
        }
        if let pending = pendingResult, pending.hasSameKeyFields(result) {
            completed = true
            log("MRZ detected")
            DispatchQueue.main.async { [weak self] in
                self?.deliver(result)
            }
        } else {
            // 検証は通ったが1フレーム目。次に同じ値が出たら確定する。
            pendingResult = result
        }
    }

    private func deliver(_ result: MrzScanResult) {
        if !result.isCompositeCheckDigitValid {
            // 任意データの誤認識で不一致になり得るため、破棄はせず記録のみ行う
            log("composite check digit mismatch")
        }
        stopCamera()
        let delegate = self.delegate
        dismiss(animated: true) { [weak self] in
            guard let self = self else {
                return
            }
            delegate?.mrzScanViewController(
                self, didScan: result.documentNumber,
                birthDate: result.birthDate,
                expirationDate: result.expirationDate)
        }
    }

    private func showErrorAndDismiss(_ message: String) {
        completed = true
        let alertController = UIAlertController(
            title: "エラー", message: message, preferredStyle: .alert)
        alertController.addAction(
            UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                // 自身を閉じるため、閉じる操作は提示元へ依頼する
                self?.presentingViewController?.dismiss(
                    animated: true, completion: nil)
            })
        present(alertController, animated: true, completion: nil)
    }

    /// 端末のログへ1行出します。
    ///
    /// `Logger` の文字列補間は既定で `<private>` に伏せられるため、
    /// 組み立てた文字列を明示的に public として渡す。
    private func log(_ message: String) {
        Self.logger.notice("\(message, privacy: .public)")
    }
}
