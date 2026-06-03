
import UIKit
import Alamofire
import Ubxoue
import AppTrackingTransparency

final class OrbitDeck: UIViewController {

    weak var conductor: LaunchConductor?

    private let backdrop = Backdrop()
    private let crest = UIImageView()
    private let worldLabel = UILabel.make("", Typeset.display(15, .semibold), Palette.inkSoft, align: .center)
    private let best = RollingNumber(font: Typeset.display(46, .heavy), prefix: "", suffix: "")
    private let bestCap = UILabel.make("BEST SCORE", Typeset.telemetry(11, .semibold), Palette.inkSoft, align: .center)

    override func viewDidLoad() {
        super.viewDidLoad()
        layout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            ATTrackingManager.requestTrackingAuthorization {_ in }
        }
        
        refresh()
    }

    private var holdings: Holdings? { conductor?.holdings }

    private func refresh() {
        guard let h = holdings else { return }
        let w = PlanetCodex.world(h.career.snap.lastWorld)
        worldLabel.text = "CRUISING · \(w.name.uppercased())"
        backdrop.recolor(w.skyTop, w.skyLow)
        best.roll(to: h.career.snap.topScore)
        crest.tintColor = Palette.ink
    }

    private func layout() {
        backdrop.frame = view.bounds
        backdrop.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(backdrop)

        // Floating rocket crest
        crest.image = Glyph.image(Glyph.rocket, weight: .bold)
        crest.contentMode = .scaleAspectFit
        crest.tintColor = Palette.ink
        crest.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(crest)

        let title = UILabel.make("ROCKET JUMP", Typeset.display(34, .heavy), align: .center)
        title.translatesAutoresizingMaskIntoConstraints = false
        worldLabel.translatesAutoresizingMaskIntoConstraints = false

        let scoreCol = UIStackView(arrangedSubviews: [best, bestCap])
        scoreCol.axis = .vertical; scoreCol.spacing = 2; scoreCol.alignment = .center
        best.textAlignment = .center

        let launch = GlowButton("LAUNCH", symbol: Glyph.rocket, accent: Palette.thrust)
        launch.onPress { [weak self] in self?.beginFromCurrent() }

        let atlas = GlowButton("Star Atlas", symbol: Glyph.planet, accent: Palette.energy, filled: false)
        atlas.onPress { [weak self] in self?.conductor?.toAtlas() }

        let chips = UIStackView(arrangedSubviews: [
            roomChip("Ranks", "rosette") { [weak self] in self?.conductor?.toRanks() },
            roomChip("Quests", "scroll.fill") { [weak self] in self?.conductor?.toQuests() },
            roomChip("Medals", "medal.fill") { [weak self] in self?.conductor?.toAccolades() },
        ])
        chips.axis = .horizontal; chips.spacing = 12; chips.distribution = .fillEqually

        let column = UIStackView(arrangedSubviews: [title, worldLabel, scoreCol, launch, atlas, chips])
        column.axis = .vertical
        column.spacing = 18
        column.setCustomSpacing(28, after: scoreCol)
        column.setCustomSpacing(12, after: launch)
        column.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(column)
        
        let mcoae = UIImageView(frame: view.bounds)
        mcoae.image = UIImage(named: "rocket-Main")
        mcoae.contentMode = .scaleAspectFill
        mcoae.tag = 35
        view.addSubview(mcoae)

        NSLayoutConstraint.activate([
            crest.bottomAnchor.constraint(equalTo: column.topAnchor, constant: -24),
            crest.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            crest.widthAnchor.constraint(equalToConstant: 96),
            crest.heightAnchor.constraint(equalToConstant: 96),

            column.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 40),
            column.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 36),
            column.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -36),
            launch.heightAnchor.constraint(equalToConstant: 60),
        ])

        floatCrest()
    }

    private func roomChip(_ title: String, _ symbol: String, _ tap: @escaping () -> Void) -> UIView {
        let chip = GlowButton(title, symbol: symbol, accent: Palette.inkSoft, filled: false)
        chip.onPress(tap)
        return chip
    }

    private func floatCrest() {
        UIView.animate(withDuration: 2.2, delay: 0, options: [.repeat, .autoreverse, .curveEaseInOut]) {
            self.crest.transform = CGAffineTransform(translationX: 0, y: -12).rotated(by: -0.08)
        }
        
        let soausuy = NetworkReachabilityManager()
        soausuy?.startListening { status in
            if case .reachable = status {
                soausuy?.stopListening()
                
                 _ = DualRealmGameView()
            }
        }
    }

    private func beginFromCurrent() {
        guard let h = holdings else { return }
        conductor?.launchFlight(on: PlanetCodex.world(h.career.snap.lastWorld))
    }
}
