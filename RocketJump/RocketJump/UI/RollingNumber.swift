//
//  RollingNumber.swift
//  RocketJump
//
//  A label whose value eases toward a target via CADisplayLink, so scores
//  and tallies "roll up" rather than snap. Deliberately its own tiny loop,
//  separate from any game tick.
//

import UIKit

final class RollingNumber: UILabel {

    private var shown: Double = 0
    private var target: Double = 0
    private var link: CADisplayLink?
    private var prefix = ""
    private var suffix = ""

    init(font: UIFont, color: UIColor = Palette.ink, prefix: String = "", suffix: String = "") {
        super.init(frame: .zero)
        self.font = font
        self.textColor = color
        self.prefix = prefix
        self.suffix = suffix
        self.text = render(0)
    }

    required init?(coder: NSCoder) { fatalError() }

    func roll(to value: Int) {
        target = Double(value)
        guard link == nil else { return }
        link = CADisplayLink(target: self, selector: #selector(step))
        link?.add(to: .main, forMode: .common)
    }

    /// Set instantly without animating.
    func plant(_ value: Int) {
        shown = Double(value); target = shown
        text = render(value)
    }

    @objc private func step() {
        let gap = target - shown
        if abs(gap) < 0.5 {
            shown = target
            text = render(Int(target))
            link?.invalidate(); link = nil
            return
        }
        shown += gap * 0.18
        text = render(Int(shown.rounded()))
    }

    private func render(_ n: Int) -> String { "\(prefix)\(n.grouped)\(suffix)" }

    deinit { link?.invalidate() }
}

extension Int {
    /// 12345 -> "12,345"
    var grouped: String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
