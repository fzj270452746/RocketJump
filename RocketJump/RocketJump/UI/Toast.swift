//
//  Toast.swift
//  RocketJump
//
//  Top-anchored banner for transient news — a world opening, a medal earned.
//  Slides down, lingers, retracts. A different rhythm from the centre modal
//  so the two never feel like the same component.
//

import UIKit

enum Toast {

    static func drop(on host: UIView, symbol: String, tint: UIColor,
                     title: String, note: String) {
        let bar = UIView()
        bar.backgroundColor = Palette.rgb(28, 30, 52)
        bar.layer.cornerRadius = 18
        bar.layer.cornerCurve = .continuous
        bar.layer.borderWidth = 1
        bar.layer.borderColor = tint.withAlphaComponent(0.5).cgColor
        bar.layer.shadowColor = UIColor.black.cgColor
        bar.layer.shadowOpacity = 0.35
        bar.layer.shadowRadius = 12
        bar.layer.shadowOffset = CGSize(width: 0, height: 6)
        bar.translatesAutoresizingMaskIntoConstraints = false

        let sym = Glyph.tinted(symbol, tint, 24, weight: .bold)
        let head = UILabel.make(title, Typeset.display(15, .bold))
        let sub = UILabel.make(note, Typeset.body(12), Palette.inkSoft)
        let text = UIStackView(arrangedSubviews: [head, sub])
        text.axis = .vertical; text.spacing = 1

        let row = UIStackView(arrangedSubviews: [sym, text])
        row.axis = .horizontal; row.spacing = 12; row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        sym.widthAnchor.constraint(equalToConstant: 30).isActive = true
        bar.addSubview(row)
        host.addSubview(bar)

        let drop = bar.topAnchor.constraint(equalTo: host.safeAreaLayoutGuide.topAnchor, constant: -90)
        NSLayoutConstraint.activate([
            bar.leadingAnchor.constraint(equalTo: host.leadingAnchor, constant: 20),
            bar.trailingAnchor.constraint(equalTo: host.trailingAnchor, constant: -20),
            drop,
            row.leadingAnchor.constraint(equalTo: bar.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: bar.trailingAnchor, constant: -16),
            row.topAnchor.constraint(equalTo: bar.topAnchor, constant: 14),
            row.bottomAnchor.constraint(equalTo: bar.bottomAnchor, constant: -14),
        ])
        host.layoutIfNeeded()

        drop.constant = 12
        UIView.animate(withDuration: 0.55, delay: 0, usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 0.5, options: []) {
            host.layoutIfNeeded()
        }
        Buzz.chime()

        UIView.animate(withDuration: 0.35, delay: 2.4, options: []) {
            drop.constant = -110
            host.layoutIfNeeded()
            bar.alpha = 0
        } completion: { _ in bar.removeFromSuperview() }
    }

    /// Drop several banners in a staggered cascade.
    static func cascade(on host: UIView, items: [(String, UIColor, String, String)]) {
        for (i, it) in items.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.5) {
                drop(on: host, symbol: it.0, tint: it.1, title: it.2, note: it.3)
            }
        }
    }
}
