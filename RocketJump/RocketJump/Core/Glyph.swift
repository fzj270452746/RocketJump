//
//  Glyph.swift
//  RocketJump
//
//  SF Symbol resolver. Centralises the symbol names from the design doc and
//  guards against the handful that did not exist before iOS 15/16, so the
//  game still draws something sensible on iOS 14.
//

import UIKit

enum Glyph {

    // Names lifted straight from the design brief.
    static let rocket = "rocket.fill"
    static let fuel = "fuelpump.fill"
    static let coin = "circle.fill"
    static let energy = "bolt.fill"
    static let shield = "shield.fill"
    static let magnet = "magnet"
    static let doubler = "star.fill"
    static let chest = "gift.fill"
    static let meteor = "circle.hexagongrid.fill"
    static let blackhole = "circle.dashed.inset.filled"
    static let planet = "globe.americas.fill"

    /// Resolve a symbol with a fallback for older systems.
    static func image(_ name: String, weight: UIImage.SymbolWeight = .regular,
                      scale: UIImage.SymbolScale = .medium) -> UIImage? {
        let cfg = UIImage.SymbolConfiguration(pointSize: 0, weight: weight, scale: scale)
        if let img = UIImage(systemName: name, withConfiguration: cfg) {
            return img
        }
        return UIImage(systemName: substitute(for: name), withConfiguration: cfg)
    }

    /// Tinted, point-sized symbol ready to drop into a view.
    static func tinted(_ name: String, _ tint: UIColor, _ points: CGFloat,
                       weight: UIImage.SymbolWeight = .semibold) -> UIImageView {
        let cfg = UIImage.SymbolConfiguration(pointSize: points, weight: weight)
        let resolved = UIImage(systemName: name, withConfiguration: cfg)
            ?? UIImage(systemName: substitute(for: name), withConfiguration: cfg)
        let v = UIImageView(image: resolved)
        v.tintColor = tint
        v.contentMode = .scaleAspectFit
        return v
    }

    /// A few symbols arrived after iOS 14 — map them to close cousins.
    private static func substitute(for name: String) -> String {
        switch name {
        case "circle.dashed.inset.filled": return "circle.dashed"
        case "circle.hexagongrid.fill": return "hexagon.fill"
        case "magnet": return "scribble.variable"
        case blackhole: return "circle.dashed"
        default: return "questionmark.circle"
        }
    }
}
