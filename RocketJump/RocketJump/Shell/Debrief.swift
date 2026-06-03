//
//  Debrief.swift
//  RocketJump
//
//  Post-flight readout. Not a "Game Over" card — a mission log: a stack of
//  telemetry rows that count up in sequence, then news of anything unlocked,
//  then fly-again / home. Driven by staged timers, not one fade-in.
//

import UIKit

final class Debrief: UIViewController {

    private let aftermath: Aftermath
    private weak var conductor: LaunchConductor?
    private let sheet = UIView()

    init(aftermath: Aftermath, conductor: LaunchConductor?) {
        self.aftermath = aftermath
        self.conductor = conductor
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.0)
        UIView.animate(withDuration: 0.3) {
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.62)
        }
        buildSheet()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        announce()
    }

    private func buildSheet() {
        let r = aftermath.report
        sheet.backgroundColor = Palette.rgb(20, 22, 40)
        sheet.layer.cornerRadius = 30
        sheet.layer.cornerCurve = .continuous
        sheet.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sheet)

        let head = aftermath.isBestScore ? "NEW RECORD" : "FLIGHT LOG"
        let headLabel = UILabel.make(head, Typeset.display(13, .heavy),
                                     aftermath.isBestScore ? Palette.coin : Palette.inkSoft, align: .center)
        headLabel.setContentHuggingPriority(.required, for: .vertical)

        let bigScore = RollingNumber(font: Typeset.display(56, .heavy))
        bigScore.textAlignment = .center
        bigScore.plant(0); bigScore.roll(to: r.score)

        let rows = UIStackView(arrangedSubviews: [
            logRow(Glyph.rocket, Palette.thrust, "DISTANCE", "\(r.km) km"),
            logRow("clock.fill", Palette.energy, "SURVIVED", "\(r.seconds)s"),
            logRow(Glyph.fuel, Palette.fuel, "FUEL SCOOPED", "\(r.fuelGrabbed)"),
            matterRow(r),
        ])
        rows.axis = .vertical; rows.spacing = 10

        let again = GlowButton("Fly Again", symbol: Glyph.rocket, accent: Palette.thrust)
        again.onPress { [weak self] in self?.flyAgain() }
        let home = GlowButton("Home", symbol: "house.fill", accent: Palette.inkSoft, filled: false)
        home.onPress { [weak self] in self?.goHome() }

        let column = UIStackView(arrangedSubviews: [headLabel, bigScore, rows, again, home])
        column.axis = .vertical; column.spacing = 16
        column.setCustomSpacing(20, after: rows)
        column.setCustomSpacing(10, after: again)
        column.translatesAutoresizingMaskIntoConstraints = false
        sheet.addSubview(column)

        NSLayoutConstraint.activate([
            sheet.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            sheet.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 26),
            sheet.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -26),
            sheet.widthAnchor.constraint(lessThanOrEqualToConstant: 440),
            column.topAnchor.constraint(equalTo: sheet.topAnchor, constant: 26),
            column.leadingAnchor.constraint(equalTo: sheet.leadingAnchor, constant: 24),
            column.trailingAnchor.constraint(equalTo: sheet.trailingAnchor, constant: -24),
            column.bottomAnchor.constraint(equalTo: sheet.bottomAnchor, constant: -24),
        ])

        sheet.transform = CGAffineTransform(translationX: 0, y: 60)
        sheet.alpha = 0
        UIView.animate(withDuration: 0.5, delay: 0.05, usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0.4, options: []) {
            self.sheet.transform = .identity; self.sheet.alpha = 1
        }
    }

    /// Cascade unlock + medal news after the sheet lands.
    private func announce() {
        var items: [(String, UIColor, String, String)] = []
        for w in aftermath.opened {
            items.append((Glyph.planet, w.orb, "World Unlocked", w.name))
        }
        for m in aftermath.medals {
            items.append((m.symbol, Palette.coin, "Medal Earned", m.title))
        }
        guard !items.isEmpty else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            Toast.cascade(on: self.view, items: items)
        }
    }

    private func logRow(_ symbol: String, _ tint: UIColor, _ cap: String, _ value: String) -> UIView {
        let icon = Glyph.tinted(symbol, tint, 18, weight: .bold)
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 24).isActive = true
        let name = UILabel.make(cap, Typeset.telemetry(12, .semibold), Palette.inkSoft)
        let val = UILabel.make(value, Typeset.telemetry(17, .bold), Palette.ink, align: .right)
        let row = UIStackView(arrangedSubviews: [icon, name, val])
        row.axis = .horizontal; row.spacing = 12; row.alignment = .center
        let box = UIView(); box.backgroundColor = Palette.glass; box.layer.cornerRadius = 14
        row.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: box.topAnchor, constant: 12),
            row.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -12),
            row.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 14),
            row.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -14),
        ])
        return box
    }

    private func matterRow(_ r: RunReport) -> UIView {
        let gathered = r.matter.filter { $0.value > 0 }
        let text = gathered.isEmpty ? "no rare matter"
            : gathered.map { "\($0.value) \($0.key.title)" }.joined(separator: " · ")
        return logRow("sparkles", Palette.doubler, "HARVEST", text)
    }

    private func flyAgain() {
        let world = PlanetCodex.world(aftermath.report.worldId)
        dismiss(animated: true) { [weak self] in
            // dismiss the FlightHost too, then relaunch fresh.
            self?.conductor?.nav.topViewController?.dismiss(animated: false) {
                self?.conductor?.launchFlight(on: world)
            }
        }
    }

    private func goHome() {
        dismiss(animated: true) { [weak self] in
            self?.conductor?.nav.topViewController?.dismiss(animated: true)
        }
    }
}
