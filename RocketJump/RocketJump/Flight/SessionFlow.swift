//
//  SessionFlow.swift
//  RocketJump
//
//  The flight's state node + live tallies. It owns the beacons the scene and
//  HUD converse over. This is the "state node" the design asks for — not a
//  global manager, just the truth of one flight, born and discarded with it.
//

import UIKit

enum FlightPhase { case priming, flying, grounded }

/// Signals a flight can raise. The HUD listens; the scene raises.
struct FlightPulse {
    var score = 0
    var distanceKm = 0
    var fuel: CGFloat = 1          // 0...1
    var energy: CGFloat = 0        // 0...1, fills the streak bonus
    var boosts: [Boost: TimeInterval] = [:]   // remaining seconds per active boost
}

final class SessionFlow {

    let world: World
    private(set) var phase: FlightPhase = .priming

    // Beacons — the conversation channels for this flight.
    let pulse = Beacon<FlightPulse>()       // HUD refresh
    let popup = Beacon<(Pickup, CGPoint)>() // floating "+N" feedback
    let ended = Beacon<RunReport>()         // flight over

    // Live tallies
    private(set) var live = FlightPulse()
    private var fuelGrabbed = 0
    private var matter: [Matter: Int] = [:]
    private var startedAt = Date()

    init(world: World) {
        self.world = world
        live.fuel = 1
    }

    func begin() {
        phase = .flying
        startedAt = Date()
        pulse.relay(live)
    }

    // MARK: mutation entry points (called by the scene's tick / contacts)

    func addScore(_ n: Int) {
        let mult: Int = live.boosts[.doubler] != nil ? 2 : 1
        live.score += n * mult
    }

    func setDistance(_ km: Int) {
        if km > live.distanceKm {
            live.distanceKm = km
            live.score += 0  // distance counted into score at debrief via report
        }
    }

    func burnFuel(_ amount: CGFloat) {
        guard live.boosts[.booster] == nil else { return } // booster flies free
        live.fuel = max(0, live.fuel - amount * world.climate.fuelBurn)
        if live.fuel <= 0 { conclude() }
    }

    func refuel(_ fraction: CGFloat) {
        live.fuel = min(1, live.fuel + fraction)
        fuelGrabbed += 1
    }

    func bumpEnergy(_ amount: CGFloat) {
        live.energy = min(1, live.energy + amount)
    }

    func collect(_ matterKind: Matter) {
        matter[matterKind, default: 0] += 1
    }

    func ignite(_ boost: Boost) {
        live.boosts[boost] = boost.span
    }

    func hasShield() -> Bool { live.boosts[.shield] != nil }
    func isInvincible() -> Bool { live.boosts[.shield] != nil || live.boosts[.booster] != nil }
    func magnetActive() -> Bool { live.boosts[.magnet] != nil }

    /// Drain active boost timers; drop any that expire. Returns expired list.
    @discardableResult
    func tickBoosts(_ dt: TimeInterval) -> [Boost] {
        var expired: [Boost] = []
        for b in Boost.allCases {
            guard var left = live.boosts[b] else { continue }
            left -= dt
            if left <= 0 { live.boosts[b] = nil; expired.append(b) }
            else { live.boosts[b] = left }
        }
        return expired
    }

    func broadcast() { pulse.relay(live) }

    func struck() {
        guard !isInvincible() else { return }
        conclude()
    }

    /// End the flight once, package the report.
    func conclude() {
        guard phase == .flying else { return }
        phase = .grounded
        let secs = Int(Date().timeIntervalSince(startedAt))
        // Distance contributes 1pt/km; pickups already added their bounties.
        let finalScore = live.score + live.distanceKm
        let report = RunReport(score: finalScore, km: live.distanceKm, seconds: secs,
                               fuelGrabbed: fuelGrabbed, matter: matter, worldId: world.id)
        ended.relay(report)
    }
}
