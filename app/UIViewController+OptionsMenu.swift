//
//  UIViewController+OptionsMenu.swift
//  libjeid-ios-app
//
//  Copyright © 2019 Open Source Solution Technology Corporation
//  All rights reserved.
//

import UIKit

extension UIViewController {
    func installOptionsMenuButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "︙", style: .done, target: self,
            action: #selector(presentOptionsMenu))
    }

    @objc func presentOptionsMenu() {
        let vc = OptionsMenuViewController()
        vc.modalPresentationStyle = .overCurrentContext
        vc.closeHandler = { $0.dismiss(animated: false) }
        present(vc, animated: false)
    }
}
