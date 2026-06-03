//
//  ModalCard.swift
//  RocketJump
//
//  Hand-built dialog to replace UIAlertController. A dimmed scrim plus a
//  card that springs up from centre, carrying a symbol crest, copy, and a
//  stack of actions. Dismisses by tapping the scrim or an action.
//

import UIKit

struct CardAction {
    let title: String
    let accent: UIColor
    let filled: Bool
    let handler: () -> Void
    init(_ title: String, accent: UIColor = Palette.thrust, filled: Bool = true,
         _ handler: @escaping () -> Void) {
        self.title = title; self.accent = accent; self.filled = filled; self.handler = handler
    }
}

final class ModalCard: UIViewController {

    private let crest: String?
    private let crestTint: UIColor
    private let heading: String
    private let message: String
    private let actions: [CardAction]
    private let card = UIView()
    private let scrim = UIView()

    init(crest: String?, crestTint: UIColor = Palette.thrust,
         heading: String, message: String, actions: [CardAction]) {
        self.crest = crest; self.crestTint = crestTint
        self.heading = heading; self.message = message; self.actions = actions
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        scrim.backgroundColor = UIColor.black.withAlphaComponent(0.0)
        scrim.frame = view.bounds
        scrim.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(scrim)
        scrim.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapScrim)))

        buildCard()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.2) { self.scrim.backgroundColor = UIColor.black.withAlphaComponent(0.55) }
        card.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        card.alpha = 0
        UIView.animate(withDuration: 0.5, delay: 0.02, usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 0.6, options: []) {
            self.card.transform = .identity
            self.card.alpha = 1
        }
    }

    private func buildCard() {
        card.backgroundColor = Palette.rgb(24, 26, 46)
        card.layer.cornerRadius = 26
        card.layer.cornerCurve = .continuous
        card.layer.borderWidth = 1
        card.layer.borderColor = Palette.hairline.cgColor
        card.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(card)

        let column = UIStackView()
        column.axis = .vertical
        column.spacing = 14
        column.alignment = .fill
        column.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(column)

        if let crest = crest {
            let disc = UIView()
            disc.backgroundColor = crestTint.withAlphaComponent(0.16)
            disc.layer.cornerRadius = 34
            disc.translatesAutoresizingMaskIntoConstraints = false
            let sym = Glyph.tinted(crest, crestTint, 32, weight: .bold)
            sym.translatesAutoresizingMaskIntoConstraints = false
            disc.addSubview(sym)
            NSLayoutConstraint.activate([
                disc.widthAnchor.constraint(equalToConstant: 68),
                disc.heightAnchor.constraint(equalToConstant: 68),
                sym.centerXAnchor.constraint(equalTo: disc.centerXAnchor),
                sym.centerYAnchor.constraint(equalTo: disc.centerYAnchor),
            ])
            let wrap = UIStackView(arrangedSubviews: [disc])
            wrap.alignment = .center
            wrap.axis = .vertical
            column.addArrangedSubview(wrap)
        }

        column.addArrangedSubview(UILabel.make(heading, Typeset.display(24, .heavy), align: .center))
        column.addArrangedSubview(UILabel.make(message, Typeset.body(15), Palette.inkSoft, align: .center))

        let spacer = UIView(); spacer.heightAnchor.constraint(equalToConstant: 4).isActive = true
        column.addArrangedSubview(spacer)

        for a in actions {
            let b = GlowButton(a.title, accent: a.accent, filled: a.filled)
            b.onPress { [weak self] in self?.dismissCard { a.handler() } }
            column.addArrangedSubview(b)
        }

        NSLayoutConstraint.activate([
            card.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            card.widthAnchor.constraint(lessThanOrEqualToConstant: 420),
            column.topAnchor.constraint(equalTo: card.topAnchor, constant: 26),
            column.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 22),
            column.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -22),
            column.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -22),
        ])
    }

    @objc private func tapScrim() { dismissCard(nil) }

    private func dismissCard(_ then: (() -> Void)?) {
        UIView.animate(withDuration: 0.22, animations: {
            self.scrim.backgroundColor = .clear
            self.card.alpha = 0
            self.card.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }, completion: { _ in
            self.dismiss(animated: false) { then?() }
        })
    }
}

extension UIViewController {
    /// Present a ModalCard over the current surface.
    func showCard(crest: String?, crestTint: UIColor = Palette.thrust,
                  heading: String, message: String, actions: [CardAction]) {
        let card = ModalCard(crest: crest, crestTint: crestTint,
                             heading: heading, message: message, actions: actions)
        present(card, animated: false)
    }
}
