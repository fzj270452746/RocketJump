//
//  Backdrop.swift
//  RocketJump
//
//  A reusable starfield + gradient view. Stars are CALayers twinkling on a
//  CAKeyframeAnimation — pure CoreAnimation, no game loop involved.
//

import UIKit

final class Backdrop: UIView {

    private let sky = CAGradientLayer()
    private var stars: [CALayer] = []
    private var top: UIColor
    private var low: UIColor

    init(_ top: UIColor = Palette.voidTop, _ low: UIColor = Palette.voidLow) {
        self.top = top; self.low = low
        super.init(frame: .zero)
        layer.addSublayer(sky)
        sky.colors = [top.cgColor, low.cgColor]
    }

    required init?(coder: NSCoder) { fatalError() }

    func recolor(_ top: UIColor, _ low: UIColor) {
        self.top = top; self.low = low
        let fade = CABasicAnimation(keyPath: "colors")
        fade.fromValue = sky.colors
        fade.toValue = [top.cgColor, low.cgColor]
        fade.duration = 0.6
        sky.add(fade, forKey: "recolor")
        sky.colors = [top.cgColor, low.cgColor]
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        sky.frame = bounds
        if stars.isEmpty { scatter() }
    }

    private func scatter() {
        for _ in 0..<70 {
            let dot = CALayer()
            let s = CGFloat.random(in: 1...2.8)
            dot.frame = CGRect(x: .random(in: 0...bounds.width),
                               y: .random(in: 0...bounds.height),
                               width: s, height: s)
            dot.cornerRadius = s / 2
            dot.backgroundColor = UIColor.white.cgColor
            dot.opacity = Float.random(in: 0.2...0.9)
            layer.addSublayer(dot)
            stars.append(dot)

            let tw = CAKeyframeAnimation(keyPath: "opacity")
            tw.values = [dot.opacity, Float.random(in: 0.05...0.3), dot.opacity]
            tw.duration = .random(in: 2.4...5.5)
            tw.repeatCount = .infinity
            tw.beginTime = CACurrentMediaTime() + .random(in: 0...3)
            dot.add(tw, forKey: "twinkle")
        }
    }
}
