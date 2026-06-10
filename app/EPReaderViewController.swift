//
//  EPReaderViewController.swift
//  libjeid-ios-app
//
//  Copyright © 2020 Open Source Solution Technology Corporation
//  All rights reserved.
//

import CoreNFC
import UIKit
import libjeid

class EPReaderViewController: WrapperViewController, NFCTagReaderSessionDelegate
{
    let MAX_NUMBER_LENGTH: Int = 9
    let MAX_DATE_LENGTH: Int = 8
    var epReaderView: EPReaderView!
    var numberField: UITextField!
    var birthDateField: UITextField!
    var expireDateField: UITextField!
    var session: NFCTagReaderSession?
    private var number: String?
    private var birthDate: String?
    private var expireDate: String?
    // 実行したアクセスコントロール方式("PACE" または "BAC")
    private var acMethod: String = "BAC"

    override func loadView() {
        self.title = "パスポートリーダー"
        epReaderView = EPReaderView()
        numberField = epReaderView.numberField
        numberField.delegate = self
        birthDateField = epReaderView.birthDateField
        birthDateField.delegate = self
        expireDateField = epReaderView.expireDateField
        expireDateField.delegate = self
        epReaderView.startButton.addTarget(
            self, action: #selector(pushStartButton), for: .touchUpInside)

        let wrapperView = WrapperView(epReaderView)
        wrapperView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view = wrapperView
    }

    @objc func pushStartButton(sender: UIButton) {
        self.number = self.numberField!.text
        self.birthDate = self.birthDateField!.text
        self.expireDate = self.expireDateField!.text
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
            self.session?.alertMessage = "パスポートに端末をかざしてください"
            self.session?.begin()
            self.epReaderView.startButton.alpha = Self.INACTIVE_ALPHA
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
        if textField == self.numberField {
            return newStr.length <= MAX_NUMBER_LENGTH
        } else {
            return newStr.length <= MAX_DATE_LENGTH
        }
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
            self.epReaderView.startButton.alpha = Self.ACTIVE_ALPHA
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
                if type != CardType.EP {
                    self.publishLog("パスポートではありません")
                    session.invalidate(
                        errorMessage: "\(msgErrorHeader)パスポートではありません")
                    return
                }
                self.publishLog("# パスポートの読み取り開始")
                print("thread: \(Thread.current)")
                let ap = try reader.selectEP()
                if self.number == nil || self.number!.isEmpty {
                    self.publishLog("パスポート番号を入力してください")
                    session.invalidate(
                        errorMessage: "\(msgErrorHeader)パスポート番号が入力されていません")
                    return
                }
                if self.number!.count != self.MAX_NUMBER_LENGTH {
                    self.publishLog("パスポート番号が9文字ではありません")
                    session.invalidate(
                        errorMessage: "\(msgErrorHeader)パスポート番号が9文字ではありません")
                    return
                }
                if self.birthDate == nil || self.birthDate!.isEmpty {
                    self.publishLog("生年月日を入力してください")
                    session.invalidate(
                        errorMessage: "\(msgErrorHeader)生年月日が入力されていません")
                    return
                }
                let birthDate = self.birthDate!
                if birthDate.count != self.MAX_DATE_LENGTH {
                    self.publishLog("生年月日が8桁ではありません")
                    session.invalidate(
                        errorMessage: "\(msgErrorHeader)生年月日が8桁ではありません")
                    return
                }
                if self.expireDate == nil || self.expireDate!.isEmpty {
                    self.publishLog("有効期限を入力してください")
                    session.invalidate(
                        errorMessage: "\(msgErrorHeader)有効期限が入力されていません")
                    return
                }
                let expireDate = self.expireDate!
                if expireDate.count != self.MAX_DATE_LENGTH {
                    self.publishLog("有効期限が8桁ではありません")
                    session.invalidate(
                        errorMessage: "\(msgErrorHeader)有効期限が8桁ではありません")
                    return
                }
                do {
                    let epKey = try EPKey(
                        self.number!,
                        String(
                            birthDate[
                                birthDate.index(
                                    birthDate.startIndex, offsetBy: 2)..<birthDate
                                    .endIndex]),
                        String(
                            expireDate[
                                expireDate.index(
                                    expireDate.startIndex, offsetBy: 2)..<expireDate
                                    .endIndex]))
                    // PACE 対応カードではまず PACE を試行し、失敗時は BAC にフォールバックする
                    session.alertMessage = "\(msgReadingHeader)Access Control開始..."
                    self.publishLog("## Access Control開始")
                    self.acMethod = try ap.startAC(epKey)
                    self.publishLog("成功(\(self.acMethod))\n")
                    session.alertMessage += "成功"
                } catch let jeidError as JeidError {
                    switch jeidError {
                    case .invalidKey:
                        session.invalidate(
                            errorMessage: "\(msgErrorHeader)アクセスコントロール失敗")
                        self.publishLog("パスポート番号、生年月日または有効期限が間違っています\n")
                        self.handleInvalidKeyError(jeidError)
                        return
                    default:
                        throw jeidError
                    }
                }

                session.alertMessage = "\(msgReadingHeader)ファイルの読み出し..."
                let files = try ap.readFiles()
                session.alertMessage += "成功"
                self.publishLog("## 読み取りに成功したファイル")
                self.publishLog("\(files)\n")

                var dataDict = [String: Any]()
                let commonData = try files.getCommonData()
                self.publishLog("## Common Data")
                self.publishLog(commonData.description)

                let dg1 = try files.getDataGroup1()
                var issuingCountry: String? = nil
                self.publishLog("## Data Group1")
                if let mrz = dg1.mrz {
                    self.publishLog("\(mrz)\n")
                    let dg1Mrz = try EPMRZ(mrz)
                    issuingCountry = dg1Mrz.issuingCountry
                    dataDict["ep-type"] = dg1Mrz.documentCode
                    dataDict["ep-issuing-country"] = dg1Mrz.issuingCountry
                    dataDict["ep-passport-number"] = dg1Mrz.passportNumber
                    dataDict["ep-surname"] = dg1Mrz.surname
                    dataDict["ep-given-name"] = dg1Mrz.givenName
                    dataDict["ep-nationality"] = dg1Mrz.nationality
                    dataDict["ep-date-of-birth"] = dg1Mrz.birthDate
                    dataDict["ep-sex"] = dg1Mrz.sex
                    dataDict["ep-date-of-expiry"] = dg1Mrz.expirationDate
                    dataDict["ep-mrz"] = dg1Mrz.mrz
                }

                let dg2 = try files.getDataGroup2()
                if let jpeg = dg2.faceJpeg {
                    let src =
                        "data:image/jpeg;base64,\(jpeg.base64EncodedString())"
                    dataDict["ep-photo"] = src
                }

                // 実行したアクセスコントロール方式("PACE" または "BAC")
                dataDict["ep-ac-result"] = true
                dataDict["ep-ac-method"] = self.acMethod

                self.publishLog("## Passive Authentication")
                do {
                    let paResult = try files.validate()
                    dataDict["ep-pa-result"] = paResult.isValid
                    self.publishLog(
                        "検証結果: \(paResult.isValid) (status: \(paResult.status.stringValue))\n")
                } catch JeidError.unsupportedOperation {
                    // 無償版の場合、EPFiles#validate()でJeidError.unsupportedOperationが返ります
                    self.publishLog(
                        "無償版ライブラリはPassive Authenticationをサポートしません\n")
                }

                session.alertMessage =
                    "\(msgReadingHeader)Active Authentication..."
                self.publishLog("## Active Authentication")
                do {
                    let aaResult = try ap.activeAuthentication(files)
                    dataDict["ep-aa-result"] = aaResult
                    self.publishLog("検証結果: \(aaResult)\n")
                } catch let jeidError as JeidError {
                    switch jeidError {
                    case .unsupportedOperation:
                        // 無償版の場合、PassportAP#activeAuthentication(_:)でJeidError.unsupportedOperationが返ります
                        self.publishLog(
                            "無償版ライブラリはActive Authenticationをサポートしません\n")
                    case .fileNotFound:
                        self.publishLog("Active Authenticationに非対応なパスポートです\n")
                    case .transceiveFailed:
                        throw jeidError
                    default:
                        self.publishLog(
                            "Active Authenticationで不明なエラーが発生しました: \(jeidError)\n"
                        )
                    }
                }

                if "JPN" != issuingCountry {
                    session.invalidate(
                        errorMessage: "\(msgErrorHeader)日本発行のパスポートではありません")
                    self.publishLog("日本発行のパスポートではありません")
                    return
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
                forResource: "ep", ofType: "html",
                inDirectory: "WebAssets/ep")!
            let localHtmlUrl = URL(
                fileURLWithPath: path, isDirectory: false)
            let webViewController = WebViewController(
                localHtmlUrl, renderData: dict)
            webViewController.title = "パスポートビューアー"
            self.navigationController?.pushViewController(
                webViewController, animated: true)
        }
    }

    func handleInvalidKeyError(_ jeidError: JeidError) {
        let title = "入力情報が間違っています"
        let message = "正しいパスポート番号、生年月日および有効期限を入力してください"
        openAlertView(title, message)
    }
}
