//
//  CustomViewUtil.swift
//  libjeid-ios-app
//
//  Copyright © 2019-2020 Open Source Solution Technology Corporation
//  All rights reserved.
//

import UIKit

class CustomViewUtil: UIView {
    static var screenSize: CGSize {
        UIScreen.main.bounds.size
    }

    private static let LARGE_TEXT_SIZE_DENOMINATOR = CGFloat(18)
    private static let MEDIUM_TEXT_SIZE_DENOMINATOR = CGFloat(20)
    private static let SMALL_TEXT_SIZE_DENOMINATOR = CGFloat(24)
    private static let TEXT_FIELD_HEIGHT_DENOMINATOR = CGFloat(12)
    private static let BUTTON_LABEL_FONT_SIZE_DENOMINATOR = CGFloat(16)
    private static let STACK_VIEW_WIDE_SPACING_DENOMINATOR = CGFloat(20)
    private static let STACK_VIEW_NARROW_SPACING_DENOMINATOR = CGFloat(50)
    private static let AUTO_LAYOUT_PADDING_DENOMINATOR = CGFloat(20)

    static func createLargeTextFont(_ size: CGSize) -> UIFont {
        let fontSize = CGFloat(
            min(size.width, size.height) / LARGE_TEXT_SIZE_DENOMINATOR)
        return UIFont.systemFont(ofSize: fontSize)
    }

    static func createMediumTextFont(_ size: CGSize) -> UIFont {
        let fontSize = CGFloat(
            min(size.width, size.height) / MEDIUM_TEXT_SIZE_DENOMINATOR)
        return UIFont.systemFont(ofSize: fontSize)
    }

    static func createSmallTextFont(_ size: CGSize) -> UIFont {
        let fontSize = CGFloat(
            min(size.width, size.height) / SMALL_TEXT_SIZE_DENOMINATOR)
        return UIFont.systemFont(ofSize: fontSize)
    }

    static func getAutoLayoutPadding(_ size: CGSize) -> CGFloat {
        return CGFloat(
            min(size.width, size.height) / AUTO_LAYOUT_PADDING_DENOMINATOR)
    }

    static func createButton(_ size: CGSize) -> UIButton {
        let button = CustomButton(type: .custom)
        button.backgroundColor = CustomColor.buttonBackground
        button.highlightedBackgroundColor =
            CustomColor.buttonHighlightedBackground
        button.setTitleColor(CustomColor.buttonTitle, for: .normal)
        button.setTitleColor(CustomColor.buttonTitle, for: .highlighted)
        let fontSize = CGFloat(
            min(size.width, size.height) / BUTTON_LABEL_FONT_SIZE_DENOMINATOR)
        button.titleLabel?.font = UIFont.systemFont(ofSize: fontSize)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    /// SFシンボルのみを表示する正方形のボタンを生成します。
    ///
    /// 背景は透明とし、必要な呼び出し元が `backgroundColor` と `layer.cornerRadius` を
    /// 設定して枠付きにする。
    ///
    /// - Parameters:
    ///   - size: 画面サイズ
    ///   - systemName: SFシンボル名
    /// - Returns: 生成したボタン
    static func createIconButton(_ size: CGSize, systemName: String) -> UIButton
    {
        let button = CustomButton(type: .custom)
        button.backgroundColor = .clear
        button.highlightedBackgroundColor =
            CustomColor.menuItemHighlightedBackground
        button.tintColor = CustomColor.text
        let pointSize = CGFloat(
            min(size.width, size.height) / MEDIUM_TEXT_SIZE_DENOMINATOR)
        let configuration = UIImage.SymbolConfiguration(pointSize: pointSize)
        button.setImage(
            UIImage(systemName: systemName, withConfiguration: configuration),
            for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        // 指で押しやすい寸法を確保する(Human Interface Guidelinesの44pt)
        let side = max(
            CGFloat(44),
            CGFloat(min(size.width, size.height) / TEXT_FIELD_HEIGHT_DENOMINATOR
            ))
        button.widthAnchor.constraint(equalToConstant: side).isActive = true
        button.heightAnchor.constraint(equalToConstant: side).isActive = true
        return button
    }

    static func createHorizontalStackView(_ size: CGSize) -> UIStackView {
        let stackView = UIStackView(frame: .zero)
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        let spacing = CGFloat(
            min(size.width, size.height) / STACK_VIEW_NARROW_SPACING_DENOMINATOR
        )
        stackView.spacing = spacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }

    static func createMenuItem(_ size: CGSize) -> UIButton {
        let button = CustomButton(type: .custom)
        button.backgroundColor = CustomColor.optionsMenuItemBackground
        button.highlightedBackgroundColor =
            CustomColor.menuItemHighlightedBackground
        button.setTitleColor(CustomColor.optionsMenuItemTitle, for: .normal)
        button.setTitleColor(
            CustomColor.optionsMenuItemTitle, for: .highlighted)
        let fontSize = CGFloat(
            min(size.width, size.height) / SMALL_TEXT_SIZE_DENOMINATOR)
        button.titleLabel?.font = UIFont.systemFont(ofSize: fontSize)
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(
            top: fontSize * 0.75, left: fontSize * 0.75,
            bottom: fontSize * 0.75, right: fontSize * 0.75)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    static func createLogView(_ size: CGSize) -> UITextView {
        let textView = UITextView()
        textView.textColor = CustomColor.text
        textView.font = createSmallTextFont(size)
        textView.backgroundColor = CustomColor.background
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }

    static func createVerticalStackView(_ size: CGSize) -> UIStackView {
        let stackView = UIStackView(frame: .zero)
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        let spacing = CGFloat(
            min(size.width, size.height) / STACK_VIEW_WIDE_SPACING_DENOMINATOR)
        stackView.spacing = spacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }

    static func createNarrowVerticalStackView(_ size: CGSize) -> UIStackView {
        let stackView = createVerticalStackView(size)
        let spacing = CGFloat(
            min(size.width, size.height) / STACK_VIEW_NARROW_SPACING_DENOMINATOR
        )
        stackView.spacing = spacing
        return stackView
    }

    static func createNoSpaceVerticalStackView(_ size: CGSize) -> UIStackView {
        let stackView = createVerticalStackView(size)
        stackView.spacing = 0
        return stackView
    }

    static func createTextField(_ size: CGSize) -> UITextField {
        let textField = UITextField()
        textField.textColor = CustomColor.textFieldText
        textField.font = createLargeTextFont(size)
        textField.backgroundColor = CustomColor.textFieldBackground
        textField.borderStyle = UITextField.BorderStyle.roundedRect
        textField.layer.borderColor = CustomColor.textFieldBorder.cgColor
        textField.layer.borderWidth = 1
        textField.translatesAutoresizingMaskIntoConstraints = false
        let textFieldHeight = CGFloat(
            min(size.width, size.height) / TEXT_FIELD_HEIGHT_DENOMINATOR)
        textField.heightAnchor.constraint(
            equalToConstant: CGFloat(
                textFieldHeight + textField.layer.borderWidth * 2)
        )
        .isActive = true
        return textField
    }

    static func createTextView(_ size: CGSize) -> UITextView {
        let textView = UITextView()
        textView.textColor = CustomColor.text
        textView.font = createLargeTextFont(size)
        textView.backgroundColor = CustomColor.background
        textView.textContainerInset = UIEdgeInsets.zero
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }
}
