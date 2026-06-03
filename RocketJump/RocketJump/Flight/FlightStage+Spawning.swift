//
//  FlightStage+Spawning.swift
//  RocketJump
//
//  The action-queue side of the scene: timed waves of pickups and hazards
//  that scroll leftward, the magnet sweep, contact resolution, and the
//  streak bonus. Kept apart from the per-frame loop on purpose.
//

import SpriteKit

extension FlightStage {

    func startSpawnQueues() {
        // Pickups on one cadence...
        let pickupCycle = SKAction.sequence([
            .wait(forDuration: 1.1, withRange: 0.7),
            .run { [weak self] in self?.emitPickup() },
        ])
        run(.repeatForever(pickupCycle), withKey: "pickups")

        // ...hazards on a separate, biome-scaled cadence.
        let gap = 2.4 / Double(world.climate.hazardRate)
        let hazardCycle = SKAction.sequence([
            .wait(forDuration: gap, withRange: gap * 0.5),
            .run { [weak self] in self?.emitHazard() },
        ])
        run(.repeatForever(hazardCycle), withKey: "hazards")
    }

    private func emitPickup() {
        let f = Floater(role: .pickup(rollPickup()), size: laneUnit)
        f.position = CGPoint(x: size.width + laneUnit, y: .random(in: laneUnit...(size.height - laneUnit)))
        addChild(f)
        glide(f)
    }

    private func emitHazard() {
        let kind: Floater.Role = (world.id >= 7 && Bool.random()) ? .blackhole : .meteor
        let f = Floater(role: kind, size: laneUnit * 1.1)
        f.position = CGPoint(x: size.width + laneUnit, y: .random(in: laneUnit...(size.height - laneUnit)))
        addChild(f)
        glide(f, speedup: 1.15)
    }

    private func glide(_ node: Floater, speedup: CGFloat = 1) {
        let dist = size.width + laneUnit * 2
        let dur = TimeInterval(dist / (210 * speedup))
        node.run(.sequence([.moveBy(x: -dist, y: 0, duration: dur), .removeFromParent()]),
                 withKey: "drift")
    }

    var laneUnit: CGFloat { min(size.width, size.height) * 0.08 }

    /// Weighted pick of what the next collectible is.
    private func rollPickup() -> Pickup {
        let r = Int.random(in: 0..<100)
        switch r {
        case 0..<30: return .coin
        case 30..<48: return .fuelCan
        case 48..<58: return .energy
        case 58..<66: return .superFuel
        case 66..<72: return .shield
        case 72..<78: return .magnet
        case 78..<84: return .doubler
        case 84..<89: return .booster
        case 89..<93: return .chest
        default:
            // rare matter, drawn from this world's drop table
            let m = world.drops.randomElement() ?? .shard
            return .matter(m)
        }
    }

    // MARK: magnet

    func sweepMagnet() {
        let reach = laneUnit * 4.5
        let target = rocket.position
        for case let f as Floater in children where !f.captured {
            if case .pickup = f.role {
                if f.position.distance(to: target) < reach {
                    f.lurch(to: target)
                }
            }
        }
    }

    // MARK: contacts

    func didBegin(_ contact: SKPhysicsContact) {
        let nodes = [contact.bodyA.node, contact.bodyB.node]
        guard let floater = nodes.compactMap({ $0 as? Floater }).first,
              let rocketNode = nodes.compactMap({ $0 as? ThrustBody }).first else { return }
        resolve(floater, at: rocketNode.position)
    }

    private func resolve(_ f: Floater, at point: CGPoint) {
        switch f.role {
        case .meteor, .blackhole:
            if flow.isInvincible() {
                burst(at: f.position, tint: Palette.shield); f.removeFromParent()
            } else {
                Buzz.alarm(); flow.struck()
            }
        case .pickup(let p):
            guard !f.captured else { return }
            f.capture()
            grant(p, at: f.position)
            burst(at: f.position, tint: p.tint)
            f.removeFromParent()
        }
    }

    private func grant(_ p: Pickup, at point: CGPoint) {
        flow.popup.relay((p, point))
        flow.addScore(p.bounty)
        switch p {
        case .coin, .energy: flow.bumpEnergy(0.04)
        case .fuelCan: flow.refuel(0.20)
        case .superFuel: flow.refuel(0.50)
        case .shield: flow.ignite(.shield); rocketShield(true)
        case .magnet: flow.ignite(.magnet)
        case .doubler: flow.ignite(.doubler)
        case .booster: flow.ignite(.booster)
        case .chest: openChest()
        case .matter(let m): flow.collect(m)
        }
        Buzz.tap()
    }

    private func openChest() {
        let roll = Int.random(in: 0..<4)
        switch roll {
        case 0: flow.refuel(0.4)
        case 1: flow.addScore(200)
        case 2: flow.ignite(.shield); rocketShield(true)
        default: flow.collect(world.drops.randomElement() ?? .shard)
        }
    }

    private func rocketShield(_ on: Bool) {
        rocket.flashShield(on)
    }

    // MARK: streak bonus — every 30s aloft

    func awardStreakIfDue() {
        if flow.live.energy >= 1 {
            flow.bumpEnergy(-1)
            flow.addScore(150)
            flow.broadcast()
        }
    }

    private func burst(at p: CGPoint, tint: UIColor) {
        let n = SKEmitterNode()
        n.particleTexture = FlightStage.sparkTexture
        n.position = p
        n.numParticlesToEmit = 14
        n.particleLifetime = 0.5
        n.particleBirthRate = 800
        n.particleSpeed = 140
        n.particleSpeedRange = 60
        n.emissionAngleRange = .pi * 2
        n.particleScale = 0.4
        n.particleScaleSpeed = -0.8
        n.particleColor = tint
        n.particleColorBlendFactor = 1
        n.particleBlendMode = .add
        n.particleAlphaSpeed = -1.6
        addChild(n)
        n.run(.sequence([.wait(forDuration: 0.6), .removeFromParent()]))
    }

    func addHaze() {
        let fog = SKSpriteNode(color: Palette.voidLow.withAlphaComponent(world.climate.haze),
                               size: size)
        fog.position = CGPoint(x: size.width/2, y: size.height/2)
        fog.zPosition = 50
        fog.blendMode = .alpha
        fog.alpha = world.climate.haze
        addChild(fog)
    }
}

extension CGPoint {
    func distance(to o: CGPoint) -> CGFloat { hypot(x - o.x, y - o.y) }
}
