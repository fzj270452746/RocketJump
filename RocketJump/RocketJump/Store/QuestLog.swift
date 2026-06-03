//
//  QuestLog.swift
//  RocketJump
//
//  Permanent quests (the brief turned daily into forever). Progress is a
//  set of claimed IDs in UserDefaults; the definitions live in code and are
//  evaluated lazily against career stats + inventory.
//

import Foundation

struct Quest {
    let id: String
    let title: String
    let detail: String
    let reward: String
    let symbol: String
    /// Returns 0..1 completion against current state.
    let gauge: (Progress, ResourceSatchel) -> Double
}

enum QuestBoard {

    static let all: [Quest] = [
        Quest(id: "rookie", title: "First Light", detail: "Fly 100 km in your career.",
              reward: "Fuel cache", symbol: "flag.checkered",
              gauge: { p, _ in clamp(Double(p.lifetimeKm) / 100) }),

        Quest(id: "toTheMoon", title: "Moonshot", detail: "Unlock the Moon.",
              reward: "Shield charge", symbol: Glyph.shield,
              gauge: { p, _ in p.unlockedWorlds.contains(1) ? 1 : 0 }),

        Quest(id: "tanker", title: "Tanker", detail: "Scoop 100 fuel, lifetime.",
              reward: "Magnet charge", symbol: Glyph.magnet,
              gauge: { p, _ in clamp(Double(p.lifetimeFuel) / 100) }),

        Quest(id: "highRoller", title: "High Roller", detail: "Score 5,000 in one run.",
              reward: "Booster charge", symbol: Glyph.rocket,
              gauge: { p, _ in clamp(Double(p.topScore) / 5000) }),

        Quest(id: "prospector", title: "Prospector", detail: "Bank 25 Star Shards.",
              reward: "Double points", symbol: Matter.shard.symbol,
              gauge: { _, s in clamp(Double(s.count(of: .shard)) / 25) }),
    ]

    private static func clamp(_ v: Double) -> Double { min(1, max(0, v)) }
}

/// Tracks which quest rewards the pilot has acknowledged.
final class QuestLog {
    private var claimed: Set<String>
    private let key = "rj.quests.claimed"

    init() {
        claimed = Set(UserDefaults.standard.stringArray(forKey: key) ?? [])
    }

    func isClaimed(_ id: String) -> Bool { claimed.contains(id) }

    func claim(_ id: String) {
        claimed.insert(id)
        UserDefaults.standard.set(Array(claimed), forKey: key)
    }
}
