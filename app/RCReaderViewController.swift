//
//  RCReaderViewController.swift
//  libjeid-ios-app
//
//  Copyright © 2020 Open Source Solution Technology Corporation
//  All rights reserved.
//

import CoreNFC
import UIKit
import libjeid

class RCReaderViewController: WrapperViewController, NFCTagReaderSessionDelegate
{
    let MAX_NUMBER_LENGTH: Int = 12
    var rcReaderView: RCReaderView!
    var numberField: UITextField!
    var session: NFCTagReaderSession?
    private var number: String?

    override func loadView() {
        self.title = "在留カードリーダー"
        rcReaderView = RCReaderView()
        numberField = rcReaderView.numberField
        numberField.delegate = self
        rcReaderView.startButton.addTarget(
            self, action: #selector(pushStartButton), for: .touchUpInside)

        let wrapperView = WrapperView(rcReaderView)
        wrapperView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view = wrapperView
    }

    @objc func pushStartButton(sender: UIButton) {
        self.number = self.numberField!.text
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
            self.rcReaderView.startButton.alpha = Self.INACTIVE_ALPHA
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
        return newStr.length <= MAX_NUMBER_LENGTH
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
            self.rcReaderView.startButton.alpha = Self.ACTIVE_ALPHA
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
                let reader = try JeidReader(tag)
                self.clearPublishedLog()
                session.alertMessage = "読み取り開始..."
                let type = try reader.detectCardType()
                if type != CardType.RC {
                    self.publishLog("在留カード/特別永住者証明書ではありません")
                    session.invalidate(
                        errorMessage: "\(msgErrorHeader)在留カード/特別永住者証明書ではありません")
                    return
                }
                self.publishLog("# 在留カードの読み取り開始")
                print("thread: \(Thread.current)")
                let ap = try reader.selectRC()
                session.alertMessage = "\(msgReadingHeader)共通データ要素、カード種別..."
                // startAC(_:)実行前は認証の必要がない共通データ要素とカード種別のみが読み出されます
                let freeFiles = try ap.readFiles()
                session.alertMessage += "成功"
                let commonData = try freeFiles.getCommonData()
                self.publishLog("## 共通データ要素")
                self.publishLog(commonData.description)
                let cardType = try freeFiles.getCardType()
                self.publishLog("## カード種別")
                self.publishLog(cardType.description)

                if self.number == nil || self.number!.isEmpty {
                    self.publishLog("在留カード番号または特別永住者証明書番号を入力してください")
                    session.invalidate(
                        errorMessage: "\(msgErrorHeader)在留カード等の番号が入力されていません")
                    return
                }
                do {
                    let rcKey = try RCKey(self.number!)
                    session.alertMessage = "\(msgReadingHeader)SM開始&認証..."
                    self.publishLog("## セキュアメッセージング開始&認証")
                    try ap.startAC(rcKey)
                    self.publishLog("成功\n")
                    session.alertMessage += "成功"
                } catch let jeidError as JeidError {
                    switch jeidError {
                    case .invalidKey:
                        session.invalidate(
                            errorMessage: "\(msgErrorHeader)認証失敗")
                        self.publishLog("失敗\n")
                        self.handleInvalidKeyError(jeidError)
                        return
                    default:
                        throw jeidError
                    }
                }

                session.alertMessage = "\(msgReadingHeader)ファイルの読み出し..."
                let files = try ap.readFiles()
                session.alertMessage += "成功"

                var dataDict = [String: Any]()
                if let type = cardType.type {
                    dataDict["rc-card-type"] = type
                }
                let cardEntries = try files.getCardEntries()
                let entriesImage = try cardEntries.pngData()
                let src =
                    "data:image/png;base64,\(entriesImage.base64EncodedString())"
                dataDict["rc-front-image"] = src
                let photo = try files.getPhoto()
                if let photoImage = photo.photoData {
                    let src =
                        "data:image/jp2;base64,\(photoImage.base64EncodedString())"
                    dataDict["rc-photo"] = src
                }

                let address = try files.getAddress()
                self.publishLog("## 住居地(裏面追記)")
                self.publishLog(address.description)

                // カード種別が在留カードの場合
                if cardType.type == "1" {
                    let comprehensivePermission =
                        try files.getComprehensivePermission()
                    self.publishLog("## 裏面資格外活動包括許可欄")
                    self.publishLog(comprehensivePermission.description)
                    let individualPermission =
                        try files.getIndividualPermission()
                    self.publishLog("## 裏面資格外活動個別許可欄")
                    self.publishLog(individualPermission.description)
                    let updateStatus = try files.getUpdateStatus()
                    self.publishLog("## 裏面在留期間等更新申請欄")
                    self.publishLog(updateStatus.description)
                }
                let signature = try files.getSignature()
                self.publishLog("## 電子署名")
                self.publishLog(signature.description)

                // 真正性検証
                do {
                    let result = try files.validate()
                    dataDict["rc-valid"] = result.isValid
                    dataDict["rc-validation-result"] = result.description
                    self.publishLog("真正性検証結果: \(result)\n")
                } catch JeidError.unsupportedOperation {
                    // 無償版の場合、RCFiles#validate()でJeidError.unsupportedOperationが返ります
                    self.publishLog("無償版ライブラリは真正性検証をサポートしません\n")
                } catch {
                    self.publishLog("\(error)")
                }

                session.alertMessage = "読み取り完了"
                session.invalidate()
                self.openWebView(dataDict)
            } catch {
                session.invalidate(errorMessage: session.alertMessage + "失敗")
                self.publishLog("\(error)")
            }
        }
    }

    func openWebView(_ dict: [String: Any]) {
        DispatchQueue.main.async {
            let path = Bundle.main.path(
                forResource: "rc", ofType: "html",
                inDirectory: "WebAssets/rc")!
            let localHtmlUrl = URL(fileURLWithPath: path, isDirectory: false)
            let webViewController = WebViewController(
                localHtmlUrl, renderData: dict)
            webViewController.title = "在留カードビューア"
            self.navigationController?.pushViewController(
                webViewController, animated: true)
        }
    }

    func handleInvalidKeyError(_ jeidError: JeidError) {
        let title = "番号が間違っています"
        let message = "正しい在留カード番号または特別永住者証明書番号を入力してください"
        openAlertView(title, message)
    }
}
