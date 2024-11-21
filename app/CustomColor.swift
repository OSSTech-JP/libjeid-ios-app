//
//  CustomColor.swift
//  libjeid-ios-app
//
//  Copyright © 2019-2020 Open Source Solution Technology Corporation
//  All rights reserved.
//

import UIKit

class CustomColor {

    static var text: UIColor {
        return dynamicColor(
            light: createUIColor(hex: 0x1C1C1E, alpha: 1.0),
            dark: createUIColor(hex: 0xF2F2F7, alpha: 1.0))
    }

    static var background: UIColor {
        return dynamicColor(
            light: createUIColor(hex: 0xFFFFFF, alpha: 1.0),
            dark: createUIColor(hex: 0x1C1C1E, alpha: 1.0))
    }

    static var buttonTitle: UIColor {
        return dynamicColor(
            light: createUIColor(hex: 0x1C1C1E, alpha: 1.0),
            dark: createUIColor(hex: 0xEBEBF5, alpha: 1.0))
    }

    static var buttonBackground: UIColor {
        return dynamicColor(
            light: createUIColor(hex: 0xD1D1D6, alpha: 1.0),
            dark: createUIColor(hex: 0x3A3A3C, alpha: 1.0))
    }

    static var buttonHighlightedBackground: UIColor {
        return dynamicColor(
            light: createUIColor(hex: 0x8E8E93, alpha: 1.0),
            dark: createUIColor(hex: 0x636366, alpha: 1.0))
    }

    static var textFieldText: UIColor {
        return text
    }

    static var textFieldBackground: UIColor {
        return dynamicColor(
            light: createUIColor(hex: 0xFFFFFF, alpha: 1.0),
            dark: createUIColor(hex: 0x2C2C2E, alpha: 1.0))
    }

    static var textFieldBorder: UIColor {
        return dynamicColor(
            light: createUIColor(hex: 0x636366, alpha: 1.0),
            dark: createUIColor(hex: 0x8E8E93, alpha: 1.0))
    }

    static var optionsMenuBackground: UIColor {
        return dynamicColor(
            light: createUIColor(hex: 0xFFFFFF, alpha: 1.0),
            dark: createUIColor(hex: 0x323234, alpha: 1.0))
    }

    static var optionsMenuShadow: UIColor {
        return dynamicColor(
            light: createUIColor(hex: 0x000000, alpha: 1.0),
            dark: createUIColor(hex: 0xFFFFFF, alpha: 0.0))
    }

    static var optionsMenuItemTitle: UIColor {
        return text
    }

    static var optionsMenuItemBackground: UIColor {
        return optionsMenuBackground
    }

    static var menuItemHighlightedBackground: UIColor {
        return dynamicColor(
            light: createUIColor(hex: 0xEBEBEE, alpha: 1.0),
            dark: createUIColor(hex: 0x48484A, alpha: 1.0))
    }

    private class func dynamicColor(light: UIColor, dark: UIColor) -> UIColor {
        return UIColor { (traitCollection) -> UIColor in
            switch traitCollection.userInterfaceStyle {
            case .unspecified, .light:
                return light
            case .dark:
                return dark
            @unknown default:
                return light
            }
        }
    }

    private class func createUIColor(hex: UInt, alpha: CGFloat) -> UIColor {
        let red = CGFloat((hex >> 16) & 0xff) / 0xff
        let green = CGFloat((hex >> 8) & 0xff) / 0xff
        let blue = CGFloat(hex & 0xff) / 0xff
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}
