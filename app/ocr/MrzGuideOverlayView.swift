//
//  MrzGuideOverlayView.swift
//  libjeid-ios-app
//
//  Copyright © 2026 Open Source Solution Technology Corporation
//  All rights reserved.
//

import UIKit

/// MRZを合わせる位置を示すガイド枠を描画するオーバーレイ。
///
/// 枠は `MrzScanViewController` が解析対象とする領域(ROI)より内側に取り、
/// 利用者が枠に合わせればROIに確実に収まるようにしている。
class MrzGuideOverlayView: UIView {
    /// ガイド枠の幅(ビュー幅に対する比率)。
    static let guideWidthRatio = CGFloat(0.90)
    /// ガイド枠の高さ(ビュー高さに対する比率)。
    static let guideHeightRatio = CGFloat(0.16)
    private static let cornerRadius = CGFloat(4)
    private static let borderWidth = CGFloat(2)

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        super.init(frame: .zero)
        self.backgroundColor = .clear
        self.isOpaque = false
        self.isUserInteractionEnabled = false
    }

    /// ガイド枠の矩形を返します。
    var guideRect: CGRect {
        let guideWidth = bounds.width * Self.guideWidthRatio
        let guideHeight = bounds.height * Self.guideHeightRatio
        return CGRect(
            x: (bounds.width - guideWidth) / 2,
            y: (bounds.height - guideHeight) / 2,
            width: guideWidth, height: guideHeight)
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        let guide = guideRect
        // ガイド枠の外側を暗くする
        context.setFillColor(UIColor(white: 0, alpha: 0.55).cgColor)
        context.fill(
            CGRect(x: 0, y: 0, width: bounds.width, height: guide.minY))
        context.fill(
            CGRect(
                x: 0, y: guide.maxY, width: bounds.width,
                height: bounds.height - guide.maxY))
        context.fill(
            CGRect(
                x: 0, y: guide.minY, width: guide.minX, height: guide.height))
        context.fill(
            CGRect(
                x: guide.maxX, y: guide.minY,
                width: bounds.width - guide.maxX, height: guide.height))

        let border = UIBezierPath(
            roundedRect: guide, cornerRadius: Self.cornerRadius)
        border.lineWidth = Self.borderWidth
        UIColor.white.setStroke()
        border.stroke()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // 回転やレイアウト確定で寸法が変わったら枠を描き直す
        setNeedsDisplay()
    }
}
