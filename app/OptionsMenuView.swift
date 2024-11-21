//
//  OptionsMenuView.swift
//  libjeid-ios-app
//
//  Copyright © 2020 Open Source Solution Technology Corporation
//  All rights reserved.
//

import UIKit

class OptionsMenuView: UIView {
    let rightView: UIView
    let scrollView: UIScrollView
    let stackView: UIStackView
    let aboutButton: UIButton

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        aboutButton = CustomViewUtil.createMenuItem(UIScreen.main.bounds.size)
        aboutButton.setTitle("このアプリについて", for: .normal)

        stackView = CustomViewUtil.createNoSpaceVerticalStackView(
            UIScreen.main.bounds.size)
        stackView.addArrangedSubview(aboutButton)

        let cornerRadius: CGFloat = 4
        scrollView = CustomScrollView()
        scrollView.layer.cornerRadius = cornerRadius
        scrollView.delaysContentTouches = false
        scrollView.isDirectionalLockEnabled = true
        scrollView.addSubview(stackView)

        rightView = UIView(frame: .zero)
        rightView.backgroundColor = CustomColor.optionsMenuBackground
        rightView.layer.cornerRadius = cornerRadius
        rightView.layer.shadowColor = CustomColor.optionsMenuShadow.cgColor
        rightView.layer.shadowOpacity = 0.2
        rightView.layer.shadowRadius = 4
        rightView.layer.shadowOffset = CGSize(width: 0, height: 0)
        rightView.addSubview(scrollView)

        super.init(frame: .zero)
        self.addSubview(rightView)

        stackView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive =
            true
        stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor)
            .isActive = true
        stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor)
            .isActive = true
        stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
            .isActive = true

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.topAnchor.constraint(equalTo: rightView.topAnchor).isActive =
            true
        scrollView.leadingAnchor.constraint(equalTo: rightView.leadingAnchor)
            .isActive = true
        scrollView.trailingAnchor.constraint(equalTo: rightView.trailingAnchor)
            .isActive = true
        scrollView.bottomAnchor.constraint(equalTo: rightView.bottomAnchor)
            .isActive = true

        let rightViewSize = self.rightViewSize
        rightView.translatesAutoresizingMaskIntoConstraints = false
        rightView.topAnchor.constraint(
            equalTo: self.safeAreaLayoutGuide.topAnchor,
            constant: rightViewMargin
        ).isActive = true
        rightView.trailingAnchor.constraint(
            equalTo: self.safeAreaLayoutGuide.trailingAnchor,
            constant: rightViewMargin * -1
        ).isActive = true
        rightView.widthAnchor.constraint(equalToConstant: rightViewSize.width)
            .isActive = true

        let heightConstraint = rightView.heightAnchor.constraint(
            equalToConstant: rightViewSize.height)
        heightConstraint.isActive = true
        heightConstraint.priority = UILayoutPriority(rawValue: 750)
        let bottomConstraint =
            rightView.bottomAnchor.constraint(
                lessThanOrEqualTo: self.safeAreaLayoutGuide.bottomAnchor,
                constant: rightViewMargin * -1)
        bottomConstraint.isActive = true
        bottomConstraint.priority = UILayoutPriority(rawValue: 1000)
    }

    private var stackViewMargin: CGFloat {
        return min(
            UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height)
            / 50
    }

    private var rightViewMargin: CGFloat {
        return 10
    }

    // rightViewの大きさは以下で計算する
    private var rightViewSize: CGSize {
        var width: CGFloat = 0
        var height: CGFloat = 0
        for view in stackView.subviews {
            if view.intrinsicContentSize.width > width {
                width = view.intrinsicContentSize.width
            }
            height += view.intrinsicContentSize.height
        }
        if stackView.subviews.count > 2 {
            height += stackView.spacing * CGFloat(stackView.subviews.count - 1)
        }
        let widthBaseSize = min(
            UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        let heightBaseSize =
            max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
            - rightViewMargin * 2
        if width < widthBaseSize * 0.2 {
            width = widthBaseSize * 0.2
        } else if width > widthBaseSize * 0.7 {
            width = widthBaseSize * 0.7
        }
        if stackView.subviews.count == 0 {
            height = heightBaseSize * 0.1
        }
        if height > heightBaseSize {
            height = heightBaseSize
        }
        return CGSize(width: ceil(width), height: ceil(height))
    }

    override func traitCollectionDidChange(
        _ previousTraitCollection: UITraitCollection?
    ) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection!.hasDifferentColorAppearance(
            comparedTo: traitCollection)
        {
            rightView.layer.shadowColor = CustomColor.optionsMenuShadow.cgColor
        }
    }
}
