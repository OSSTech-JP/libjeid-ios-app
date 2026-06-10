//
//  WrapperViewController.swift
//  libjeid-ios-app
//
//  Copyright © 2019 Open Source Solution Technology Corporation
//  All rights reserved.
//

import UIKit

class WrapperViewController: UIViewController, UITextFieldDelegate {
    var logView: UITextView?
    var scrollView: UIScrollView?
    var activeField: UITextField?
    private var previousKeyboardHeight: CGFloat = CGFloat(0)
    private var previousViewSize: CGSize?
    private var hasResized: Bool = false
    private var logFont: UIFont?
    private var largeLogFont: UIFont?

    internal static let ACTIVE_ALPHA = CGFloat(1.0)
    internal static let INACTIVE_ALPHA = CGFloat(0.5)

    override func viewDidLoad() {
        super.viewDidLoad()
        if let wrapperView = self.view as? WrapperView {
            scrollView = wrapperView.scrollView
            logView = wrapperView.logView
            logFont = wrapperView.logView.font
        }
        largeLogFont = CustomViewUtil.createMediumTextFont(
            CustomViewUtil.screenSize)
        installOptionsMenuButton()
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeField = textField
        hasResized = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(
            self,
            selector: #selector(keyboardDidShow(_:)),
            name: UIResponder.keyboardDidShowNotification, object: nil)
        notificationCenter.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self)
    }

    @objc func keyboardWillShow(_ notification: Notification?) {
        if hasResized {
            return
        }
        let keyboardHeight =
            (notification?.userInfo![UIResponder.keyboardFrameEndUserInfoKey]
            as! NSValue).cgRectValue.size.height
        resizeScrollView(keyboardHeight)
        hasResized = true
        previousKeyboardHeight = keyboardHeight
        previousViewSize = view.bounds.size
    }

    @objc func keyboardDidShow(_ notification: Notification?) {
        let keyboardHeight =
            (notification?.userInfo![UIResponder.keyboardFrameEndUserInfoKey]
            as! NSValue).cgRectValue.size.height
        if keyboardHeight != previousKeyboardHeight {
            // keyboardWillShowの時点でキーボードの高さが正常に取得できなかった場合、ここで再度リサイズする
            resizeScrollView(keyboardHeight)
            hasResized = true
            previousKeyboardHeight = keyboardHeight
            previousViewSize = view.bounds.size
        }
    }

    @objc func keyboardWillHide(_ notification: Notification?) {
        if let previousViewSize = self.previousViewSize {
            if !self.view.bounds.size.equalTo(previousViewSize) {
                hasResized = false
            }
        }
        if hasResized {
            let keyboardHeight =
                (notification?.userInfo![
                    UIResponder.keyboardFrameEndUserInfoKey] as! NSValue)
                .cgRectValue.size.height
            undoResizing(keyboardHeight)
            hasResized = false
        }
        previousKeyboardHeight = 0
    }

    func clearPublishedLog() {
        DispatchQueue.main.async {
            if let logView = self.logView {
                logView.isEditable = true
                logView.text = nil
                logView.isEditable = false
            }
        }
    }

    func publishLog(_ text: String) {
        publishLog(text, logFont)
    }

    func publishLargeLog(_ text: String) {
        publishLog(text, largeLogFont)
    }

    private func publishLog(_ text: String, _ font: UIFont?) {
        DispatchQueue.main.async {
            if let logView = self.logView {
                if logView.font != font {
                    logView.font = font
                }
                logView.isEditable = true
                logView.insertText(text + "\n")
                logView.isEditable = false
            }
            // 追記のたびに最新行(エラーを含む)が見えるよう最下部へスクロールする
            self.scrollLogToBottom()
        }
    }

    /// ログ(外側スクロールビュー)を最下部までスクロールして最新行を表示する。
    private func scrollLogToBottom() {
        guard let scrollView = self.scrollView else {
            return
        }
        scrollView.layoutIfNeeded()
        let visibleHeight = scrollView.bounds.height
            - scrollView.adjustedContentInset.top
            - scrollView.adjustedContentInset.bottom
        let offsetY = scrollView.contentSize.height - visibleHeight
        if offsetY > 0 {
            scrollView.setContentOffset(
                CGPoint(x: 0, y: offsetY - scrollView.adjustedContentInset.top),
                animated: false)
        }
    }

    func openAlertView(_ title: String, _ message: String) {
        DispatchQueue.main.async {
            let alertController: UIAlertController = UIAlertController(
                title: title, message: message, preferredStyle: .alert)
            let okAction = UIAlertAction(
                title: "OK", style: .default, handler: nil)
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }

    private func resizeScrollView(_ keyboardHeight: CGFloat) {
        if let activeField = activeField,
            let scrollView = self.scrollView
        {
            let fieldBottom =
                (scrollView.frame.origin.y + getActiveFieldOriginY(activeField)
                    - scrollView.contentOffset.y)
                + activeField.frame.height
            let margin = activeField.frame.height * 0.5
            let keyboardTop = CustomViewUtil.screenSize.height - keyboardHeight
            if fieldBottom + margin >= keyboardTop {
                scrollView.contentOffset.y += fieldBottom + margin - keyboardTop
            }
            scrollView.contentSize.height +=
                keyboardHeight - previousKeyboardHeight
        }
    }

    private func undoResizing(_ keyboardHeight: CGFloat) {
        if let scrollView = self.scrollView {
            scrollView.contentSize.height -= keyboardHeight
        }
    }

    private func getActiveFieldOriginY(_ textField: UITextField) -> CGFloat {
        var originY = CGFloat(0)
        var view: UIView = textField
        while !view.isEqual(scrollView) {
            originY += view.frame.origin.y
            guard let superview = view.superview else {
                return originY
            }
            view = superview
        }
        return originY
    }

}
