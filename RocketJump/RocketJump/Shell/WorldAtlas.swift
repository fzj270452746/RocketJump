//
//  WorldAtlas.swift
//  RocketJump
//
//  The star map. A vertical scroll of world plates; unlocked ones launch,
//  locked ones reveal their gate as a checklist. Each plate recolours to its
//  biome so the list reads as a journey outward.
//

import UIKit

final class WorldAtlas: UIViewController {

    private weak var conductor: LaunchConductor?
    private let scroller = UIScrollView()
    private let column = UIStackView()

    init(conductor: LaunchConductor?) {
        self.conductor = conductor
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Palette.voidTop
        let bg = Backdrop(Palette.voidTop, Palette.voidLow)
        bg.frame = view.bounds; bg.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(bg)

        let header = PageHeader(title: "Star Atlas", subtitle: "Chart the system") { [weak self] in
            self?.conductor?.nav.popViewController(animated: true)
        }
        header.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(header)

        scroller.translatesAutoresizingMaskIntoConstraints = false
        scroller.showsVerticalScrollIndicator = false
        view.addSubview(scroller)

        column.axis = .vertical; column.spacing = 14
        column.translatesAutoresizingMaskIntoConstraints = false
        scroller.addSubview(column)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            scroller.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 8),
            scroller.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroller.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroller.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            column.topAnchor.constraint(equalTo: scroller.topAnchor, constant: 4),
            column.bottomAnchor.constraint(equalTo: scroller.bottomAnchor, constant: -28),
            column.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            column.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])

        buildPlates()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        buildPlates()    // refresh lock states on return
    }

    private func buildPlates() {
        guard let h = conductor?.holdings else { return }
        column.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for w in PlanetCodex.worlds {
            let unlocked = h.career.snap.unlockedWorlds.contains(w.id)
            column.addArrangedSubview(plate(w, unlocked: unlocked, holdings: h))
        }
    }

    private func plate(_ w: World, unlocked: Bool, holdings h: Holdings) -> UIView {
        let card = UIView()
        card.backgroundColor = w.skyLow.withAlphaComponent(unlocked ? 0.4 : 0.16)
        card.layer.cornerRadius = 22
        card.layer.cornerCurve = .continuous
        card.layer.borderWidth = 1
        card.layer.borderColor = w.orb.withAlphaComponent(unlocked ? 0.7 : 0.2).cgColor

        let orb = UIView()
        orb.backgroundColor = w.orb.withAlphaComponent(unlocked ? 0.9 : 0.3)
        orb.layer.cornerRadius = 26
        orb.translatesAutoresizingMaskIntoConstraints = false
        if !unlocked {
            let lock = Glyph.tinted("lock.fill", Palette.ink, 18, weight: .bold)
            lock.translatesAutoresizingMaskIntoConstraints = false
            orb.addSubview(lock)
            NSLayoutConstraint.activate([
                lock.centerXAnchor.constraint(equalTo: orb.centerXAnchor),
                lock.centerYAnchor.constraint(equalTo: orb.centerYAnchor)])
        }

        let name = UILabel.make(w.name, Typeset.display(20, .bold))
        let blurb = UILabel.make(unlocked ? w.blurb : gateText(w, h), Typeset.body(13), Palette.inkSoft)
        let text = UIStackView(arrangedSubviews: [name, blurb])
        text.axis = .vertical; text.spacing = 3

        let head = UIStackView(arrangedSubviews: [orb, text])
        head.axis = .horizontal; head.spacing = 14; head.alignment = .center
        head.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(head)

        NSLayoutConstraint.activate([
            orb.widthAnchor.constraint(equalToConstant: 52),
            orb.heightAnchor.constraint(equalToConstant: 52),
            head.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            head.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            head.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
        ])

        if unlocked {
            let go = GlowButton("Launch", symbol: Glyph.rocket, accent: w.orb)
            go.onPress { [weak self] in
                self?.conductor?.holdings.career.mutate { $0.lastWorld = w.id }
                self?.conductor?.launchFlight(on: w)
            }
            go.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(go)
            NSLayoutConstraint.activate([
                go.topAnchor.constraint(equalTo: head.bottomAnchor, constant: 14),
                go.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
                go.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
                go.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            ])
        } else {
            head.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16).isActive = true
        }
        return card
    }

    private func gateText(_ w: World, _ h: Holdings) -> String {
        let parts = w.gate.rules.map { rule -> String in
            let have = rule.0.reading(h.career.snap, h.satchel)
            return "\(label(rule.0)) \(have)/\(rule.1)"
        }
        let mode = w.gate.needAtLeast < w.gate.rules.count ? "Any \(w.gate.needAtLeast): " : ""
        return mode + parts.joined(separator: " · ")
    }

    private func label(_ t: Tally) -> String {
        switch t {
        case .distance: return "Dist"
        case .score: return "Score"
        case .fuelTaken: return "Fuel"
        case .matter(let m): return m.title
        }
    }
}
