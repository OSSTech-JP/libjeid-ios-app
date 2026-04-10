//
//  WebViewController.swift
//  libjeid-ios-app
//
//  Copyright © 2019 Open Source Solution Technology Corporation
//  All rights reserved.
//

import UIKit
@preconcurrency import WebKit

class WebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {

    var webview: WKWebView!
    var script: String?
    let url: URL

    init(_ url: URL, _ script: String?) {
        self.url = url
        self.script = script
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        let screenSize = CustomViewUtil.screenSize
        let paddingSize = CGFloat(min(screenSize.width, screenSize.height) / 50)

        webview = WKWebView(
            frame: view.bounds, configuration: WKWebViewConfiguration())
        view.backgroundColor = UIColor.white
        webview.uiDelegate = self
        webview.navigationDelegate = self

        view.addSubview(webview)

        webview.translatesAutoresizingMaskIntoConstraints = false
        webview.topAnchor.constraint(
            equalTo: self.view.safeAreaLayoutGuide.topAnchor,
            constant: paddingSize
        ).isActive = true
        webview.leadingAnchor.constraint(
            equalTo: self.view.safeAreaLayoutGuide.leadingAnchor,
            constant: paddingSize
        ).isActive = true
        webview.trailingAnchor.constraint(
            equalTo: self.view.safeAreaLayoutGuide.trailingAnchor,
            constant: paddingSize * -1
        ).isActive = true
        webview.bottomAnchor.constraint(
            equalTo: self.view.safeAreaLayoutGuide.bottomAnchor,
            constant: paddingSize * -1
        ).isActive = true

        webview.load(URLRequest(url: url))

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "︙", style: .done, target: self,
            action: #selector(pushThreeDotLeaders))
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping () -> Void
    ) {
        let alertController = UIAlertController(
            title: nil, message: message,
            preferredStyle: UIAlertController.Style.alert)
        let alertAction = UIAlertAction(
            title: "OK", style: UIAlertAction.Style.default
        ) { (action: UIAlertAction) -> Void in
            alertController.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(alertAction)
        present(alertController, animated: true)
        completionHandler()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let script = script {
            webview.evaluateJavaScript(script) { (_, error) in
                if let error = error {
                    print("evaluateJavaScript failed: \(error)")
                }
            }
        }
    }

    @objc func pushThreeDotLeaders(sender: UIButton) {
        let optionsMenuViewController = OptionsMenuViewController()
        optionsMenuViewController.modalPresentationStyle = .overCurrentContext
        optionsMenuViewController.closeHandler = { viewController in
            viewController.dismiss(animated: false, completion: nil)
        }
        self.present(
            optionsMenuViewController, animated: false, completion: nil)
    }
}
