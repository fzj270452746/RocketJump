//
//  MedalTile.swift
//  RocketJump
//
//  One achievement tile. Earned: a glowing crest in a tinted disc. Locked: a
//  grey crest dimmed back, criterion shown small.
//

import UIKit

final class MedalTile: UICollectionViewCell {

    private let disc = UIView()
    private let crest = UIImageView()
    private let title = UILabel.make("", Typeset.display(14, .bold), Palette.ink, align: .center)
    private let detail = UILabel.make("", Typeset.body(11), Palette.inkSoft, align: .center)

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = Palette.glass
        contentView.layer.cornerRadius = 20
        contentView.layer.cornerCurve = .continuous
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = Palette.hairline.cgColor

        disc.layer.cornerRadius = 28
        disc.translatesAutoresizingMaskIntoConstraints = false
        crest.contentMode = .scaleAspectFit
        crest.translatesAutoresizingMaskIntoConstraints = false
        disc.addSubview(crest)

        let stack = UIStackView(arrangedSubviews: [disc, title, detail])
        stack.axis = .vertical; stack.spacing = 6; stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            disc.widthAnchor.constraint(equalToConstant: 56),
            disc.heightAnchor.constraint(equalToConstant: 56),
            crest.centerXAnchor.constraint(equalTo: disc.centerXAnchor),
            crest.centerYAnchor.constraint(equalTo: disc.centerYAnchor),
            crest.widthAnchor.constraint(equalToConstant: 28),
            crest.heightAnchor.constraint(equalToConstant: 28),
            stack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func fill(_ a: Accolade, earned: Bool) {
        let tint = earned ? Palette.coin : Palette.inkSoft
        disc.backgroundColor = tint.withAlphaComponent(earned ? 0.2 : 0.08)
        crest.image = Glyph.image(a.symbol, weight: .bold)
        crest.tintColor = earned ? Palette.coin : Palette.inkSoft.withAlphaComponent(0.5)
        title.text = a.title
        title.textColor = earned ? Palette.ink : Palette.inkSoft
        detail.text = a.detail
        contentView.layer.borderColor = (earned ? Palette.coin.withAlphaComponent(0.5) : Palette.hairline).cgColor

        if earned {
            disc.layer.shadowColor = Palette.coin.cgColor
            disc.layer.shadowOpacity = 0.6
            disc.layer.shadowRadius = 10
            disc.layer.shadowOffset = .zero
        } else {
            disc.layer.shadowOpacity = 0
        }
    }
}
