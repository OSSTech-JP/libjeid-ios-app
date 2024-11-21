//
//  MainViewController.swift
//  libjeid-ios-app
//
//  Copyright © 2019 Open Source Solution Technology Corporation
//  All rights reserved.
//

import UIKit

class MainViewController: WrapperViewController {
    var mainView: MainView!

    override func loadView() {
        let bundleName =
            Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! String
        self.title = bundleName
        mainView = MainView()
        mainView.inButton.addTarget(
            self, action: #selector(pushInButton), for: .touchUpInside)
        mainView.dlButton.addTarget(
            self, action: #selector(pushDlButton), for: .touchUpInside)
        mainView.epButton.addTarget(
            self, action: #selector(pushEpButton), for: .touchUpInside)
        mainView.rcButton.addTarget(
            self, action: #selector(pushRcButton), for: .touchUpInside)
        mainView.pinButton.addTarget(
            self, action: #selector(pushPinButton), for: .touchUpInside)

        let wrapperView = WrapperView(mainView)
        wrapperView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        wrapperView.logView.isHidden = true
        self.view = wrapperView
    }

    @objc func pushInButton(sender: UIButton) {
        let nextViewController = INReaderViewController()
        self.navigationController?.pushViewController(
            nextViewController, animated: true)
    }

    @objc func pushDlButton(sender: UIButton) {
        let nextViewController = DLReaderViewController()
        self.navigationController?.pushViewController(
            nextViewController, animated: true)
    }

    @objc func pushEpButton(sender: UIButton) {
        let nextViewController = EPReaderViewController()
        self.navigationController?.pushViewController(
            nextViewController, animated: true)
    }

    @objc func pushRcButton(sender: UIButton) {
        let nextViewController = RCReaderViewController()
        self.navigationController?.pushViewController(
            nextViewController, animated: true)
    }

    @objc func pushPinButton(sender: UIButton) {
        let nextViewController = PinStatusViewController()
        self.navigationController?.pushViewController(
            nextViewController, animated: true)
    }
}
