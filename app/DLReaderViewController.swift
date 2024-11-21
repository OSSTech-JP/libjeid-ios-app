//
//  DLReaderViewController.swift
//  libjeid-ios-app
//
//  Copyright © 2019 Open Source Solution Technology Corporation
//  All rights reserved.
//

import CoreNFC
import UIKit
import libjeid

class DLReaderViewController: WrapperViewController, NFCTagReaderSessionDelegate
{
    let MAX_PIN_LENGTH: Int = 4
    let DPIN = "****"
    var dlReaderView: DLReaderView!
    var pin1Field: UITextField!
    var pin2Field: UITextField!
    var session: NFCTagReaderSession?
    private var pin1: String?
    private var pin2: String?

    override func loadView() {
        self.title = "運転免許証リーダー"
        dlReaderView = DLReaderView()
        pin1Field = dlReaderView.pin1Field
        pin1Field.delegate = self
        pin2Field = dlReaderView.pin2Field
        pin2Field.delegate = self
        dlReaderView.startButton.addTarget(
            self, action: #selector(pushStartButton), for: .touchUpInside)

        let wrapperView = WrapperView(dlReaderView)
        wrapperView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view = wrapperView
    }

    @objc func pushStartButton(sender: UIButton) {
        self.pin1 = self.pin1Field!.text
        self.pin2 = self.pin2Field!.text
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
            self.session?.alertMessage = "免許証に端末をかざしてください"
            self.session?.begin()
            self.dlReaderView.startButton.alpha = Self.INACTIVE_ALPHA
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
            self.dlReaderView.startButton.alpha = Self.ACTIVE_ALPHA
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
                let cardType = try reader.detectCardType()
                if cardType != CardType.DL {
                    self.publishLog("運転免許証ではありません")
                    session.invalidate(
                        errorMessage: "\(msgErrorHeader)運転免許証ではありません")
                    return
                }
                self.publishLog("# 運転免許証の読み取り開始")
                print("thread: \(Thread.current)")
                let ap = try reader.selectDL()

                // PINを入力せず共通データ要素を読み出す場合は、
                // DriverLicenseAP.readCommonData()を利用できます
                // PIN1を入力せずにDriverLicenseAP.readFiles()を実行した場合、
                // 共通データ要素と暗証番号(PIN)設定のみを読み出します。
                session.alertMessage =
                    "\(msgReadingHeader)共通データ要素と暗証番号(PIN)設定..."
                let freeFiles = try ap.readFiles()
                session.alertMessage += "成功"
                let commonData = try freeFiles.getCommonData()
                let pinSetting = try freeFiles.getPinSetting()
                self.publishLog("## 共通データ要素")
                self.publishLog(commonData.description)
                self.publishLog("## 暗証番号(PIN)設定")
                self.publishLog(pinSetting.description)
                if self.pin1 == nil || self.pin1!.isEmpty {
                    self.publishLog("暗証番号1を入力してください")
                    session.invalidate(
                        errorMessage: "\(msgErrorHeader)暗証番号1が入力されていません")
                    return
                }
                do {
                    if !pinSetting.isPinSet {
                        self.publishLog(
                            "暗証番号(PIN)設定がfalseのため、デフォルトPINの「****」を暗証番号として使用します\n"
                        )
                        self.pin1 = self.DPIN
                    }
                    session.alertMessage = "\(msgReadingHeader)暗証番号1による認証..."
                    self.publishLog("## 暗証番号1による認証")
                    try ap.verifyPin1(self.pin1!)
                    self.publishLog("成功\n")
                    session.alertMessage += "成功"
                } catch let jeidError as JeidError {
                    switch jeidError {
                    case .invalidPin:
                        session.invalidate(
                            errorMessage: "\(msgErrorHeader)認証失敗(暗証番号1)")
                        self.publishLog("失敗\n")
                        self.handleInvalidPinError(jeidError, 1)
                        return
                    default:
                        throw jeidError
                    }
                }

                if self.pin2 != nil && !self.pin2!.isEmpty {
                    do {
                        if !pinSetting.isPinSet {
                            self.pin2 = self.DPIN
                        }
                        session.alertMessage =
                            "\(msgReadingHeader)暗証番号2による認証..."
                        self.publishLog("## 暗証番号2による認証")
                        try ap.verifyPin2(self.pin2!)
                        self.publishLog("成功\n")
                        session.alertMessage += "成功"
                    } catch let jeidError as JeidError {
                        switch jeidError {
                        case .invalidPin:
                            session.invalidate(
                                errorMessage: "\(msgErrorHeader)認証失敗(暗証番号2)")
                            self.publishLog("失敗\n")
                            self.handleInvalidPinError(jeidError, 2)
                            return
                        default:
                            throw jeidError
                        }
                    }
                }

                session.alertMessage = "\(msgReadingHeader)ファイルの読み出し..."
                // PINを入力した後、DriverLicenseAP.readFiles()を実行すると、
                // 入力されたPINで読み出し可能なファイルをすべて読み出します。
                // PIN1のみを入力した場合、PIN2の入力が必要なファイル(本籍など)は読み出しません。
                let files = try ap.readFiles()
                session.alertMessage += "成功"
                let entries = try files.getEntries()
                self.publishLog("## 記載事項(本籍除く)")
                self.publishLog(entries.description)

                var dataDict = [String: Any]()
                dataDict["dl-name"] = try self.dlStringToDictArray(entries.name)
                if let kana = entries.kana {
                    dataDict["dl-kana"] = kana
                }
                if let birthDate = entries.birthDate {
                    dataDict["dl-birth"] = birthDate.stringValue
                }
                dataDict["dl-addr"] = try self.dlStringToDictArray(
                    entries.address)
                if let issueDate = entries.issueDate {
                    dataDict["dl-issue"] = issueDate.stringValue
                }
                if let refNumber = entries.refNumber {
                    dataDict["dl-ref"] = refNumber
                }
                if let colorClass = entries.colorClass {
                    dataDict["dl-color-class"] = colorClass
                }
                if let expireDate = entries.expireDate {
                    dataDict["dl-expire"] = expireDate.stringValue
                    let now = Date()
                    let date = expireDate.dateValue.addingTimeInterval(
                        60 * 60 * 24)
                    dataDict["dl-is-expired"] = Bool(now >= date)
                }
                if let licenseNumber = entries.licenseNumber {
                    dataDict["dl-number"] = licenseNumber
                }
                if let pscName = entries.pscName {
                    dataDict["dl-sc"] = pscName.replacingCharacters(
                        in: pscName.range(of: "公安委員会")!, with: "")
                }

                var i: Int = 1
                if let conditions = entries.conditions {
                    for condition in conditions {
                        dataDict[String(format: "dl-condition%d", i)] =
                            condition
                        i += 1
                    }
                }

                if let categories = entries.categories {
                    var categoriesDict: [[String: Any]] = []
                    for category in categories {
                        var obj = [String: Any]()
                        obj["tag"] = category.tag
                        obj["name"] = category.name
                        obj["date"] = category.date.stringValue
                        obj["licensed"] = category.isLicensed
                        categoriesDict.append(obj)
                    }
                    dataDict["dl-categories"] = categoriesDict
                }

                let changedEntries = try files.getChangedEntries()
                self.publishLog("## 記載事項変更等(本籍除く)")
                self.publishLog(changedEntries.description)

                let formatter = DateFormatter()
                formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
                formatter.dateFormat = "yyyyMMdd"
                var changes: [[String: Any]] = []
                if changedEntries.isChanged {
                    for newName in changedEntries.newNameList {
                        var dict = [String: Any]()
                        dict["label"] = "新氏名"
                        dict["date"] = newName.date.stringValue
                        dict["ad"] = formatter.string(
                            from: newName.date.dateValue)
                        dict["value"] = try self.dlStringToDictArray(
                            newName.value)
                        dict["psc"] = newName.psc
                        changes.append(dict)
                    }
                    for newAddress in changedEntries.newAddressList {
                        var dict = [String: Any]()
                        dict["label"] = "新住所"
                        dict["date"] = newAddress.date.stringValue
                        dict["ad"] = formatter.string(
                            from: newAddress.date.dateValue)
                        dict["value"] = try self.dlStringToDictArray(
                            newAddress.value)
                        dict["psc"] = newAddress.psc
                        changes.append(dict)
                    }
                    for newCond in changedEntries.newConditionList {
                        var dict = [String: Any]()
                        dict["label"] = "新条件"
                        dict["date"] = newCond.date.stringValue
                        dict["ad"] = formatter.string(
                            from: newCond.date.dateValue)
                        dict["value"] = try self.dlStringToDictArray(
                            newCond.value)
                        dict["psc"] = newCond.psc
                        changes.append(dict)
                    }
                    for condCancel in changedEntries.conditionCancellationList {
                        var dict = [String: Any]()
                        dict["label"] = "条件解除"
                        dict["date"] = condCancel.date.stringValue
                        dict["ad"] = formatter.string(
                            from: condCancel.date.dateValue)
                        dict["value"] = try self.dlStringToDictArray(
                            condCancel.value)
                        dict["psc"] = condCancel.psc
                        changes.append(dict)
                    }
                }

                do {
                    let registeredDomicile = try files.getRegisteredDomicile()
                    dataDict["dl-registered-domicile"] =
                        try self.dlStringToDictArray(
                            registeredDomicile.registeredDomicile)

                    let photo = try files.getPhoto()
                    // 顔写真をCGImageオブジェクトで取得
                    if let photoImage = photo.photoImage {
                        // CGImageオブジェクトからJpeg形式に変換
                        if let jpegData = try self.encodeJpeg(photoImage) {
                            let src =
                                "data:image/jpeg;base64,\(jpegData.base64EncodedString())"
                            dataDict["dl-photo"] = src
                        }
                    }

                    let changedRegDomicile =
                        try files.getChangedRegisteredDomicile()
                    var newRegDomiciles: [[String: Any]] = []
                    if changedRegDomicile.isChanged {
                        for newRegDomicile in changedRegDomicile
                            .newRegisteredDomicileList
                        {
                            var dict = [String: Any]()
                            dict["label"] = "新本籍"
                            dict["date"] = newRegDomicile.date.stringValue
                            dict["ad"] = formatter.string(
                                from: newRegDomicile.date.dateValue)
                            dict["value"] = try self.dlStringToDictArray(
                                newRegDomicile.value)
                            dict["psc"] = newRegDomicile.psc
                            newRegDomiciles.append(dict)
                        }
                    }
                    changes += newRegDomiciles

                    let signature = try files.getSignature()
                    self.publishLog("## 電子署名")
                    if let signatureSubject = signature.subject {
                        self.publishLog("Subject: \(signatureSubject)")
                        dataDict["dl-signature-subject"] = signatureSubject
                    }
                    if let signatureSKI = signature.subjectKeyIdentifier {
                        let signatureSkiStr = signatureSKI.map {
                            String(format: "%.2hhx", $0)
                        }.joined(separator: ":")
                        self.publishLog(
                            "Subject Key Identifier: \(signatureSkiStr)")
                        dataDict["dl-signature-ski"] = signatureSkiStr
                    }

                    // 真正性検証
                    do {
                        let result = try files.validate()
                        dataDict["dl-verified"] = result.isValid
                        self.publishLog("真正性検証結果: \(result)\n")
                    } catch JeidError.unsupportedOperation {
                        // 無償版の場合、DLFiles#validate()でJeidError.unsupportedOperationが返ります
                        self.publishLog("無償版ライブラリは真正性検証をサポートしません\n")
                    } catch {
                        self.publishLog("\(error)")
                    }
                } catch (JeidError.fileNotFound(message: _)) {
                    // PIN2を入力していない場合、filesオブジェクトは
                    // JeidError.fileNotFound(message: String)をスローします
                }

                dataDict["dl-changes"] = changes
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
                    forResource: "dl", ofType: "html",
                    inDirectory: "WebAssets/dl")!
                let localHtmlUrl = URL(
                    fileURLWithPath: path, isDirectory: false)
                let webViewController = WebViewController(
                    localHtmlUrl, "render(\'\(jsonStr!)\');")
                webViewController.title = "運転免許証ビューア"
                self.navigationController?.pushViewController(
                    webViewController, animated: true)
            } catch (let error) {
                self.publishLog("\(error)")
                self.openAlertView("エラー", "読み取り結果の表示に失敗しました")
            }
        }
    }

    func handleInvalidPinError(_ jeidError: JeidError, _ pinIndex: Int) {
        let title: String
        let message: String
        guard case .invalidPin(let counter) = jeidError else {
            print("unexpected error: \(jeidError)")
            return
        }
        if jeidError.isBlocked! {
            title = "暗証番号\(pinIndex)がブロックされています"
            message = "警察署でブロック解除の申請を行ってください。"
        } else {
            title = "暗証番号\(pinIndex)が間違っています"
            message =
                "暗証番号\(pinIndex)を正しく入力してください。\n"
                + "残り\(counter)回間違えるとブロックされます。"
        }
        openAlertView(title, message)
    }

    func dlStringToDictArray(_ dlString: DLString) throws -> [[String: Any]] {
        guard let jsonData = try dlString.toJSON().data(using: .utf8),
            let jsonObj = try? JSONSerialization.jsonObject(
                with: jsonData, options: []),
            let dictArray = jsonObj as? [[String: Any]]
        else {
            throw JeidError.decodeFailed(
                message:
                    "failed to decode JSON String: \(try dlString.toJSON())")
        }
        return dictArray
    }
}
