//
//  PageHeader.swift
//  RocketJump
//
//  A back-arrow + title strip the secondary rooms share. Lightweight; each
//  room still arranges its own body however it likes.
//

import UIKit

final class PageHeader: UIView {

    private let onBack: () -> Void

    init(title: String, subtitle: String, onBack: @escaping () -> Void) {
        self.onBack = onBack
        super.init(frame: .zero)

        let back = UIButton(type: .system)
        back.setImage(Glyph.image("chevron.left", weight: .bold), for: .normal)
        back.tintColor = Palette.ink
        back.addTarget(self, action: #selector(tap), for: .touchUpInside)
        back.translatesAutoresizingMaskIntoConstraints = false

        let t = UILabel.make(title, Typeset.display(26, .heavy))
        let s = UILabel.make(subtitle, Typeset.body(13), Palette.inkSoft)
        let text = UIStackView(arrangedSubviews: [t, s])
        text.axis = .vertical; text.spacing = 1

        let row = UIStackView(arrangedSubviews: [back, text])
        row.axis = .horizontal; row.spacing = 12; row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)

        NSLayoutConstraint.activate([
            back.widthAnchor.constraint(equalToConstant: 34),
            back.heightAnchor.constraint(equalToConstant: 34),
            row.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    @objc private func tap() { Buzz.tap(); onBack() }
}
