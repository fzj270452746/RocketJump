//
//  AccoladeRegistry.swift
//  RocketJump
//
//  Achievements. Earned IDs persist as a bare string array under their own
//  key. Evaluation is a pure pass over career state, run after each flight.
//

import Foundation

struct Accolade {
    let id: String
    let title: String
    let detail: String
    let symbol: String
    let earned: (Progress) -> Bool
}

enum AccoladeWall {

    static let all: [Accolade] = [
        Accolade(id: "liftoff", title: "Liftoff", detail: "Complete your first flight.",
                 symbol: Glyph.rocket, earned: { $0.runs >= 1 }),
        Accolade(id: "astronaut", title: "Astronaut", detail: "Fly 1,000 km, lifetime.",
                 symbol: "figure.wave", earned: { $0.lifetimeKm >= 1000 }),
        Accolade(id: "moonwalk", title: "Moon Program", detail: "Unlock the Moon.",
                 symbol: "moon.fill", earned: { $0.unlockedWorlds.contains(1) }),
        Accolade(id: "redPlanet", title: "Mars Explorer", detail: "Unlock Mars.",
                 symbol: "globe.asia.australia.fill", earned: { $0.unlockedWorlds.contains(2) }),
        Accolade(id: "cartographer", title: "Deep-Space Voyager", detail: "Unlock every world.",
                 symbol: "map.fill", earned: { $0.unlockedWorlds.count >= PlanetCodex.worlds.count }),
        Accolade(id: "legend", title: "Galaxy Legend", detail: "Fly 50,000 km, lifetime.",
                 symbol: "crown.fill", earned: { $0.lifetimeKm >= 50000 }),
    ]
}

final class AccoladeRegistry {
    private var won: Set<String>
    private let key = "rj.accolades.won"

    init() {
        won = Set(UserDefaults.standard.stringArray(forKey: key) ?? [])
    }

    func has(_ id: String) -> Bool { won.contains(id) }

    /// Re-evaluate every accolade; returns the ones newly earned this pass.
    func reconcile(_ p: Progress) -> [Accolade] {
        var fresh: [Accolade] = []
        for a in AccoladeWall.all where !won.contains(a.id) && a.earned(p) {
            won.insert(a.id)
            fresh.append(a)
        }
        if !fresh.isEmpty {
            UserDefaults.standard.set(Array(won), forKey: key)
        }
        return fresh
    }
}
