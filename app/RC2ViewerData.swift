//
//  RC2ViewerData.swift
//  libjeid-ios-app
//
//  Copyright © 2026 Open Source Solution Technology Corporation
//  All rights reserved.
//

import Foundation
import libjeid

/// 第2世代在留カード等・特定在留カード等のビューア(`WebAssets/rc2`)へ渡す
/// レンダリングデータを組み立てます。
/// <br>
/// 両者はデータ構造が共通(`RC2Files`)なのでビューアもキーも共用します
/// (Android 版 `RC2ReaderTask` / `RCSReaderTask` が使う `rc2-*` と同じキー)。
/// カード種別だけが異なります:
/// "05"=第2世代在留カード / "06"=第2世代特別永住者証明書 /
/// "07"=特定在留カード / "08"=特定特別永住者証明書
enum RC2ViewerData {

    /// - Parameter files: 読み出したファイル
    /// - Parameter cardType: カード種別
    /// - Parameter logger: 進捗ログの出力先(省略可)
    /// - Returns: ビューアへ渡す辞書
    static func build(_ files: RC2Files,
                     _ cardType: RC2CardType,
                     _ logger: ((String) -> Void)? = nil) throws -> [String: Any] {
        var dict = [String: Any]()
        let typeCode = cardType.type
        if let typeCode = typeCode {
            dict["rc2-card-type"] = typeCode
        }
        // 資格外活動許可欄・在留期間更新等許可申請ステータスは在留カードのみ
        let isResidence = (typeCode == "05" || typeCode == "07")

        let cardNumber = try files.getCardNumber()
        logger?("## 在留カード等の番号")
        logger?(cardNumber.description)
        dict["rc2-card-number"] = cardNumber.number

        let entries = try files.getCardEntries()
        logger?("## 券面記載事項")
        logger?(entries.description)
        dict["rc2-card-expire-date"] = entries.cardExpireDate
        dict["rc2-birth-date"] = entries.birthDate
        dict["rc2-sex"] = entries.sex
        dict["rc2-sex-name"] = entries.sexName
        // 券面表示(コード表 / 仕様書本文のコード定義)も渡す。
        // ビューアは「名前 (コード)」で表示し、定義に無いコードでは名前がnilになるので
        // 生のコードだけを表示する
        dict["rc2-nationality"] = entries.nationality
        dict["rc2-nationality-name"] = entries.nationalityName
        dict["rc2-status"] = entries.residenceStatus
        dict["rc2-status-name"] = entries.residenceStatusName
        dict["rc2-stay-period"] = entries.stayPeriod
        dict["rc2-stay-period-name"] = entries.stayPeriodName
        dict["rc2-permission-type"] = entries.permissionType
        dict["rc2-permission-type-name"] = entries.permissionTypeName
        dict["rc2-permission-date"] = entries.permissionDate
        dict["rc2-work-restriction"] = entries.workRestriction
        dict["rc2-work-restriction-name"] = entries.workRestrictionName
        dict["rc2-stay-period-expire-date"] = entries.stayPeriodExpireDate

        logger?("## 氏名イメージ・顔画像・住居地イメージ")
        // libjeid が返す汎用画像(CGImage)をアプリ側で PNG / JPEG に変換して渡す。
        // 顔画像を JPEG2000 のまま渡すことはできない。iOS 18 で WebKit が
        // JPEG2000 のサポートを削除したため、data:image/jp2 は WKWebView で
        // 表示できない(Android 版 RC2ReaderTask と同じ扱い)
        let nameImage = try files.getNameImage()
        if let image = nameImage.image, let src = try image.pngDataUri() {
            dict["rc2-name-image"] = src
        }
        // 1歳未満の中長期在留者・特別永住者では顔画像が格納されない
        let faceImage = try files.getFaceImage()
        if let image = faceImage.image, let src = try image.jpegDataUri() {
            dict["rc2-face-image"] = src
        }
        let addressImage = try files.getAddressImage()
        if let image = addressImage.image, let src = try image.pngDataUri() {
            dict["rc2-address-image"] = src
        }

        if isResidence {
            if let permission = try files.getPermission() {
                logger?("## 資格外活動許可欄")
                logger?(permission.description)
                dict["rc2-comprehensive"] = permission.comprehensive
                dict["rc2-comprehensive-name"] = permission.comprehensiveName
                dict["rc2-comprehensive-limit"] = permission.comprehensiveLimit
                dict["rc2-individual"] = permission.individual
                dict["rc2-individual-name"] = permission.individualName
            }
            if let updateStatus = try files.getUpdateStatus() {
                logger?("## 在留期間更新等許可申請ステータス")
                logger?(updateStatus.description)
                dict["rc2-update-status"] = updateStatus.status
                dict["rc2-update-status-name"] = updateStatus.statusName
            }
        }

        let others = try files.getOthers()
        logger?("## その他")
        logger?(others.description)
        dict["rc2-commissioner-entry"] = others.commissionerEntry
        dict["rc2-commissioner-entry-name"] = others.commissionerEntryName
        dict["rc2-reserved"] = others.reserved

        let signature = try files.getSignature()
        logger?("## 電子署名")
        logger?(signature.description)

        // 真正性検証
        do {
            let result = try files.validate()
            dict["rc2-valid"] = result.isValid
            dict["rc2-validation-result"] = result.description
            logger?("真正性検証結果: \(result)\n")
        } catch JeidError.unsupportedOperation {
            // 無償版の場合、RC2Files#validate()でJeidError.unsupportedOperationが返ります
            logger?("無償版ライブラリは真正性検証をサポートしません\n")
        } catch {
            logger?("\(error)")
        }
        return dict
    }
}
