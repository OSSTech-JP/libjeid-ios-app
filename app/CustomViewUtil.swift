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
    private static let CAPTION_TEXT_SIZE_DENOMINATOR = CGFloat(28)
    private static let MENU_CARD_CORNER_RADIUS = CGFloat(12)
    private static let MENU_CARD_PADDING = CGFloat(16)
    private static let MENU_CARD_TEXT_SPACING = CGFloat(2)

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

    static func createCaptionTextFont(_ size: CGSize) -> UIFont {
        let fontSize = CGFloat(
            min(size.width, size.height) / CAPTION_TEXT_SIZE_DENOMINATOR)
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

    /// メニュー項目のカードを生成します。
    ///
    /// アイコン、タイトル、説明、シェブロンを横に並べた角丸のボタンです。
    /// 内容のビューはタッチを受け取らないため、どこを押してもボタンが反応します。
    ///
    /// - Parameters:
    ///   - size: 画面サイズ
    ///   - systemName: 左に表示するSFシンボル名
    ///   - title: 項目名
    ///   - description: 項目の説明
    /// - Returns: 生成したボタン
    static func createMenuCard(
        _ size: CGSize, systemName: String, title: String, description: String
    ) -> UIButton {
        let button = CustomButton(type: .custom)
        button.backgroundColor = CustomColor.menuItemBackground
        button.highlightedBackgroundColor =
            CustomColor.menuItemHighlightedBackground
        button.layer.cornerRadius = MENU_CARD_CORNER_RADIUS
        button.translatesAutoresizingMaskIntoConstraints = false

        let iconPointSize = CGFloat(
            min(size.width, size.height) / TEXT_FIELD_HEIGHT_DENOMINATOR)
        let iconView = UIImageView(
            image: UIImage(
                systemName: systemName,
                withConfiguration: UIImage.SymbolConfiguration(
                    pointSize: iconPointSize)))
        iconView.tintColor = CustomColor.menuItemIcon
        iconView.contentMode = .scaleAspectFit

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = CustomColor.menuItemTitle
        titleLabel.font = UIFont.boldSystemFont(
            ofSize: CGFloat(
                min(size.width, size.height) / MEDIUM_TEXT_SIZE_DENOMINATOR))
        titleLabel.numberOfLines = 0

        let descriptionLabel = UILabel()
        descriptionLabel.text = description
        descriptionLabel.textColor = CustomColor.menuItemDescription
        descriptionLabel.font = createCaptionTextFont(size)
        descriptionLabel.numberOfLines = 0

        let chevronView = UIImageView(
            image: UIImage(
                systemName: "chevron.right",
                withConfiguration: UIImage.SymbolConfiguration(
                    pointSize: createCaptionTextFont(size).pointSize)))
        chevronView.tintColor = CustomColor.menuItemChevron
        chevronView.contentMode = .scaleAspectFit

        let textStackView = UIStackView(
            arrangedSubviews: [titleLabel, descriptionLabel])
        textStackView.axis = .vertical
        textStackView.alignment = .fill
        textStackView.distribution = .fill
        textStackView.spacing = MENU_CARD_TEXT_SPACING

        let stackView = UIStackView(
            arrangedSubviews: [iconView, textStackView, chevronView])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = MENU_CARD_PADDING
        stackView.translatesAutoresizingMaskIntoConstraints = false
        // タップをボタンへ通すため、内容はタッチを受け取らないようにする
        stackView.isUserInteractionEnabled = false
        button.addSubview(stackView)

        // アイコンとシェブロンは固有の幅を保ち、余った幅は文字に割り当てる
        for view in [iconView, chevronView] {
            view.setContentHuggingPriority(.required, for: .horizontal)
            view.setContentCompressionResistancePriority(
                .required, for: .horizontal)
        }

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(
                equalTo: button.topAnchor, constant: MENU_CARD_PADDING),
            stackView.bottomAnchor.constraint(
                equalTo: button.bottomAnchor, constant: MENU_CARD_PADDING * -1),
            stackView.leadingAnchor.constraint(
                equalTo: button.leadingAnchor, constant: MENU_CARD_PADDING),
            stackView.trailingAnchor.constraint(
                equalTo: button.trailingAnchor,
                constant: MENU_CARD_PADDING * -1),
            iconView.widthAnchor.constraint(
                equalToConstant: iconPointSize * 1.25),
        ])
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

    /// オプションメニューの項目を生成します。
    ///
    /// 題名は呼び出し元が`setTitle(_:for:)`で設定します。
    ///
    /// - Parameter size: 画面サイズ
    /// - Returns: 生成したボタン
    static func createMenuItem(_ size: CGSize) -> UIButton {
        let button = UIButton(type: .custom)
        let fontSize = CGFloat(
            min(size.width, size.height) / SMALL_TEXT_SIZE_DENOMINATOR)
        var configuration = UIButton.Configuration.plain()
        configuration.contentInsets = NSDirectionalEdgeInsets(
            top: fontSize * 0.75, leading: fontSize * 0.75,
            bottom: fontSize * 0.75, trailing: fontSize * 0.75)
        configuration.baseForegroundColor = CustomColor.optionsMenuItemTitle
        // setTitle()で設定された題名にフォントを適用する
        configuration.titleTextAttributesTransformer =
            UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = UIFont.systemFont(ofSize: fontSize)
                return outgoing
            }
        button.configuration = configuration
        button.contentHorizontalAlignment = .leading
        // CustomButtonのbackgroundColor差し替えはconfigurationと併用できないため、
        // 押下時の背景はconfigurationUpdateHandlerで切り替える
        button.configurationUpdateHandler = { button in
            button.configuration?.background.backgroundColor =
                button.isHighlighted
                ? CustomColor.menuItemHighlightedBackground
                : CustomColor.optionsMenuItemBackground
        }
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
