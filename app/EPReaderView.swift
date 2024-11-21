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

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        let explanation = CustomViewUtil.createTextView(
            UIScreen.main.bounds.size)
        explanation.text =
            "読み取り開始ボタンを押下後、端末をパスポートにかざしてください。\n"
            + "生年月日および有効期限は年4桁、月2桁、日2桁の8文字を入力してください。"

        let numberLabel = CustomViewUtil.createTextView(
            UIScreen.main.bounds.size)
        numberLabel.text = "パスポート番号"

        numberField = CustomViewUtil.createTextField(UIScreen.main.bounds.size)
        numberField.keyboardType = UIKeyboardType.asciiCapable
        numberField.autocapitalizationType = .allCharacters

        let numberStackView = CustomViewUtil.createNarrowVerticalStackView(
            UIScreen.main.bounds.size)
        numberStackView.addArrangedSubview(numberLabel)
        numberStackView.addArrangedSubview(numberField)

        let birthDateLabel = CustomViewUtil.createTextView(
            UIScreen.main.bounds.size)
        birthDateLabel.text = "生年月日"

        birthDateField = CustomViewUtil.createTextField(
            UIScreen.main.bounds.size)
        birthDateField.keyboardType = UIKeyboardType.numberPad
        birthDateField.placeholder = "YYYYMMDD"

        let birthDateStackView = CustomViewUtil.createNarrowVerticalStackView(
            UIScreen.main.bounds.size)
        birthDateStackView.addArrangedSubview(birthDateLabel)
        birthDateStackView.addArrangedSubview(birthDateField)

        let expireDateLabel = CustomViewUtil.createTextView(
            UIScreen.main.bounds.size)
        expireDateLabel.text = "有効期限"

        expireDateField = CustomViewUtil.createTextField(
            UIScreen.main.bounds.size)
        expireDateField.keyboardType = UIKeyboardType.numberPad
        expireDateField.placeholder = "YYYYMMDD"

        let expireDateStackView = CustomViewUtil.createNarrowVerticalStackView(
            UIScreen.main.bounds.size)
        expireDateStackView.addArrangedSubview(expireDateLabel)
        expireDateStackView.addArrangedSubview(expireDateField)

        startButton = CustomViewUtil.createButton(UIScreen.main.bounds.size)
        startButton.setTitle("読み取り開始", for: .normal)

        let stackView = CustomViewUtil.createVerticalStackView(
            UIScreen.main.bounds.size)
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
