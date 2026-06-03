//
//  GlowButton.swift
//  RocketJump
//
//  A pill control with an inner glow and a spring press. Not the system
//  rounded button — it carries an optional leading symbol and animates on
//  touch with a transform + shadow pulse.
//

import UIKit

final class GlowButton: UIControl {

    private let cap = UILabel()
    private let icon = UIImageView()
    private let stack = UIStackView()
    private let accent: UIColor
    private var onTap: (() -> Void)?

    init(_ title: String, symbol: String? = nil, accent: UIColor = Palette.thrust,
         filled: Bool = true) {
        self.accent = accent
        super.init(frame: .zero)

        backgroundColor = filled ? accent.withAlphaComponent(0.16) : Palette.glass
        layer.cornerRadius = 17
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = accent.withAlphaComponent(filled ? 0.55 : 0.3).cgColor
        layer.shadowColor = accent.cgColor
        layer.shadowOpacity = 0.0
        layer.shadowRadius = 14
        layer.shadowOffset = .zero

        cap.text = title
        cap.font = Typeset.display(17, .bold)
        cap.textColor = filled ? Palette.ink : accent

        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.isUserInteractionEnabled = false
        if let symbol = symbol {
            icon.image = Glyph.image(symbol, weight: .bold)
            icon.tintColor = filled ? Palette.ink : accent
            icon.contentMode = .scaleAspectFit
            icon.widthAnchor.constraint(equalToConstant: 20).isActive = true
            stack.addArrangedSubview(icon)
        }
        stack.addArrangedSubview(cap)
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 54),
        ])

        addTarget(self, action: #selector(down), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(up), for: [.touchUpInside])
        addTarget(self, action: #selector(cancel), for: [.touchUpOutside, .touchDragExit, .touchCancel])
    }

    required init?(coder: NSCoder) { fatalError() }

    func onPress(_ action: @escaping () -> Void) { onTap = action }

    @objc private func down() {
        UIView.animate(withDuration: 0.12) {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            self.layer.shadowOpacity = 0.7
        }
    }

    @objc private func cancel() { settle() }

    @objc private func up() {
        settle()
        Buzz.tap()
        onTap?()
    }

    private func settle() {
        UIView.animate(withDuration: 0.34, delay: 0, usingSpringWithDamping: 0.55,
                       initialSpringVelocity: 0.4, options: []) {
            self.transform = .identity
            self.layer.shadowOpacity = 0.0
        }
    }
}
