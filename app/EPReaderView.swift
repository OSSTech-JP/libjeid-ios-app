//
//  EPReaderView.swift
//  libjeid-ios-app
//
//  Copyright © 2020 Open Source Solution Technology Corporation
//  All rights reserved.
//

import UIKit

class EPReaderView: UIView {
    let numberField: UITextField
    let birthDateField: UITextField
    let expireDateField: UITextField
    let startButton: UIButton
    /// MRZをカメラで読み取るボタン。
    let scanButton: UIButton
    /// 生年月日の入力形式を説明するボタン。
    let birthDateHelpButton: UIButton
    /// 有効期限の入力形式を説明するボタン。
    let expireDateHelpButton: UIButton

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        let explanation = CustomViewUtil.createTextView(
            CustomViewUtil.screenSize)
        explanation.text =
            "読み取り開始ボタンを押下後、端末をパスポートにかざしてください。\n"
            + "生年月日および有効期限は年2桁、月2桁、日2桁の6文字を入力してください。\n"
            + "カメラのボタンを押すと、パスポート下部のMRZから自動入力できます。\n"
            + "古い端末、古いパスポートは読めないことがあります。"

        let numberLabel = CustomViewUtil.createTextView(
            CustomViewUtil.screenSize)
        numberLabel.text = "パスポート番号"

        numberField = CustomViewUtil.createTextField(CustomViewUtil.screenSize)
        numberField.keyboardType = UIKeyboardType.asciiCapable
        numberField.autocapitalizationType = .allCharacters

        scanButton = CustomViewUtil.createIconButton(
            CustomViewUtil.screenSize, systemName: "camera")
        scanButton.backgroundColor = CustomColor.buttonBackground
        scanButton.layer.cornerRadius = 8
        scanButton.accessibilityLabel = "MRZをカメラで読み取る"

        let numberFieldStackView = CustomViewUtil.createHorizontalStackView(
            CustomViewUtil.screenSize)
        numberFieldStackView.addArrangedSubview(numberField)
        numberFieldStackView.addArrangedSubview(scanButton)

        let numberStackView = CustomViewUtil.createNarrowVerticalStackView(
            CustomViewUtil.screenSize)
        numberStackView.addArrangedSubview(numberLabel)
        numberStackView.addArrangedSubview(numberFieldStackView)

        let birthDateLabel = CustomViewUtil.createTextView(
            CustomViewUtil.screenSize)
        birthDateLabel.text = "生年月日(YYMMDD)"

        birthDateHelpButton = CustomViewUtil.createIconButton(
            CustomViewUtil.screenSize, systemName: "questionmark.circle")
        birthDateHelpButton.accessibilityLabel = "生年月日の入力形式について"

        let birthDateLabelStackView = CustomViewUtil.createHorizontalStackView(
            CustomViewUtil.screenSize)
        birthDateLabelStackView.addArrangedSubview(birthDateLabel)
        birthDateLabelStackView.addArrangedSubview(birthDateHelpButton)

        birthDateField = CustomViewUtil.createTextField(
            CustomViewUtil.screenSize)
        birthDateField.keyboardType = UIKeyboardType.numberPad
        birthDateField.placeholder = "YYMMDD"

        let birthDateStackView = CustomViewUtil.createNarrowVerticalStackView(
            CustomViewUtil.screenSize)
        birthDateStackView.addArrangedSubview(birthDateLabelStackView)
        birthDateStackView.addArrangedSubview(birthDateField)

        let expireDateLabel = CustomViewUtil.createTextView(
            CustomViewUtil.screenSize)
        expireDateLabel.text = "有効期限(YYMMDD)"

        expireDateHelpButton = CustomViewUtil.createIconButton(
            CustomViewUtil.screenSize, systemName: "questionmark.circle")
        expireDateHelpButton.accessibilityLabel = "有効期限の入力形式について"

        let expireDateLabelStackView = CustomViewUtil.createHorizontalStackView(
            CustomViewUtil.screenSize)
        expireDateLabelStackView.addArrangedSubview(expireDateLabel)
        expireDateLabelStackView.addArrangedSubview(expireDateHelpButton)

        expireDateField = CustomViewUtil.createTextField(
            CustomViewUtil.screenSize)
        expireDateField.keyboardType = UIKeyboardType.numberPad
        expireDateField.placeholder = "YYMMDD"

        let expireDateStackView = CustomViewUtil.createNarrowVerticalStackView(
            CustomViewUtil.screenSize)
        expireDateStackView.addArrangedSubview(expireDateLabelStackView)
        expireDateStackView.addArrangedSubview(expireDateField)

        startButton = CustomViewUtil.createButton(CustomViewUtil.screenSize)
        startButton.setTitle("読み取り開始", for: .normal)

        let stackView = CustomViewUtil.createVerticalStackView(
            CustomViewUtil.screenSize)
        stackView.addArrangedSubview(explanation)
        stackView.addArrangedSubview(numberStackView)
        stackView.addArrangedSubview(birthDateStackView)
        stackView.addArrangedSubview(expireDateStackView)
        stackView.addArrangedSubview(startButton)

        super.init(frame: .zero)
        self.addSubview(stackView)

        stackView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive =
            true
        stackView.centerXAnchor.constraint(equalTo: self.centerXAnchor)
            .isActive = true
        stackView.widthAnchor.constraint(equalTo: self.widthAnchor).isActive =
            true
    }

    override func traitCollectionDidChange(
        _ previousTraitCollection: UITraitCollection?
    ) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection!.hasDifferentColorAppearance(
            comparedTo: traitCollection)
        {
            numberField.layer.borderColor = CustomColor.textFieldBorder.cgColor
            birthDateField.layer.borderColor =
                CustomColor.textFieldBorder.cgColor
            expireDateField.layer.borderColor =
                CustomColor.textFieldBorder.cgColor
        }
    }
}
