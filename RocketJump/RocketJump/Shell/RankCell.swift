//
//  RankCell.swift
//  RocketJump
//
//  One leaderboard row: rank badge, the headline figure, and a world note.
//  Top three get a warmer badge so the podium stands out.
//

import UIKit

final class RankCell: UITableViewCell {

    private let badge = UILabel()
    private let primary = UILabel.make("", Typeset.display(20, .heavy))
    private let detail = UILabel.make("", Typeset.body(12), Palette.inkSoft, align: .right)
    private let plate = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        plate.backgroundColor = Palette.glass
        plate.layer.cornerRadius = 16
        plate.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(plate)

        badge.font = Typeset.telemetry(16, .heavy)
        badge.textAlignment = .center
        badge.textColor = Palette.voidTop
        badge.layer.cornerRadius = 16
        badge.clipsToBounds = true
        badge.translatesAutoresizingMaskIntoConstraints = false

        let texts = UIStackView(arrangedSubviews: [primary, detail])
        texts.axis = .horizontal; texts.distribution = .fill
        primary.setContentHuggingPriority(.defaultLow, for: .horizontal)
        texts.translatesAutoresizingMaskIntoConstraints = false

        plate.addSubview(badge); plate.addSubview(texts)
        NSLayoutConstraint.activate([
            plate.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            plate.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            plate.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            plate.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            badge.leadingAnchor.constraint(equalTo: plate.leadingAnchor, constant: 12),
            badge.centerYAnchor.constraint(equalTo: plate.centerYAnchor),
            badge.widthAnchor.constraint(equalToConstant: 32),
            badge.heightAnchor.constraint(equalToConstant: 32),
            texts.leadingAnchor.constraint(equalTo: badge.trailingAnchor, constant: 14),
            texts.trailingAnchor.constraint(equalTo: plate.trailingAnchor, constant: -16),
            texts.centerYAnchor.constraint(equalTo: plate.centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func fill(rank: Int, primary value: String, detail note: String) {
        badge.text = "\(rank)"
        badge.backgroundColor = rank <= 3 ? Palette.coin : Palette.inkSoft.withAlphaComponent(0.5)
        primary.text = value
        primary.textColor = Palette.ink
        detail.text = note
    }

    func showEmpty(_ text: String) {
        badge.text = "·"
        badge.backgroundColor = Palette.inkSoft.withAlphaComponent(0.3)
        primary.text = text
        primary.font = Typeset.body(15)
        primary.textColor = Palette.inkSoft
        detail.text = ""
    }
}
