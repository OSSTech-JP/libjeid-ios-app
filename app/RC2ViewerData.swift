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
        dict["rc2-valid-until"] = entries.cardValidUntil
        dict["rc2-birth-date"] = entries.birthDate
        dict["rc2-sex"] = entries.sex
        // コード表(RC2Code)による券面表示も渡す。ビューアは「名前 (コード)」で表示し、
        // コード表に無いコードでは名前がnilになるので生のコードだけを表示する
        dict["rc2-nationality"] = entries.nationality
        dict["rc2-nationality-name"] = entries.nationalityName
        dict["rc2-status"] = entries.residenceStatus
        dict["rc2-status-name"] = entries.residenceStatusName
        dict["rc2-period"] = entries.stayPeriod
        dict["rc2-permit-category"] = entries.permissionType
        dict["rc2-permit-category-name"] = entries.permissionTypeName
        dict["rc2-permit-date"] = entries.permissionDate
        dict["rc2-work-restriction"] = entries.workRestriction
        dict["rc2-period-until"] = entries.stayPeriodUntil

        logger?("## 氏名イメージ・顔画像・住居地イメージ")
        let nameImage = try files.getNameImage()
        if nameImage.imageData != nil {
            let png = try nameImage.pngData()
            dict["rc2-name-image"] = "data:image/png;base64,\(png.base64EncodedString())"
        }
        // 1歳未満の中長期在留者・特別永住者では顔画像が格納されない。
        // JPEG2000 は WebKit がそのまま表示できるので変換しない(第1世代と同じ扱い)
        let faceImage = try files.getFaceImage()
        if let jp2 = faceImage.imageData {
            dict["rc2-face-image"] = "data:image/jp2;base64,\(jp2.base64EncodedString())"
        }
        let addressImage = try files.getAddressImage()
        if addressImage.imageData != nil {
            let png = try addressImage.pngData()
            dict["rc2-address-image"] = "data:image/png;base64,\(png.base64EncodedString())"
        }

        if isResidence {
            if let permission = try files.getPermission() {
                logger?("## 資格外活動許可欄")
                logger?(permission.description)
                dict["rc2-comprehensive"] = permission.comprehensive
                dict["rc2-comprehensive-limit"] = permission.comprehensiveLimit
                dict["rc2-individual"] = permission.individual
            }
            if let updateStatus = try files.getUpdateStatus() {
                logger?("## 在留期間更新等許可申請ステータス")
                logger?(updateStatus.description)
                dict["rc2-update-status"] = updateStatus.status
            }
        }

        let others = try files.getOthers()
        logger?("## その他")
        logger?(others.description)
        dict["rc2-commissioner-entry"] = others.hasCommissionerEntry
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
