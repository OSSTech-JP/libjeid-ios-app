//
//  MrzTd3Parser.swift
//  libjeid-ios-app
//
//  Copyright © 2026 Open Source Solution Technology Corporation
//  All rights reserved.
//

import Foundation

/// ICAO 9303 Part 4 の TD3(パスポート)MRZ を、汎用OCRの誤認識を補正しながらパースします。
///
/// 設計上のポイント:
/// - **2行目だけで成立させる**。BAC/PACEの鍵導出に必要なパスポート番号・生年月日・
///   有効期限はすべて2行目にあるため、1行目が読めなくても成功とする。
/// - **字種別の補正を積極的に行う**。数値フィールドの `O→0` のような誤認識を
///   補正した上でチェックデジットを検証し、通ったものだけを採用する。
///   1文字の誤りは必ずチェックデジット不一致になるため、補正を強くかけても
///   誤った値を採用してしまうことはない。
///
/// UIKit/Visionに依存しない純粋なロジックのみで構成し、Android版と同じ実装とする。
enum MrzTd3Parser {
    /// TD3の1行の文字数。
    static let lineLength = 44

    // MRZ2行目のフィールド位置(0起点)
    private static let docNumberBegin = 0
    private static let docNumberEnd = 9
    private static let docNumberCd = 9
    private static let nationalityBegin = 10
    private static let nationalityEnd = 13
    private static let birthDateBegin = 13
    private static let birthDateEnd = 19
    private static let birthDateCd = 19
    private static let sexIndex = 20
    private static let expirationBegin = 21
    private static let expirationEnd = 27
    private static let expirationCd = 27
    private static let optionalBegin = 28
    private static let optionalEnd = 42
    private static let optionalCd = 42
    private static let compositeCd = 43

    // 1行目のフィールド位置(0起点)
    private static let nameBegin = 5

    /// チェックデジットの重み。
    private static let weights = [7, 3, 1]

    /// 誤認識行が長大な場合の探索打ち切り長。
    private static let maxSearchLength = 256

    /// OCRが返した行群からMRZを探し、チェックデジット検証を通ったものを返します。
    ///
    /// - Parameter rawLines: OCRが返した行(正規化前でよい)
    /// - Returns: 検証を通った結果。見つからない場合は `nil`
    static func parse(_ rawLines: [String]) -> MrzScanResult? {
        var normalized: [[Character]] = []
        for raw in rawLines {
            let line = MrzNormalizer.normalize(raw)
            if line.count >= lineLength && line.count <= maxSearchLength {
                normalized.append(Array(line))
            }
        }
        // 2行目を探す。OCRが2行を1行に連結して返すことや、余分な文字を
        // 挿入することがあるため、長さ44の窓をずらしながら総当たりする。
        var result: MrzScanResult? = nil
        search: for line in normalized {
            for offset in 0...(line.count - lineLength) {
                if let parsed = parseLine2(
                    Array(line[offset..<(offset + lineLength)]))
                {
                    result = parsed
                    break search
                }
            }
        }
        guard let found = result else {
            return nil
        }
        if let names = findNames(normalized) {
            return found.withName(
                surname: names.surname, givenName: names.givenName)
        }
        return found
    }

    /// MRZ2行目1本をパースします。
    ///
    /// - Parameter rawLine: MRZ2行目(正規化前でよい)
    /// - Returns: 検証を通った結果。検証に失敗した場合は `nil`
    static func parseLine2(_ rawLine: String) -> MrzScanResult? {
        let line = MrzNormalizer.normalize(rawLine)
        guard line.count == lineLength else {
            return nil
        }
        return parseLine2(Array(line))
    }

    /// 正規化済みの44文字をパースします。
    ///
    /// - Parameter line: 正規化済みのMRZ2行目(44文字)
    /// - Returns: 検証を通った結果。検証に失敗した場合は `nil`
    private static func parseLine2(_ line: [Character]) -> MrzScanResult? {
        guard line.count == lineLength else {
            return nil
        }
        var chars = line
        // 字種が確定しているフィールドを補正する
        coerceToDigit(&chars, birthDateBegin, birthDateEnd)
        coerceToDigit(&chars, birthDateCd, birthDateCd + 1)
        coerceToDigit(&chars, expirationBegin, expirationEnd)
        coerceToDigit(&chars, expirationCd, expirationCd + 1)
        coerceToDigit(&chars, docNumberCd, docNumberCd + 1)
        coerceToDigit(&chars, optionalCd, optionalCd + 1)
        coerceToDigit(&chars, compositeCd, compositeCd + 1)
        coerceToAlpha(&chars, nationalityBegin, nationalityEnd)
        coerceSex(&chars, sexIndex)

        let birthDate = Array(chars[birthDateBegin..<birthDateEnd])
        guard isValidDate(birthDate),
            calculateCheckDigit(birthDate) == toDigit(chars[birthDateCd])
        else {
            return nil
        }
        let expirationDate = Array(chars[expirationBegin..<expirationEnd])
        guard isValidDate(expirationDate),
            calculateCheckDigit(expirationDate) == toDigit(chars[expirationCd])
        else {
            return nil
        }

        // パスポート番号は英字と数字の双方を取り得るため字種を確定できない。
        // 候補を順に試し、チェックデジットが一致したものを採用する。
        let rawDocNumber = Array(chars[docNumberBegin..<docNumberEnd])
        var docNumber: [Character]? = nil
        for candidate in documentNumberCandidates(rawDocNumber) {
            if calculateCheckDigit(candidate) == toDigit(chars[docNumberCd]) {
                docNumber = candidate
                break
            }
        }
        guard let documentNumber = docNumber else {
            return nil
        }
        chars.replaceSubrange(docNumberBegin..<docNumberEnd, with: documentNumber)

        let compositeValid =
            calculateCheckDigit(compositeSource(chars))
            == toDigit(chars[compositeCd])
        return MrzScanResult(
            line2: String(chars),
            documentNumber: unpad(documentNumber),
            nationality: String(chars[nationalityBegin..<nationalityEnd]),
            birthDate: String(birthDate),
            expirationDate: String(expirationDate),
            sex: chars[sexIndex],
            isCompositeCheckDigitValid: compositeValid,
            surname: "",
            givenName: "")
    }

    /// MRZのチェックデジットを計算します。
    ///
    /// - Parameter value: 対象文字列(正規化済みであること)
    /// - Returns: チェックデジット(0-9)
    static func calculateCheckDigit(_ value: [Character]) -> Int {
        var sum = 0
        for (i, c) in value.enumerated() {
            sum += weightOf(c) * weights[i % 3]
        }
        return sum % 10
    }

    /// 複合チェックデジットの計算対象を返します。
    /// 対象は1行目からではなく2行目の 0-9、13-19、21-42 の各文字。
    ///
    /// - Parameter line2: MRZ2行目(44文字)
    /// - Returns: 複合チェックデジットの計算対象文字列
    static func compositeSource(_ line2: [Character]) -> [Character] {
        return Array(line2[docNumberBegin...docNumberCd])
            + Array(line2[birthDateBegin...birthDateCd])
            + Array(line2[expirationBegin...optionalCd])
    }

    /// 正規化により文字集合は `A-Z`、`0-9`、`<` に限られるため、
    /// それ以外はフィラーと同じ重み0として扱う。
    private static func weightOf(_ c: Character) -> Int {
        if let ascii = c.asciiValue {
            if ascii >= 48 && ascii <= 57 {  // 0-9
                return Int(ascii - 48)
            }
            if ascii >= 65 && ascii <= 90 {  // A-Z
                return Int(ascii - 65) + 10
            }
        }
        return 0
    }

    private static func toDigit(_ c: Character) -> Int {
        guard let ascii = c.asciiValue, ascii >= 48, ascii <= 57 else {
            return -1
        }
        return Int(ascii - 48)
    }

    /// パスポート番号フィールドの補正候補を、可能性の高い順に返します。
    private static func documentNumberCandidates(_ field: [Character])
        -> [[Character]]
    {
        var candidates: [[Character]] = []
        func append(_ candidate: [Character]) {
            if !candidates.contains(candidate) {
                candidates.append(candidate)
            }
        }
        append(field)
        // 日本のパスポート番号は英字2桁+数字7桁
        var jp = field
        coerceToAlpha(&jp, 0, min(2, jp.count))
        coerceToDigit(&jp, min(2, jp.count), jp.count)
        append(jp)
        var digits = field
        coerceToDigit(&digits, 0, digits.count)
        append(digits)
        var alphas = field
        coerceToAlpha(&alphas, 0, alphas.count)
        append(alphas)
        return candidates
    }

    /// 数字であるべき範囲を数字へ寄せます。フィラーはそのまま残します。
    private static func coerceToDigit(
        _ chars: inout [Character], _ begin: Int, _ end: Int
    ) {
        for i in begin..<end {
            switch chars[i] {
            case "O", "Q", "D":
                chars[i] = "0"
            case "I", "L":
                chars[i] = "1"
            case "Z":
                chars[i] = "2"
            case "A":
                chars[i] = "4"
            case "S":
                chars[i] = "5"
            case "G":
                chars[i] = "6"
            case "T":
                chars[i] = "7"
            case "B":
                chars[i] = "8"
            default:
                break
            }
        }
    }

    /// 英字であるべき範囲を英字へ寄せます。フィラーはそのまま残します。
    private static func coerceToAlpha(
        _ chars: inout [Character], _ begin: Int, _ end: Int
    ) {
        for i in begin..<end {
            switch chars[i] {
            case "0":
                chars[i] = "O"
            case "1":
                chars[i] = "I"
            case "2":
                chars[i] = "Z"
            case "4":
                chars[i] = "A"
            case "5":
                chars[i] = "S"
            case "6":
                chars[i] = "G"
            case "7":
                chars[i] = "T"
            case "8":
                chars[i] = "B"
            default:
                break
            }
        }
    }

    /// 性別を `M`、`F`、`X`、`<` のいずれかへ寄せます。
    /// このフィールドは複合チェックデジットの対象外のため、判別できない場合は
    /// フィラーとして扱っても他の検証に影響しない。
    private static func coerceSex(_ chars: inout [Character], _ index: Int) {
        switch chars[index] {
        case "M", "F", "X":
            break
        case "H", "N":
            chars[index] = "M"
        case "E", "P":
            chars[index] = "F"
        default:
            chars[index] = "<"
        }
    }

    private static func isValidDate(_ yymmdd: [Character]) -> Bool {
        for c in yymmdd {
            if toDigit(c) < 0 {
                return false
            }
        }
        let month = toDigit(yymmdd[2]) * 10 + toDigit(yymmdd[3])
        let day = toDigit(yymmdd[4]) * 10 + toDigit(yymmdd[5])
        return month >= 1 && month <= 12 && day >= 1 && day <= 31
    }

    private static func unpad(_ value: [Character]) -> String {
        var end = value.count
        while end > 0 && value[end - 1] == "<" {
            end -= 1
        }
        return String(value[0..<end])
    }

    /// 1行目を探し、姓と名を返します。
    ///
    /// - Returns: 姓と名。1行目が見つからない場合は `nil`
    private static func findNames(_ normalizedLines: [[Character]])
        -> (surname: String, givenName: String)?
    {
        for line in normalizedLines {
            for offset in 0...(line.count - lineLength) {
                let candidate = Array(line[offset..<(offset + lineLength)])
                if candidate[0] != "P" || !isAlphaOrFiller(candidate) {
                    continue
                }
                return extractNames(Array(candidate[nameBegin...]))
            }
        }
        return nil
    }

    private static func isAlphaOrFiller(_ value: [Character]) -> Bool {
        for c in value {
            if c != "<" && !(c.isASCII && ("A"..."Z").contains(c)) {
                return false
            }
        }
        return true
    }

    /// 氏名フィールドを姓と名へ分解します。区切りが見つからない場合は空文字列を返します。
    private static func extractNames(_ nameField: [Character])
        -> (surname: String, givenName: String)
    {
        let name = Array(unpad(nameField))
        guard let separator = indexOfDoubleFiller(name), separator > 0 else {
            return ("", "")
        }
        let surname = String(name[0..<separator])
        let givenName = String(name[(separator + 2)...])
        if surname.contains("<") || givenName.contains("<<") {
            return ("", "")
        }
        return (
            surname,
            givenName.replacingOccurrences(of: "<", with: " ")
                .trimmingCharacters(in: .whitespaces)
        )
    }

    private static func indexOfDoubleFiller(_ value: [Character]) -> Int? {
        guard value.count >= 2 else {
            return nil
        }
        for i in 0..<(value.count - 1) {
            if value[i] == "<" && value[i + 1] == "<" {
                return i
            }
        }
        return nil
    }
}
