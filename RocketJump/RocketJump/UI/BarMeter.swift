//
//  BarMeter.swift
//  RocketJump
//
//  A horizontal fuel/energy gauge. Draws a rounded track with a tinted fill
//  that animates its width and flushes red as it empties.
//

import UIKit

final class BarMeter: UIView {

    private let track = UIView()
    private let fill = UIView()
    private let tint: UIColor
    private var fillWidth: NSLayoutConstraint!
    private var ratio: CGFloat = 1

    init(tint: UIColor) {
        self.tint = tint
        super.init(frame: .zero)

        track.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        track.layer.cornerRadius = 7
        track.layer.cornerCurve = .continuous
        track.clipsToBounds = true
        addSubview(track)

        fill.backgroundColor = tint
        fill.layer.cornerRadius = 7
        track.addSubview(fill)

        track.translatesAutoresizingMaskIntoConstraints = false
        fill.translatesAutoresizingMaskIntoConstraints = false
        fillWidth = fill.widthAnchor.constraint(equalTo: track.widthAnchor, multiplier: 1)
        NSLayoutConstraint.activate([
            track.leadingAnchor.constraint(equalTo: leadingAnchor),
            track.trailingAnchor.constraint(equalTo: trailingAnchor),
            track.topAnchor.constraint(equalTo: topAnchor),
            track.bottomAnchor.constraint(equalTo: bottomAnchor),
            heightAnchor.constraint(equalToConstant: 14),
            fill.leadingAnchor.constraint(equalTo: track.leadingAnchor),
            fill.topAnchor.constraint(equalTo: track.topAnchor),
            fill.bottomAnchor.constraint(equalTo: track.bottomAnchor),
            fillWidth,
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    /// 0...1. Below 20% the fill bleeds toward the peril colour.
    func set(_ value: CGFloat, animated: Bool = true) {
        ratio = min(1, max(0, value))
        fillWidth.isActive = false
        fillWidth = fill.widthAnchor.constraint(equalTo: track.widthAnchor,
                                                multiplier: max(0.001, ratio))
        fillWidth.isActive = true
        let danger = ratio < 0.2
        let block = {
            self.layoutIfNeeded()
            self.fill.backgroundColor = danger
                ? Palette.peril
                : self.tint
        }
        animated ? UIView.animate(withDuration: 0.25, animations: block) : block()
    }
}
