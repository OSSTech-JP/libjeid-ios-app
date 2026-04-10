//
//  WrapperView.swift
//  libjeid-ios-app
//
//  Copyright © 2019-2020 Open Source Solution Technology Corporation
//  All rights reserved.
//

import UIKit

class WrapperView: UIView {
    let scrollView: UIScrollView
    let logView: UITextView

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(_ view: UIView) {
        let stackView = CustomViewUtil.createVerticalStackView(
            CustomViewUtil.screenSize)
        logView = CustomViewUtil.createLogView(CustomViewUtil.screenSize)
        stackView.addArrangedSubview(view)
        stackView.addArrangedSubview(logView)

        scrollView = CustomScrollView()
        scrollView.delaysContentTouches = false
        scrollView.addSubview(stackView)
        super.init(frame: .zero)
        self.addSubview(scrollView)
        self.backgroundColor = CustomColor.background

        stackView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive =
            true
        stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
            .isActive = true
        stackView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor)
            .isActive = true
        stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
            .isActive = true

        let paddingSize = CustomViewUtil.getAutoLayoutPadding(
            CustomViewUtil.screenSize)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.topAnchor.constraint(
            equalTo: self.safeAreaLayoutGuide.topAnchor,
            constant: paddingSize
        ).isActive = true
        scrollView.leadingAnchor.constraint(
            equalTo: self.safeAreaLayoutGuide.leadingAnchor,
            constant: paddingSize
        ).isActive = true
        scrollView.trailingAnchor.constraint(
            equalTo: self.safeAreaLayoutGuide.trailingAnchor,
            constant: paddingSize * -1
        ).isActive = true
        scrollView.bottomAnchor.constraint(
            equalTo: self.safeAreaLayoutGuide.bottomAnchor,
            constant: paddingSize * -1
        ).isActive = true
    }
}
