//
//  CGImage+EncodeJpeg.swift
//  libjeid-ios-app
//
//  Copyright © 2019 Open Source Solution Technology Corporation
//  All rights reserved.
//

import ImageIO
import UniformTypeIdentifiers

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
}
