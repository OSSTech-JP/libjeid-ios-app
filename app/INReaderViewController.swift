//
//  INReaderViewController.swift
//  libjeid-ios-app
//
//  Copyright © 2019 Open Source Solution Technology Corporation
//  All rights reserved.
//

import CoreNFC
import UIKit
import libjeid

class INReaderViewController: WrapperViewController, NFCTagReaderSessionDelegate
{
    let MAX_PIN_LENGTH: Int = 4
    var inReaderView: INReaderView!
    var pinField: UITextField!
    var session: NFCTagReaderSession?
    private var pin: String?

    override func loadView() {
        self.title = "マイナンバーカードリーダー"
        inReaderView = INReaderView()
        pinField = inReaderView.pinField
        pinField.delegate = self
        inReaderView.startButton.addTarget(
            self, action: #selector(pushStartButton), for: .touchUpInside)

        let wrapperView = WrapperView(inReaderView)
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
            self.inReaderView.startButton.alpha = Self.INACTIVE_ALPHA
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
            self.inReaderView.startButton.alpha = Self.ACTIVE_ALPHA
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
                if self.pin == nil || self.pin!.isEmpty || self.pin!.count != 4
                {
                    self.publishLog("4桁の暗証番号を入力してください")
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
                self.publishLog("# マイナンバーカードの読み取り開始")
                print("thread: \(Thread.current)")
                self.publishLog("## 券面入力補助APから情報を取得します")
                let textAp = try reader.selectINText()
                do {
                    session.alertMessage = "\(msgReadingHeader)暗証番号による認証..."
                    self.publishLog("### 暗証番号による認証")
                    try textAp.verifyPin(self.pin!)
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

                session.alertMessage = "\(msgReadingHeader)券面入力補助AP内の情報..."
                let textFiles = try textAp.readFiles()
                session.alertMessage += "成功"

                var dataDict = [String: Any]()
                self.publishLog("### 個人番号")
                do {
                    let textMyNumber = try textFiles.getMyNumber()
                    self.publishLog(textMyNumber.description)
                    if let myNumber = textMyNumber.myNumber {
                        dataDict["cardinfo-mynumber"] = myNumber
                    }
                } catch JeidError.unsupportedOperation {
                    // 無償版の場合、INTextFiles#getMyNumber()でJeidError.unsupportedOperationが返ります
                    self.publishLog("無償版ライブラリは個人番号の取得をサポートしません\n")
                }

                let textAttrs = try textFiles.getAttributes()
                self.publishLog("### 4情報")
                self.publishLog(textAttrs.description)
                if let name = textAttrs.name {
                    dataDict["cardinfo-name"] = name
                }
                if let birthDate = textAttrs.birthDate {
                    dataDict["cardinfo-birth"] = birthDate
                }
                if let sexString = textAttrs.sexString {
                    dataDict["cardinfo-sex"] = sexString
                }
                if let address = textAttrs.address {
                    dataDict["cardinfo-addr"] = address
                }

                self.publishLog("### 券面入力補助APの真正性検証")
                do {
                    let textApValidationResult = try textFiles.validate()
                    self.publishLog(textApValidationResult.description + "\n")
                    dataDict["textap-validation-result"] =
                        textApValidationResult.isValid
                } catch JeidError.unsupportedOperation {
                    // 無償版の場合、INTextFiles#validate()でJeidError.unsupportedOperationが返ります
                    self.publishLog("無償版ライブラリは真正性検証をサポートしません\n")
                }

                self.publishLog("## 券面APから情報を取得します")
                let visualAp = try reader.selectINVisual()
                session.alertMessage = "\(msgReadingHeader)暗証番号による認証..."
                self.publishLog("### 暗証番号による認証")
                try visualAp.verifyPin(self.pin!)
                self.publishLog("成功\n")
                session.alertMessage += "成功"
                session.alertMessage = "\(msgReadingHeader)券面AP内の情報..."
                let visualFiles = try visualAp.readFiles()
                session.alertMessage += "成功"
                let visualEntries = try visualFiles.getEntries()
                self.publishLog("### 券面事項")
                self.publishLog(visualEntries.description)
                if let expireDate = visualEntries.expireDate {
                    dataDict["cardinfo-expire"] = expireDate
                }
                if let birthDate = visualEntries.birthDate {
                    dataDict["cardinfo-birth2"] = birthDate
                }
                if let sexString = visualEntries.sexString {
                    dataDict["cardinfo-sex2"] = sexString
                }
                if let nameImage = visualEntries.name {
                    let src =
                        "data:image/png;base64,\(nameImage.base64EncodedString())"
                    dataDict["cardinfo-name-image"] = src
                }
                if let addressImage = visualEntries.address {
                    let src =
                        "data:image/png;base64,\(addressImage.base64EncodedString())"
                    dataDict["cardinfo-address-image"] = src
                }

                if let photoImage = visualEntries.photoImage {
                    // CGImageオブジェクトからJpeg形式に変換
                    if let jpegData = try self.encodeJpeg(photoImage) {
                        let src =
                            "data:image/jpeg;base64,\(jpegData.base64EncodedString())"
                        dataDict["cardinfo-photo"] = src
                    }
                }

                do {
                    let visualMyNumber = try visualFiles.getMyNumber()
                    if let myNumberImage = visualMyNumber.myNumber {
                        let src =
                            "data:image/png;base64,\(myNumberImage.base64EncodedString())"
                        dataDict["cardinfo-mynumber-image"] = src
                    }
                } catch JeidError.unsupportedOperation {
                    // 無償版の場合、INVisualFiles#getMyNumber()でJeidError.unsupportedOperationが返ります
                }

                self.publishLog("### 券面APの真正性検証")
                do {
                    let visualApValidationResult = try visualFiles.validate()
                    self.publishLog(visualApValidationResult.description + "\n")
                    dataDict["visualap-validation-result"] =
                        visualApValidationResult.isValid
                } catch JeidError.unsupportedOperation {
                    // 無償版の場合、INVisualFiles#validate()でJeidError.unsupportedOperationが返ります
                    self.publishLog("無償版ライブラリは真正性検証をサポートしません\n")
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
            do {
                let jsonData: Data = try JSONSerialization.data(
                    withJSONObject: dict, options: [])
                var jsonStr: String? = String(bytes: jsonData, encoding: .utf8)
                jsonStr = jsonStr?.replacingOccurrences(
                    of: "\\\"", with: "\\\\\"")

                let path = Bundle.main.path(
                    forResource: "in", ofType: "html",
                    inDirectory: "WebAssets/in")!
                let localHtmlUrl = URL(
                    fileURLWithPath: path, isDirectory: false)
                let webViewController = WebViewController(
                    localHtmlUrl, "render(\'\(jsonStr!)\');")
                webViewController.title = "マイナンバーカードビューア"
                self.navigationController?.pushViewController(
                    webViewController, animated: true)
            } catch (let error) {
                self.publishLog("\(error)")
                self.openAlertView("エラー", "読み取り結果の表示に失敗しました")
            }
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
            message = "市区町村窓口でブロック解除の申請を行ってください。"
        } else {
            title = "暗証番号が間違っています"
            message =
                "暗証番号を正しく入力してください。\n"
                + "残り\(counter)回間違えるとブロックされます。"
        }
        openAlertView(title, message)
    }
}
