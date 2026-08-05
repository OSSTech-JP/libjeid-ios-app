//
//  TestMode.swift
//  libjeid-ios-app
//
//  Copyright © 2026 Open Source Solution Technology Corporation
//  All rights reserved.
//

import Foundation

/// 開発者向けの隠し機能(テストモード)の有効・無効を保持します。
/// <br>
/// オプションメニューの「このアプリについて」で libjeid アイコンを長押しすると
/// 切り替わります(`OptionsMenuViewController.pushIcon`)。
/// テストモードのときだけメニューに表示する項目は
/// `MainViewController.applyTestMode()` で制御します。
/// (Android 版 `TestMode` と同じ役割)
enum TestMode {
    private static let key = "testMode"

    /// テストモードが有効かどうか
    static var isEnabled: Bool {
        return UserDefaults.standard.bool(forKey: key)
    }

    /// テストモードの有効・無効を切り替えます
    /// - Returns: 切り替え後の状態
    @discardableResult
    static func toggle() -> Bool {
        let enabled = !isEnabled
        UserDefaults.standard.set(enabled, forKey: key)
        return enabled
    }
}
