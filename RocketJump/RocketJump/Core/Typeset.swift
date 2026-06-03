//
//  Typeset.swift
//  RocketJump
//
//  Font ladder. Rounded display for numbers, monospaced for telemetry.
//

import UIKit

enum Typeset {

    static func display(_ size: CGFloat, _ weight: UIFont.Weight = .heavy) -> UIFont {
        rounded(size, weight)
    }

    static func body(_ size: CGFloat, _ weight: UIFont.Weight = .regular) -> UIFont {
        .systemFont(ofSize: size, weight: weight)
    }

    /// Tabular monospaced digits — telemetry readouts that must not jitter.
    static func telemetry(_ size: CGFloat, _ weight: UIFont.Weight = .semibold) -> UIFont {
        UIFont.monospacedDigitSystemFont(ofSize: size, weight: weight)
    }

    static func rounded(_ size: CGFloat, _ weight: UIFont.Weight) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        guard let d = base.fontDescriptor.withDesign(.rounded) else { return base }
        return UIFont(descriptor: d, size: size)
    }
}

extension UILabel {
    /// Convenience builder so screens read as layout, not boilerplate.
    static func make(_ text: String, _ font: UIFont, _ color: UIColor = Palette.ink,
                     align: NSTextAlignment = .left) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = font
        l.textColor = color
        l.textAlignment = align
        l.numberOfLines = 0
        return l
    }
}
