//
//  CGImage+Encode.swift
//  libjeid-ios-app
//
//  Copyright © 2019 Open Source Solution Technology Corporation
//  All rights reserved.
//

import ImageIO
import UniformTypeIdentifiers

// libjeid が返す汎用画像(CGImage)を、ビューア(WKWebView)へ渡すための
// JPEG / PNG データURIに変換します。
// libjeid はデコードした CGImage までを提供し、エンコードはアプリ側で行います
// (Android 版 RC2ReaderTask#toJpegDataUri / #toPngDataUri と同じ役割)。
extension CGImage {
    func encodeJpeg(quality: Double = 0.9) throws -> Data? {
        let jpegData = NSMutableData()
        guard
            let destination = CGImageDestinationCreateWithData(
                jpegData, UTType.jpeg.identifier as CFString, 1, nil)
        else {
            return nil
        }
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]
        CGImageDestinationAddImage(destination, self, options as CFDictionary)

        if CGImageDestinationFinalize(destination) {
            return jpegData as Data
        } else {
            return nil
        }
    }

    func encodePng() throws -> Data? {
        let pngData = NSMutableData()
        guard
            let destination = CGImageDestinationCreateWithData(
                pngData, UTType.png.identifier as CFString, 1, nil)
        else {
            return nil
        }
        CGImageDestinationAddImage(destination, self, nil)

        if CGImageDestinationFinalize(destination) {
            return pngData as Data
        } else {
            return nil
        }
    }

    /// 顔写真などの多階調画像用。JPEGのデータURIを返します
    func jpegDataUri(quality: Double = 0.9) throws -> String? {
        guard let jpeg = try encodeJpeg(quality: quality) else {
            return nil
        }
        return "data:image/jpeg;base64,\(jpeg.base64EncodedString())"
    }

    /// 氏名イメージなどの2値画像用。PNGのデータURIを返します
    func pngDataUri() throws -> String? {
        guard let png = try encodePng() else {
            return nil
        }
        return "data:image/png;base64,\(png.base64EncodedString())"
    }
}
