//
//  DLReaderView.swift
//  libjeid-ios-app
//
//  Copyright © 2019 Open Source Solution Technology Corporation
//  All rights reserved.
//

import UIKit

class DLReaderView: UIView {
    let pin1Field: UITextField
    let pin2Field: UITextField
    let startButton: UIButton

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        let explanation = CustomViewUtil.createTextView(
            CustomViewUtil.screenSize)
        explanation.text =
            "読み取り開始ボタンを押下後、端末を免許証にかざしてください。\n"
            + "暗証番号2は省略可能です。その場合、顔写真および本籍は表示されません。"

        let pin1Label = CustomViewUtil.createTextView(CustomViewUtil.screenSize)
        pin1Label.text = "暗証番号1(4桁、必須)"
        let pin2Label = CustomViewUtil.createTextView(CustomViewUtil.screenSize)
        pin2Label.text = "暗証番号2(4桁、任意)"

        pin1Field = CustomViewUtil.createTextField(CustomViewUtil.screenSize)
        pin1Field.isSecureTextEntry = true
        pin1Field.keyboardType = UIKeyboardType.numberPad

        pin2Field = CustomViewUtil.createTextField(CustomViewUtil.screenSize)
        pin2Field.isSecureTextEntry = true
        pin2Field.keyboardType = UIKeyboardType.numberPad

        let pin1StackView = CustomViewUtil.createNarrowVerticalStackView(
            CustomViewUtil.screenSize)
        pin1StackView.addArrangedSubview(pin1Label)
        pin1StackView.addArrangedSubview(pin1Field)

        let pin2StackView = CustomViewUtil.createNarrowVerticalStackView(
            CustomViewUtil.screenSize)
        pin2StackView.addArrangedSubview(pin2Label)
        pin2StackView.addArrangedSubview(pin2Field)

        startButton = CustomViewUtil.createButton(CustomViewUtil.screenSize)
        startButton.setTitle("読み取り開始", for: .normal)

        let stackView = CustomViewUtil.createVerticalStackView(
            CustomViewUtil.screenSize)
        stackView.addArrangedSubview(explanation)
        stackView.addArrangedSubview(pin1StackView)
        stackView.addArrangedSubview(pin2StackView)
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
            pin1Field.layer.borderColor = CustomColor.textFieldBorder.cgColor
            pin2Field.layer.borderColor = CustomColor.textFieldBorder.cgColor
        }
    }
}
