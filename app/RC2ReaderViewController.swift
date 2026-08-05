//
//  RC2ReaderViewController.swift
//  libjeid-ios-app
//
//  Copyright © 2026 Open Source Solution Technology Corporation
//  All rights reserved.
//

import CoreNFC
import UIKit
import libjeid

/// 第2世代在留カード(第2世代在留カード・第2世代特別永住者証明書)の読み取り画面。
/// <br>
/// ビューアは `WebAssets/rc2` を特定在留カード(`RCSReaderViewController`)と共用します
/// (データ構造が共通のため、JSONのキーも `rc2-*` で同じ)。
class RC2ReaderViewController: WrapperViewController, NFCTagReaderSessionDelegate
{
    let MAX_NUMBER_LENGTH: Int = 12
    var readerView: RC2ReaderView!
    var numberField: UITextField!
    var session: NFCTagReaderSession?
    private var number: String?

    override func loadView() {
        self.title = "第2世代在留カードリーダー"
        readerView = RC2ReaderView(
            "読み取り開始ボタンを押下後、端末をカードにかざしてください。\n"
                + "第2世代在留カードおよび第2世代特別永住者証明書に対応しています。")
        numberField = readerView.numberField
        numberField.delegate = self
        readerView.startButton.addTarget(
            self, action: #selector(pushStartButton), for: .touchUpInside)

        let wrapperView = WrapperView(readerView)
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
            self.readerView.startButton.alpha = Self.INACTIVE_ALPHA
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
            self.readerView.startButton.alpha = Self.ACTIVE_ALPHA
        }
    }

    func tagReaderSession(
        _ session: NFCTagReaderSession,
        didDetect tags: [NFCTag]
    ) {
        let msgReadingHeader = "読み取り中\n"
        let msgErrorHeader = "エラー\n"
        let tag = tags.first!
        session.connect(to: tag) { (error: Error?) in
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
                if type != CardType.RC2 {
                    self.publishLog("第2世代在留カード/特別永住者証明書ではありません")
                    session.invalidate(
                        errorMessage: "\(msgErrorHeader)第2世代在留カード/特別永住者証明書ではありません")
                    return
                }
                self.publishLog("# 第2世代在留カードの読み取り開始")
                let ap = try reader.selectRC2()
                session.alertMessage = "\(msgReadingHeader)共通データ要素、カード種別..."
                let commonData = try ap.readCommonData()
                self.publishLog("## 共通データ要素")
                self.publishLog(commonData.description)
                let cardType = try ap.readCardType()
                self.publishLog("## カード種別")
                self.publishLog(cardType.description)
                session.alertMessage += "成功"

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

                let dataDict = try RC2ViewerData.build(files, cardType) {
                    self.publishLog($0)
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
                forResource: "rc2", ofType: "html",
                inDirectory: "WebAssets/rc2")!
            let localHtmlUrl = URL(fileURLWithPath: path, isDirectory: false)
            let webViewController = WebViewController(
                localHtmlUrl, renderData: dict)
            webViewController.title = "第2世代在留カードビューア"
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
