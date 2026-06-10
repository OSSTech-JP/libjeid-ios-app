//
//  INDLReaderViewController.swift
//  libjeid-ios-app
//
//  Copyright © 2019 Open Source Solution Technology Corporation
//  All rights reserved.
//

import CoreNFC
import ImageIO
import UIKit
import libjeid

class INDLReaderViewController: WrapperViewController,
    NFCTagReaderSessionDelegate
{
    let MAX_PIN_LENGTH: Int = 4
    let DPIN = "****"
    var indlReaderView: INDLReaderView!
    var pinField: UITextField!
    var session: NFCTagReaderSession?
    private var pin: String?

    override func loadView() {
        self.title = "マイナ免許証リーダー"
        indlReaderView = INDLReaderView()
        pinField = indlReaderView.pinField
        pinField.delegate = self
        indlReaderView.startButton.addTarget(
            self, action: #selector(pushStartButton), for: .touchUpInside)

        let wrapperView = WrapperView(indlReaderView)
        wrapperView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view = wrapperView
    }

    @objc func pushStartButton(sender: UIButton) {
        self.pin = self.pinField!.text
        if let activeField = self.activeField {
            activeField.resignFirstResponder()
        }
        if !NFCReaderSession.readingAvailable {
            self.openAlertView("エラー", "お使いの端末はNFCに対応していません。")
            return
        }
        self.clearPublishedLog()
        if self.session != nil {
            publishLog("しばらく待ってから再度お試しください")
        } else {
            self.session = NFCTagReaderSession(
                pollingOption: [.iso14443], delegate: self,
                queue: DispatchQueue.global())
            self.session?.alertMessage = "カードに端末をかざしてください"
            self.session?.begin()
            self.indlReaderView.startButton.alpha = Self.INACTIVE_ALPHA
        }
    }

    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        let currentStr: NSString = textField.text! as NSString
        let newStr: NSString =
            currentStr.replacingCharacters(in: range, with: string) as NSString
        return newStr.length <= MAX_PIN_LENGTH
    }

    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        print("tagReaderSessionDidBecomeActive: \(Thread.current)")
    }

    func tagReaderSession(
        _ session: NFCTagReaderSession,
        didInvalidateWithError error: Error
    ) {
        if let nfcError = error as? NFCReaderError {
            if nfcError.code != .readerSessionInvalidationErrorUserCanceled {
                print(
                    "tagReaderSession error: " + nfcError.localizedDescription)
                self.publishLog("エラー: " + nfcError.localizedDescription)
                if nfcError.code
                    == .readerSessionInvalidationErrorSessionTerminatedUnexpectedly
                {
                    self.publishLog("しばらく待ってから再度お試しください")
                }
            }
        } else {
            print("tagReaderSession error: " + error.localizedDescription)
        }
        self.session = nil
        DispatchQueue.main.async {
            self.indlReaderView.startButton.alpha = Self.ACTIVE_ALPHA
        }
    }

    func tagReaderSession(
        _ session: NFCTagReaderSession,
        didDetect tags: [NFCTag]
    ) {
        let msgReadingHeader = "読み取り中\n"
        let msgErrorHeader = "エラー\n"
        print("reader session thread: \(Thread.current)")
        let tag = tags.first!
        session.connect(to: tag) { (error: Error?) in
            print("connect thread: \(Thread.current)")
            if error != nil {
                print(error!)
                session.invalidate(errorMessage: "connect error")
                return
            }
            do {
                if self.pin == nil || self.pin!.isEmpty {
                    self.publishLog("暗証番号を入力してください")
                    session.invalidate(
                        errorMessage: "\(msgErrorHeader)暗証番号が入力されていません")
                    return
                }
                let reader = try JeidReader(tag)
                self.clearPublishedLog()
                session.alertMessage = "読み取り開始..."
                let cardType = try reader.detectCardType()
                if cardType != CardType.IN {
                    self.publishLog("マイナンバーカードではありません")
                    session.invalidate(
                        errorMessage: "\(msgErrorHeader)マイナンバーカードではありません")
                    return
                }
                self.publishLog("# マイナ運転免許証の読み取り開始")
                print("thread: \(Thread.current)")
                let ap = try reader.selectINDL()

                let pinSetting = try ap.readPinSetting()
                self.publishLog("## 暗証番号(PIN)設定")
                self.publishLog(pinSetting.description)
                if !pinSetting.isPinSet {
                    self.publishLog(
                        "暗証番号設定がfalseのため、デフォルトPINの「****」を暗証番号として使用します\n"
                    )
                    self.pin = self.DPIN
                }

                do {
                    session.alertMessage = "\(msgReadingHeader)暗証番号による認証..."
                    self.publishLog("## 暗証番号による認証")
                    try ap.verifyPin(self.pin!)
                    self.publishLog("成功\n")
                    session.alertMessage += "成功"
                } catch let jeidError as JeidError {
                    switch jeidError {
                    case .invalidPin:
                        session.invalidate(
                            errorMessage: "\(msgErrorHeader)認証失敗")
                        self.publishLog("失敗\n")
                        self.handleInvalidPinError(jeidError)
                        return
                    default:
                        throw jeidError
                    }
                }

                session.alertMessage = "\(msgReadingHeader)ファイルの読み出し..."
                let files = try ap.readFiles()
                session.alertMessage += "成功"

                let entries = try files.getEntries()
                self.publishLog("## 免許情報記録")
                self.publishLog(entries.description)

                var dataDict = [String: Any]()
                if let colorClass = entries.colorClass {
                    dataDict["color-class"] = colorClass
                }
                if let expireDate = entries.expireDate {
                    dataDict["expire-date"] = expireDate.stringValue
                }
                if let licenseNumber = entries.licenseNumber {
                    dataDict["license-number"] = licenseNumber
                }
                dataDict["conditions"] = entries.conditions

                var categoriesDict: [[String: Any]] = []
                for category in entries.categories where category.isLicensed {
                    var obj = [String: Any]()
                    obj["tag"] = category.tag
                    obj["name"] = category.name
                    obj["licensed"] = category.isLicensed
                    // 「二・小・原」「他」「二種」のみ取得年月日が記録されており、
                    // それ以外の免許種別に年月日は記録されていません。
                    if let date = category.date {
                        obj["date"] = date.stringValue
                    }
                    categoriesDict.append(obj)
                }
                dataDict["categories"] = categoriesDict

                // 顔写真(JPEG2000)をデコードしてJPEGに変換
                if let photo = entries.photo,
                    let imageSource = CGImageSourceCreateWithData(
                        photo.encoded as CFData, nil),
                    let cgImage = CGImageSourceCreateImageAtIndex(
                        imageSource, 0, nil),
                    let jpegData = try cgImage.encodeJpeg()
                {
                    dataDict["photo"] = jpegData.base64EncodedString()
                }

                // 電子署名
                let signature = try files.getSignature()
                self.publishLog("## 電子署名")
                self.publishLog(signature.description)
                if let issuer = signature.issuer {
                    dataDict["signature-issuer"] = issuer
                }
                if let subject = signature.subject {
                    dataDict["signature-subject"] = subject
                }
                if let ski = signature.subjectKeyIdentifier {
                    let skiStr = ski.map {
                        String(format: "%.2hhx", $0)
                    }.joined(separator: ":")
                    dataDict["signature-ski"] = skiStr
                }

                // 真正性検証
                do {
                    let result = try files.validate()
                    dataDict["signature-valid"] = result.isValid
                    self.publishLog("真正性検証結果: \(result)\n")
                } catch JeidError.unsupportedOperation {
                    // 無償版の場合、INDLFiles#validate()でJeidError.unsupportedOperationが返ります
                    self.publishLog("無償版ライブラリは真正性検証をサポートしません\n")
                } catch {
                    self.publishLog("\(error)")
                }

                session.alertMessage = "読み取り完了"
                session.invalidate()
                self.openWebView(dataDict)
            } catch JeidError.fileNotFound {
                session.invalidate(
                    errorMessage: "\(msgErrorHeader)マイナ運転免許証ではありません")
                self.publishLog("マイナ運転免許証ではありません")
            } catch {
                session.invalidate(errorMessage: session.alertMessage + "失敗")
                self.publishLog("\(error)")
            }
        }
    }

    func openWebView(_ dict: [String: Any]) {
        DispatchQueue.main.async {
            let path = Bundle.main.path(
                forResource: "indl", ofType: "html",
                inDirectory: "WebAssets/indl")!
            let localHtmlUrl = URL(
                fileURLWithPath: path, isDirectory: false)
            let webViewController = WebViewController(
                localHtmlUrl, renderData: dict)
            webViewController.title = "マイナ免許証ビューア"
            self.navigationController?.pushViewController(
                webViewController, animated: true)
        }
    }

    func handleInvalidPinError(_ jeidError: JeidError) {
        let title: String
        let message: String
        guard case .invalidPin(let counter) = jeidError else {
            print("unexpected error: \(jeidError)")
            return
        }
        if jeidError.isBlocked! {
            title = "暗証番号がブロックされています"
            message = "警察署でブロック解除の申請を行ってください。"
        } else {
            title = "暗証番号が間違っています"
            message =
                "暗証番号を正しく入力してください。\n"
                + "残り\(counter)回間違えるとブロックされます。"
        }
        openAlertView(title, message)
    }
}
