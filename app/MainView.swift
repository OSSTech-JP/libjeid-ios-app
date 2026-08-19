//
//  MainView.swift
//  libjeid-ios-app
//
//  Copyright © 2019 Open Source Solution Technology Corporation
//  All rights reserved.
//

import UIKit

class MainView: UIView {
    let inButton: UIButton
    let dlButton: UIButton
    let indlButton: UIButton
    let epButton: UIButton
    let rcButton: UIButton
    let rc2Button: UIButton
    let rcsButton: UIButton
    let pinButton: UIButton

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        inButton = CustomViewUtil.createMenuCard(
            CustomViewUtil.screenSize,
            systemName: "person.text.rectangle",
            title: "マイナンバーカード",
            description: "氏名・住所など券面事項を読み取り")

        dlButton = CustomViewUtil.createMenuCard(
            CustomViewUtil.screenSize,
            systemName: "car",
            title: "運転免許証",
            description: "ICチップの記録事項を読み取り")

        indlButton = CustomViewUtil.createMenuCard(
            CustomViewUtil.screenSize,
            systemName: "car",
            title: "マイナ免許証",
            description: "カードに記録された免許情報を読み取り")

        epButton = CustomViewUtil.createMenuCard(
            CustomViewUtil.screenSize,
            systemName: "book.closed",
            title: "パスポート",
            description: "券面情報と顔画像を読み取り")
        //epButton.isHidden = true

        rcButton = CustomViewUtil.createMenuCard(
            CustomViewUtil.screenSize,
            systemName: "globe",
            title: "在留カード",
            description: "第1世代の在留カード・特別永住者証明書")

        rc2Button = CustomViewUtil.createMenuCard(
            CustomViewUtil.screenSize,
            systemName: "globe",
            title: "第2世代在留カード",
            description: "第2世代の在留カード")

        rcsButton = CustomViewUtil.createMenuCard(
            CustomViewUtil.screenSize,
            systemName: "globe",
            title: "特定在留カード",
            description: "マイナンバーカード上の在留情報を読み取り")

        pinButton = CustomViewUtil.createMenuCard(
            CustomViewUtil.screenSize,
            systemName: "lock",
            title: "暗証番号ステータス",
            description: "暗証番号の残り試行回数を確認")

        let stackView = CustomViewUtil.createVerticalStackView(
            CustomViewUtil.screenSize)
        stackView.addArrangedSubview(inButton)
        stackView.addArrangedSubview(dlButton)
        stackView.addArrangedSubview(indlButton)
        stackView.addArrangedSubview(epButton)
        stackView.addArrangedSubview(rcButton)
        stackView.addArrangedSubview(rc2Button)
        stackView.addArrangedSubview(rcsButton)
        stackView.addArrangedSubview(pinButton)

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
}
