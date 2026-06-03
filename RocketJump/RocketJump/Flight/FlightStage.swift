//
//  FlightStage.swift
//  RocketJump
//
//  The SpriteKit world. It mixes loops on purpose:
//   - update(_:)        drives distance, lean, magnet sweep (per-frame)
//   - SKAction queues   spawn pickups and hazards on their own timed cadence
//   - the fuel drain    is owned by SessionFlow, ticked from here
//  Contacts feed the SessionFlow, which the HUD listens to over beacons.
//

import SpriteKit

final class FlightStage: SKScene, SKPhysicsContactDelegate {

    let flow: SessionFlow
    let world: World

    var rocket: ThrustBody!
    private var parallax: DriftField!
    private var lastTime: TimeInterval = 0
    private var travelled: CGFloat = 0          // points flown, mapped to km
    private var thrusting = false
    private var armed = false                    // motion paused until countdown ends
    private var vy: CGFloat = 0                  // rocket's vertical speed, in points/sec

    private let kmPerPoint: CGFloat = 0.012      // tuning: world scroll -> km

    // Flight feel, all in screen points so it's resolution-independent. We move
    // the rocket by integrating position directly — SpriteKit's physics velocity
    // carries an opaque internal scale, so we never rely on it for motion.
    private var gravity: CGFloat { 2200 * world.climate.gravityScale }   // pts/s² pulling down
    private let tapBoost: CGFloat = 560          // upward speed a tap snaps to (pts/s)
    private let holdAccel: CGFloat = 2600        // extra lift while finger held (pts/s²)
    private let fallCap: CGFloat = -1100         // terminal fall speed (pts/s)
    private let riseCap: CGFloat = 1000          // max climb speed (pts/s)

    init(size: CGSize, flow: SessionFlow) {
        self.flow = flow
        self.world = flow.world
        super.init(size: size)
        scaleMode = .resizeFill
    }

    required init?(coder: NSCoder) { fatalError() }

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        isUserInteractionEnabled = true
        // Gravity is hand-rolled in update() (points/s²) for predictable feel,
        // so the physics world itself stays weightless.
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self

        parallax = DriftField(size: size, world: world)
        addChild(parallax)

        rocket = ThrustBody(diameter: min(size.width, size.height) * 0.12, tint: Palette.ink)
        rocket.position = CGPoint(x: size.width * 0.3, y: size.height * 0.55)
        addChild(rocket)

        if world.climate.haze > 0 { addHaze() }

        flow.begin()
        startSpawnQueues()
    }

    /// Called by the host when the 3-2-1 countdown finishes: motion goes live.
    func arm() {
        armed = true
        vy = tapBoost          // start with a lift, not a drop
        rocket.flap()
    }

    // MARK: input — taps thrust, hold sustains a softer lift

    func pressDown() {
        guard armed else { return }
        thrusting = true
        vy = max(vy, tapBoost)   // snap up; rapid taps never cut a faster climb short
        rocket.flap()
    }
    func pressUp() { thrusting = false; rocket.easeFlame() }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { pressDown() }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { pressUp() }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { pressUp() }

    // MARK: the per-frame loop

    override func update(_ t: TimeInterval) {
        guard flow.phase == .flying else { return }
        let dt = lastTime == 0 ? 0 : min(t - lastTime, 1.0 / 30)
        lastTime = t

        // Hold the rocket steady through the 3-2-1 countdown.
        guard armed else {
            parallax.advance(dt, jitter: world.climate.jitter)
            flow.broadcast()
            return
        }

        // Vertical motion by direct position integration (points). Gravity pulls
        // down every frame; holding adds lift. We move position ourselves rather
        // than trusting physics velocity, whose units are opaque.
        vy -= gravity * CGFloat(dt)
        if thrusting { vy += holdAccel * CGFloat(dt) }
        vy = max(fallCap, min(riseCap, vy))
        rocket.position.y += vy * CGFloat(dt)

        // Horizontal drift from biome wind.
        if world.climate.driftWind != 0 {
            rocket.position.x += world.climate.driftWind * CGFloat(dt)
        }
        keepInLane()

        rocket.lean(toVelocity: vy)
        parallax.advance(dt, jitter: world.climate.jitter)

        // Distance + fuel + boosts.
        let speed: CGFloat = 230 * (flow.live.boosts[.booster] != nil ? 1.8 : 1)
        travelled += speed * CGFloat(dt)
        flow.setDistance(Int(travelled * kmPerPoint))
        flow.burnFuel(CGFloat(dt) * 0.022)
        flow.bumpEnergy(CGFloat(dt) * 0.05)
        awardStreakIfDue()

        let expired = flow.tickBoosts(dt)
        if expired.contains(.shield) { rocket.flashShield(false) }

        if flow.magnetActive() { sweepMagnet() }
        flow.broadcast()
    }

    /// Soft walls so the rocket can't leave the playfield.
    private func keepInLane() {
        let pad = rocket.radius
        if rocket.position.y > size.height - pad {
            rocket.position.y = size.height - pad
            if vy > 0 { vy = 0 }
        }
        if rocket.position.y < pad {
            rocket.position.y = pad
            if vy < 0 { vy = 0 }
        }
        rocket.position.x = max(pad, min(size.width * 0.6, rocket.position.x))
    }

    /// One soft round spark texture shared by every burst, baked once.
    static let sparkTexture: SKTexture = {
        let s: CGFloat = 16
        let r = UIGraphicsImageRenderer(size: CGSize(width: s, height: s))
        let img = r.image { ctx in
            let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                  colors: [UIColor.white.cgColor,
                                           UIColor.white.withAlphaComponent(0).cgColor] as CFArray,
                                  locations: [0, 1])!
            ctx.cgContext.drawRadialGradient(grad, startCenter: CGPoint(x: s/2, y: s/2),
                                             startRadius: 0, endCenter: CGPoint(x: s/2, y: s/2),
                                             endRadius: s/2, options: [])
        }
        return SKTexture(image: img)
    }()
}
