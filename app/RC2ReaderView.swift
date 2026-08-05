//
//  RC2ReaderView.swift
//  libjeid-ios-app
//
//  Copyright © 2026 Open Source Solution Technology Corporation
//  All rights reserved.
//

import UIKit

/// 第2世代在留カードの読み取り画面。`RCReaderView`(第1世代)と同じ構成で、
/// 説明文だけが異なります。
class RC2ReaderView: UIView {
    let numberField: UITextField
    let startButton: UIButton

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(_ explanationText: String) {
        let explanation = CustomViewUtil.createTextView(
            CustomViewUtil.screenSize)
        explanation.text = explanationText

        let numberLabel = CustomViewUtil.createTextView(
            CustomViewUtil.screenSize)
        numberLabel.text = "在留カード等の番号"

        numberField = CustomViewUtil.createTextField(CustomViewUtil.screenSize)
        numberField.keyboardType = UIKeyboardType.asciiCapable
        numberField.autocapitalizationType = .allCharacters

        let numberStackView = CustomViewUtil.createNarrowVerticalStackView(
            CustomViewUtil.screenSize)
        numberStackView.addArrangedSubview(numberLabel)
        numberStackView.addArrangedSubview(numberField)

        startButton = CustomViewUtil.createButton(CustomViewUtil.screenSize)
        startButton.setTitle("読み取り開始", for: .normal)

        let stackView = CustomViewUtil.createVerticalStackView(
            CustomViewUtil.screenSize)
        stackView.addArrangedSubview(explanation)
        stackView.addArrangedSubview(numberStackView)
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
        }
    }
}
