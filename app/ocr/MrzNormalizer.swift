//
//  MrzNormalizer.swift
//  libjeid-ios-app
//
//  Copyright © 2026 Open Source Solution Technology Corporation
//  All rights reserved.
//

import Foundation

/// OCRが返した行をMRZの文字集合(`A-Z`、`0-9`、`<`)へ正規化します。
///
/// 汎用OCRはMRZのフィラー(`<`)を `«` や `≪` として返すことがあり、
/// また文字間に空白を挿入することがあるため、比較・パースの前に必ずこの正規化を通す。
enum MrzNormalizer {
    /// 1行を正規化します。MRZに現れ得ない文字は削除します。
    ///
    /// - Parameter line: OCRが返した行
    /// - Returns: 正規化後の文字列
    static func normalize(_ line: String?) -> String {
        guard let line = line else {
            return ""
        }
        var normalized = ""
        normalized.reserveCapacity(line.count)
        for c in line.uppercased() {
            if c.isASCII
                && (("A"..."Z").contains(c) || ("0"..."9").contains(c)
                    || c == "<")
            {
                normalized.append(c)
                continue
            }
            switch c {
            // 全角/半角のギュメ、山括弧に類する誤認識をフィラーへ寄せる
            case "«", "‹", "ⱼ", "(", "{", "[", "^", "＜":
                normalized.append("<")
            case "≪", "《":
                normalized.append("<<")
            default:
                // 空白・記号・かな漢字などは削除する
                break
            }
        }
        return normalized
    }
}
