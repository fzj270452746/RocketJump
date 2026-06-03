//
//  QuestScroll.swift
//  RocketJump
//
//  Permanent objectives. Each quest renders its own progress as a thin bar;
//  once full and unclaimed, a claim chip lights up. Built as a plain scroll
//  of cards — a different refresh shape again (rebuild on appear + on claim).
//

import UIKit

final class QuestScroll: UIViewController {

    private let holdings: Holdings
    private let scroller = UIScrollView()
    private let column = UIStackView()

    init(holdings: Holdings) {
        self.holdings = holdings
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Palette.rgb(14, 10, 26)

        let header = PageHeader(title: "Quests", subtitle: "Standing orders") { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        header.translatesAutoresizingMaskIntoConstraints = false
        scroller.translatesAutoresizingMaskIntoConstraints = false
        column.axis = .vertical; column.spacing = 14
        column.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(header); view.addSubview(scroller); scroller.addSubview(column)
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
        rebuild()
    }

    private func rebuild() {
        column.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for q in QuestBoard.all {
            column.addArrangedSubview(card(q))
        }
    }

    private func card(_ q: Quest) -> UIView {
        let p = holdings.career.snap
        let progress = q.gauge(p, holdings.satchel)
        let done = progress >= 1
        let claimed = holdings.quests.isClaimed(q.id)

        let box = UIView()
        box.backgroundColor = Palette.glass
        box.layer.cornerRadius = 20
        box.layer.borderWidth = 1
        box.layer.borderColor = (done && !claimed ? Palette.coin : Palette.hairline).cgColor

        let icon = Glyph.tinted(q.symbol, done ? Palette.coin : Palette.energy, 22, weight: .bold)
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 30).isActive = true

        let title = UILabel.make(q.title, Typeset.display(17, .bold))
        let detail = UILabel.make(q.detail, Typeset.body(13), Palette.inkSoft)
        let reward = UILabel.make("Reward · \(q.reward)", Typeset.telemetry(11, .semibold), Palette.coin)

        let bar = BarMeter(tint: done ? Palette.coin : Palette.energy)
        bar.set(CGFloat(progress), animated: false)

        let texts = UIStackView(arrangedSubviews: [title, detail, reward, bar])
        texts.axis = .vertical; texts.spacing = 5
        texts.setCustomSpacing(10, after: reward)

        let head = UIStackView(arrangedSubviews: [icon, texts])
        head.axis = .horizontal; head.spacing = 14; head.alignment = .top
        head.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(head)
        NSLayoutConstraint.activate([
            head.topAnchor.constraint(equalTo: box.topAnchor, constant: 16),
            head.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 16),
            head.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -16),
        ])

        if done && !claimed {
            let claim = GlowButton("Claim Reward", symbol: "gift.fill", accent: Palette.coin)
            claim.onPress { [weak self] in self?.claim(q, box: box) }
            claim.translatesAutoresizingMaskIntoConstraints = false
            box.addSubview(claim)
            NSLayoutConstraint.activate([
                claim.topAnchor.constraint(equalTo: head.bottomAnchor, constant: 14),
                claim.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 16),
                claim.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -16),
                claim.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -16),
            ])
        } else {
            let tail = UILabel.make(claimed ? "Claimed ✓" : "In progress",
                                    Typeset.telemetry(11, .semibold),
                                    claimed ? Palette.fuel : Palette.inkSoft)
            tail.translatesAutoresizingMaskIntoConstraints = false
            box.addSubview(tail)
            NSLayoutConstraint.activate([
                tail.topAnchor.constraint(equalTo: head.bottomAnchor, constant: 12),
                tail.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 60),
                tail.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -16),
            ])
        }
        return box
    }

    private func claim(_ q: Quest, box: UIView) {
        holdings.quests.claim(q.id)
        Toast.drop(on: view, symbol: q.symbol, tint: Palette.coin,
                   title: "Reward Claimed", note: q.reward)
        UIView.animate(withDuration: 0.2) { box.alpha = 0.6 } completion: { _ in self.rebuild() }
    }
}
