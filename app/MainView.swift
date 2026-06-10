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
    let pinButton: UIButton

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        inButton = CustomViewUtil.createButton(CustomViewUtil.screenSize)
        inButton.setTitle("マイナンバーカード", for: .normal)

        dlButton = CustomViewUtil.createButton(CustomViewUtil.screenSize)
        dlButton.setTitle("運転免許証", for: .normal)

        indlButton = CustomViewUtil.createButton(CustomViewUtil.screenSize)
        indlButton.setTitle("マイナ免許証", for: .normal)

        epButton = CustomViewUtil.createButton(CustomViewUtil.screenSize)
        epButton.setTitle("パスポート", for: .normal)
        //epButton.isHidden = true

        rcButton = CustomViewUtil.createButton(CustomViewUtil.screenSize)
        rcButton.setTitle("在留カード", for: .normal)

        pinButton = CustomViewUtil.createButton(CustomViewUtil.screenSize)
        pinButton.setTitle("暗証番号ステータス", for: .normal)

        let stackView = CustomViewUtil.createVerticalStackView(
            CustomViewUtil.screenSize)
        stackView.addArrangedSubview(inButton)
        stackView.addArrangedSubview(dlButton)
        stackView.addArrangedSubview(indlButton)
        stackView.addArrangedSubview(epButton)
        stackView.addArrangedSubview(rcButton)
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
