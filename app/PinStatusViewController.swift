//
//  PinStatusViewController.swift
//  libjeid-ios-app
//
//  Copyright © 2019 Open Source Solution Technology Corporation
//  All rights reserved.
//

import CoreNFC
import UIKit
import libjeid

class PinStatusViewController: WrapperViewController,
    NFCTagReaderSessionDelegate
{
    var pinStatusView: PinStatusView!
    var session: NFCTagReaderSession?

    override func loadView() {
        self.title = "暗証番号ステータス"
        pinStatusView = PinStatusView()
        pinStatusView.startButton.addTarget(
            self, action: #selector(pushStartButton), for: .touchUpInside)

        let wrapperView = WrapperView(pinStatusView)
        wrapperView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view = wrapperView
    }

    @objc func pushStartButton(sender: UIButton) {
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
            self.pinStatusView.startButton.alpha = Self.INACTIVE_ALPHA
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
            self.pinStatusView.startButton.alpha = Self.ACTIVE_ALPHA
        }
    }

    func tagReaderSession(
        _ session: NFCTagReaderSession,
        didDetect tags: [NFCTag]
    ) {
        let msgReadingHeader = "読み取り中\n"
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
                self.publishLargeLog("# 暗証番号ステータスの読み取り開始")
                print("thread: \(Thread.current)")
                session.alertMessage = "\(msgReadingHeader)カード種別の判別..."
                let cardType = try reader.detectCardType()
                session.alertMessage += "成功"
                switch cardType {
                case .IN:
                    self.publishLargeLog("カード種別: マイナンバーカード")
                    session.alertMessage = "\(msgReadingHeader)暗証番号ステータスの取得..."
                    let textAP = try reader.selectINText()
                    let textPin = try textAP.getPin()
                    let textPinA = try textAP.getPinA()
                    let textPinB = try textAP.getPinB()
                    var msg = "券面入力補助AP 暗証番号: \(textPin)\n"
                    msg += "券面入力補助AP 暗証番号A: \(textPinA)\n"
                    msg += "券面入力補助AP 暗証番号B: \(textPinB)\n"

                    let visualAP = try reader.selectINVisual()
                    let visualPinA = try visualAP.getPinA()
                    let visualPinB = try visualAP.getPinB()
                    session.alertMessage += "成功"
                    msg += "券面AP 暗証番号A: \(visualPinA)\n"
                    msg += "券面AP 暗証番号B: \(visualPinB)\n"

                    do {
                        let indlAP = try reader.selectINDL()
                        let indlPin = try indlAP.getPin()
                        msg += "マイナ運転免許証AP 暗証番号: \(indlPin)\n"
                    } catch {
                        // マイナ運転免許証APなし
                    }
                    self.publishLargeLog(msg)
                case .DL:
                    self.publishLargeLog("カード種別: 運転免許証")
                    let ap = try reader.selectDL()
                    session.alertMessage = "\(msgReadingHeader)暗証番号ステータスの取得..."
                    let pin1 = try ap.getPin1()
                    let pin2 = try ap.getPin2()
                    session.alertMessage += "成功"
                    var msg = "暗証番号1: \(pin1)\n"
                    msg += "暗証番号2: \(pin2)"
                    self.publishLargeLog(msg)
                case .JUKI:
                    self.publishLargeLog("カード種別: 住基カード")
                case .EP:
                    self.publishLargeLog("カード種別: パスポート")
                case .RC:
                    let ap = try reader.selectRC()
                    let freeFiles = try ap.readFiles()
                    let cardType = try freeFiles.getCardType()
                    switch cardType.type {
                    case "1":
                        self.publishLargeLog("カード種別: 在留カード")
                    case "2":
                        self.publishLargeLog("カード種別: 特別永住者証明書")
                    default:
                        self.publishLargeLog("カード種別: 在留カード等(不明)")
                    }
                default:
                    self.publishLargeLog("カード種別: 不明")
                }
                session.alertMessage = "読み取り完了"
                session.invalidate()
            } catch {
                session.invalidate(errorMessage: session.alertMessage + "失敗")
                self.publishLog("\(error)")
            }
        }
    }
}
