//
//  FlightHUD.swift
//  RocketJump
//
//  The in-flight overlay. Top row holds telemetry (distance, score) and a
//  bail control; a slim fuel rail sits beneath; energy and boost pips ride
//  the corner. It listens to nothing directly — FlightHost feeds it pulses.
//

import UIKit

final class FlightHUD: UIView {

    var onBail: (() -> Void)?

    private let distance = UILabel.make("0 km", Typeset.telemetry(15, .bold), Palette.ink)
    private let score = RollingNumber(font: Typeset.display(30, .heavy))
    private let fuel = BarMeter(tint: Palette.fuel)
    private let energy = BarMeter(tint: Palette.energy)
    private let boostRow = UIStackView()
    private let countdown = UILabel.make("", Typeset.display(96, .heavy), Palette.ink, align: .center)
    private var pips: [Boost: UIView] = [:]

    private let bail = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        build()
    }
    required init?(coder: NSCoder) { fatalError() }

    /// The overlay covers the whole surface but only the bail control should
    /// catch touches — everything else falls through to the SpriteKit scene
    /// so the player can thrust anywhere on screen.
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        bail.bounds.contains(convert(point, to: bail)) ? bail : nil
    }

    private func build() {
        bail.setImage(Glyph.image("pause.fill", weight: .bold), for: .normal)
        bail.tintColor = Palette.inkSoft
        bail.addTarget(self, action: #selector(tapBail), for: .touchUpInside)
        bail.translatesAutoresizingMaskIntoConstraints = false

        let distChip = pill(distance, Palette.glass)
        score.textAlignment = .center

        let topRow = UIStackView(arrangedSubviews: [distChip, UIView(), bail])
        topRow.axis = .horizontal
        topRow.alignment = .center
        topRow.translatesAutoresizingMaskIntoConstraints = false

        let fuelTag = Glyph.tinted(Glyph.fuel, Palette.fuel, 15, weight: .bold)
        let enTag = Glyph.tinted(Glyph.energy, Palette.energy, 13, weight: .bold)
        let fuelRow = labelled(fuelTag, fuel)
        let enRow = labelled(enTag, energy)
        let meters = UIStackView(arrangedSubviews: [fuelRow, enRow])
        meters.axis = .vertical; meters.spacing = 8
        meters.translatesAutoresizingMaskIntoConstraints = false

        boostRow.axis = .horizontal; boostRow.spacing = 8
        boostRow.translatesAutoresizingMaskIntoConstraints = false

        score.translatesAutoresizingMaskIntoConstraints = false
        countdown.translatesAutoresizingMaskIntoConstraints = false
        countdown.alpha = 0

        addSubview(topRow); addSubview(score); addSubview(meters)
        addSubview(boostRow); addSubview(countdown)

        NSLayoutConstraint.activate([
            topRow.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 8),
            topRow.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            topRow.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            bail.widthAnchor.constraint(equalToConstant: 40),
            bail.heightAnchor.constraint(equalToConstant: 40),

            score.topAnchor.constraint(equalTo: topRow.bottomAnchor, constant: 6),
            score.centerXAnchor.constraint(equalTo: centerXAnchor),

            meters.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -14),
            meters.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            meters.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),

            boostRow.bottomAnchor.constraint(equalTo: meters.topAnchor, constant: -14),
            boostRow.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),

            countdown.centerXAnchor.constraint(equalTo: centerXAnchor),
            countdown.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    // MARK: feeds

    func render(_ p: FlightPulse) {
        distance.text = "\(p.distanceKm) km"
        score.roll(to: p.score)
        fuel.set(p.fuel)
        energy.set(p.energy)
        syncPips(p.boosts)
    }

    func floatGain(_ pickup: Pickup, at scenePoint: CGPoint) {
        // SpriteKit y is bottom-up; flip into UIKit space.
        let pt = CGPoint(x: scenePoint.x, y: bounds.height - scenePoint.y)
        let tag = UILabel.make("+\(pickup.bounty)", Typeset.display(18, .heavy), pickup.tint, align: .center)
        tag.sizeToFit()
        tag.center = pt
        addSubview(tag)
        UIView.animate(withDuration: 0.7, animations: {
            tag.center.y -= 46
            tag.alpha = 0
            tag.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        }, completion: { _ in tag.removeFromSuperview() })
    }

    func runCountdown(onGo: @escaping () -> Void) {
        let marks = ["3", "2", "1", "GO"]
        for (i, m) in marks.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.6) {
                self.flashMark(m)
                if m == "GO" { onGo() }
            }
        }
    }

    private func flashMark(_ s: String) {
        countdown.text = s
        countdown.alpha = 1
        countdown.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
        Buzz.knock()
        UIView.animate(withDuration: 0.5, animations: {
            self.countdown.transform = .identity
            self.countdown.alpha = 0
        })
    }

    // MARK: boost pips

    private func syncPips(_ active: [Boost: TimeInterval]) {
        for b in Boost.allCases {
            if let left = active[b] {
                let pip = pips[b] ?? makePip(b)
                if pips[b] == nil { pips[b] = pip; boostRow.addArrangedSubview(pip) }
                pip.alpha = left < 2 ? CGFloat(0.4 + 0.6 * (left.truncatingRemainder(dividingBy: 0.5) / 0.5)) : 1
            } else if let pip = pips[b] {
                pip.removeFromSuperview(); pips[b] = nil
            }
        }
    }

    private func makePip(_ b: Boost) -> UIView {
        let v = UIView()
        v.backgroundColor = b.tint.withAlphaComponent(0.18)
        v.layer.cornerRadius = 16
        v.layer.borderWidth = 1
        v.layer.borderColor = b.tint.cgColor
        let sym = Glyph.tinted(b.symbol, b.tint, 16, weight: .bold)
        sym.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(sym)
        v.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            v.widthAnchor.constraint(equalToConstant: 34),
            v.heightAnchor.constraint(equalToConstant: 34),
            sym.centerXAnchor.constraint(equalTo: v.centerXAnchor),
            sym.centerYAnchor.constraint(equalTo: v.centerYAnchor),
        ])
        return v
    }

    // MARK: bits

    @objc private func tapBail() { Buzz.tap(); onBail?() }

    private func pill(_ label: UILabel, _ fill: UIColor) -> UIView {
        let box = UIView()
        box.backgroundColor = fill
        box.layer.cornerRadius = 14
        label.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: box.topAnchor, constant: 7),
            label.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -7),
            label.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 14),
            label.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -14),
        ])
        return box
    }

    private func labelled(_ tag: UIView, _ meter: BarMeter) -> UIView {
        tag.translatesAutoresizingMaskIntoConstraints = false
        meter.translatesAutoresizingMaskIntoConstraints = false
        let row = UIStackView(arrangedSubviews: [tag, meter])
        row.axis = .horizontal; row.spacing = 10; row.alignment = .center
        tag.widthAnchor.constraint(equalToConstant: 22).isActive = true
        return row
    }
}
