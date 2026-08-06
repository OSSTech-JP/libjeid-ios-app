//
//  MrzScanResult.swift
//  libjeid-ios-app
//
//  Copyright © 2026 Open Source Solution Technology Corporation
//  All rights reserved.
//

import Foundation

/// MRZ(TD3)から読み取った情報。
///
/// BAC/PACEの鍵導出に必要なのはパスポート番号・生年月日・有効期限の3つで、
/// これらはすべてMRZ2行目に含まれ、チェックデジットで検証済みである。
/// 氏名は1行目が読めた場合のみ設定される任意情報。
///
/// 日付はMRZと同じYYMMDDの6桁で保持する。鍵導出に使うのは2桁年であり、
/// 4桁へ広げると世紀を推測する必要が生じて表示を誤り得るため、変換しない。
struct MrzScanResult: CustomStringConvertible {
    /// 検証を通過したMRZ2行目(44文字、誤認識補正後)。
    let line2: String
    /// パスポート番号。フィラー(`<`)は除去済み。
    let documentNumber: String
    /// 国籍コード。
    let nationality: String
    /// 生年月日(YYMMDDの6桁)。
    let birthDate: String
    /// 有効期限(YYMMDDの6桁)。
    let expirationDate: String
    /// 性別(`M`、`F`、`X`、`<`)。
    let sex: Character
    /// 複合チェックデジットが一致したかどうか。
    ///
    /// 任意データの誤認識で不一致になることがあるため、この値が `false` でも
    /// 鍵導出に必要な3フィールドの妥当性には影響しない。ログ出力用の参考情報。
    let isCompositeCheckDigitValid: Bool
    /// 姓。1行目が読めなかった場合は空文字列。
    let surname: String
    /// 名。1行目が読めなかった場合は空文字列。
    let givenName: String

    /// 氏名を追加した新しいインスタンスを返します。
    ///
    /// - Parameters:
    ///   - surname: 姓
    ///   - givenName: 名
    /// - Returns: 氏名を設定した新しいインスタンス
    func withName(surname: String, givenName: String) -> MrzScanResult {
        return MrzScanResult(
            line2: line2, documentNumber: documentNumber,
            nationality: nationality, birthDate: birthDate,
            expirationDate: expirationDate, sex: sex,
            isCompositeCheckDigitValid: isCompositeCheckDigitValid,
            surname: surname, givenName: givenName)
    }

    /// 鍵導出に使う3フィールドが一致するかどうかを返します。
    /// 複数フレームの一致判定に使用する。
    ///
    /// - Parameter other: 比較対象
    /// - Returns: パスポート番号・生年月日・有効期限がすべて一致する場合 `true`
    func hasSameKeyFields(_ other: MrzScanResult) -> Bool {
        return documentNumber == other.documentNumber
            && birthDate == other.birthDate
            && expirationDate == other.expirationDate
    }

    var description: String {
        return "MrzScanResult[documentNumber=\(documentNumber)"
            + ", birthDate=\(birthDate)"
            + ", expirationDate=\(expirationDate)"
            + ", nationality=\(nationality)"
            + ", sex=\(sex)"
            + ", compositeCheckDigitValid=\(isCompositeCheckDigitValid)"
            + ", surname=\(surname)"
            + ", givenName=\(givenName)]"
    }
}
