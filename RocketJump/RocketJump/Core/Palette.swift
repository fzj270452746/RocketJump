//
//  Palette.swift
//  RocketJump
//
//  Color tokens. Each planet biome recolors the world; the chrome stays cool.
//

import UIKit

enum Palette {

    // Chrome
    static let voidTop = rgb(8, 10, 26)
    static let voidLow = rgb(20, 12, 40)
    static let ink = rgb(232, 238, 255)
    static let inkSoft = rgb(150, 162, 196)
    static let glass = UIColor.white.withAlphaComponent(0.06)
    static let hairline = UIColor.white.withAlphaComponent(0.12)

    // Accents
    static let thrust = rgb(255, 138, 76)
    static let fuel = rgb(86, 230, 168)
    static let coin = rgb(255, 206, 84)
    static let energy = rgb(120, 196, 255)
    static let shield = rgb(122, 244, 232)
    static let magnet = rgb(255, 122, 184)
    static let doubler = rgb(196, 150, 255)
    static let peril = rgb(255, 86, 110)

    static func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> UIColor {
        UIColor(red: r / 255, green: g / 255, blue: b / 255, alpha: a)
    }

    /// Two-stop vertical gradient layer sized to a rect.
    static func sky(_ top: UIColor, _ bottom: UIColor, _ rect: CGRect) -> CAGradientLayer {
        let g = CAGradientLayer()
        g.colors = [top.cgColor, bottom.cgColor]
        g.frame = rect
        return g
    }
}
