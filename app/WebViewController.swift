//
//  WebViewController.swift
//  libjeid-ios-app
//
//  Copyright © 2019 Open Source Solution Technology Corporation
//  All rights reserved.
//

import UIKit
@preconcurrency import WebKit

class WebViewController: UIViewController, WKNavigationDelegate {

    private let webview = WKWebView(
        frame: .zero, configuration: WKWebViewConfiguration())
    private let url: URL
    private let renderData: [String: Any]

    init(_ url: URL, renderData: [String: Any]) {
        self.url = url
        self.renderData = renderData
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        let screenSize = CustomViewUtil.screenSize
        let paddingSize = CGFloat(min(screenSize.width, screenSize.height) / 50)

        view.backgroundColor = UIColor.white
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

        // WebAssetsルート(.../WebAssets)に読み取り許可を与え、
        // indl/indl.html の ../dl/normalize.css のようなクロスディレクトリ参照を可能にする
        let readAccessUrl = url.deletingLastPathComponent()
            .deletingLastPathComponent()
        webview.loadFileURL(url, allowingReadAccessTo: readAccessUrl)

        installOptionsMenuButton()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard !renderData.isEmpty else {
            return
        }
        let json: String
        do {
            let data = try JSONSerialization.data(
                withJSONObject: renderData, options: [])
            json = String(decoding: data, as: UTF8.self)
        } catch {
            print("JSON serialize failed: \(error)")
            return
        }
        webview.callAsyncJavaScript(
            "render(json);",
            arguments: ["json": json],
            in: nil,
            in: .page
        ) { result in
            if case .failure(let error) = result {
                print("callAsyncJavaScript failed: \(error)")
            }
        }
    }
}
