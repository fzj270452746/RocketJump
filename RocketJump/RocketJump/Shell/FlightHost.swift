//
//  FlightHost.swift
//  RocketJump
//
//  The flight surface. Mounts the SpriteKit view, overlays a hand-built HUD,
//  routes taps into the stage, and listens on the session beacons. When the
//  flight concludes it folds the run into Holdings and shows the debrief.
//

import UIKit
import SpriteKit

final class FlightHost: UIViewController {

    private let world: World
    private weak var conductor: LaunchConductor?
    private let flow: SessionFlow
    private let bag = SignalBag()

    private let skView = SKView()
    private var stage: FlightStage!
    private let hud = FlightHUD()
    private var settled = false
    private var counted = false

    init(world: World, conductor: LaunchConductor?) {
        self.world = world
        self.conductor = conductor
        self.flow = SessionFlow(world: world)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = world.skyLow

        // Gradient sky behind the SpriteKit layer.
        let sky = Backdrop(world.skyTop, world.skyLow)
        sky.frame = view.bounds
        sky.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(sky)

        skView.frame = view.bounds
        skView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        skView.allowsTransparency = true
        skView.isOpaque = false
        skView.backgroundColor = .clear
        view.addSubview(skView)

        hud.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hud)
        NSLayoutConstraint.activate([
            hud.topAnchor.constraint(equalTo: view.topAnchor),
            hud.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hud.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hud.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hud.onBail = { [weak self] in self?.bail() }

        wireSignals()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        mountStage()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !counted else { return }
        counted = true
        hud.runCountdown { [weak self] in self?.stage?.arm() }   // physics goes live on GO
    }

    /// Build and present the scene once the view has real bounds — done before
    /// the present animation reveals the surface, so no blank frame flashes.
    private func mountStage() {
        guard stage == nil, skView.bounds.width > 0 else { return }
        let scene = FlightStage(size: skView.bounds.size, flow: flow)
        scene.scaleMode = .resizeFill
        skView.presentScene(scene)
        stage = scene
    }

    private func wireSignals() {
        bag.keep(flow.pulse.listen { [weak self] p in self?.hud.render(p) })
        bag.keep(flow.popup.listen { [weak self] in self?.hud.floatGain($0.0, at: $0.1) })
        bag.keep(flow.ended.listen { [weak self] report in self?.settle(report) })
    }

    // MARK: input

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        stage?.pressDown()
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        stage?.pressUp()
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        stage?.pressUp()
    }

    // MARK: end of flight

    private func bail() {
        guard !settled else { return }
        skView.scene?.isPaused = true
        showCard(crest: "pause.fill", crestTint: Palette.energy,
                 heading: "Holding",
                 message: "Take a breath. The void isn't going anywhere.",
                 actions: [
                    CardAction("Resume", accent: Palette.fuel) { [weak self] in
                        self?.skView.scene?.isPaused = false
                    },
                    CardAction("End Flight", accent: Palette.peril, filled: false) { [weak self] in
                        self?.skView.scene?.isPaused = false
                        self?.flow.conclude()
                    },
                 ])
    }

    private func settle(_ report: RunReport) {
        guard !settled else { return }
        settled = true
        skView.scene?.isPaused = true
        let aftermath = conductor?.holdings.absorb(report)
        Buzz.thud()
        let debrief = Debrief(aftermath: aftermath ?? Aftermath(report: report, opened: [],
                                                                medals: [], isBestScore: false),
                              conductor: conductor)
        debrief.modalPresentationStyle = .overFullScreen
        debrief.modalTransitionStyle = .crossDissolve
        present(debrief, animated: true)
    }
}
