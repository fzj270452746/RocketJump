//
//  PlanetCodex.swift
//  RocketJump
//
//  The ten worlds, their unlock gates, and the physics each one bends.
//  Gates are expressed as a small rule list evaluated against career totals,
//  so adding a world is data, not control flow.
//

import UIKit

/// A measurable career stat that an unlock rule can test.
enum Tally {
    case distance       // total km flown across all runs
    case score          // best single-run score? -> we use lifetime peak
    case fuelTaken      // fuel pickups collected, lifetime
    case matter(Matter) // count of a rare resource

    func reading(_ p: Progress, _ sack: ResourceSatchel) -> Int {
        switch self {
        case .distance: return p.farthestKm
        case .score: return p.topScore
        case .fuelTaken: return p.lifetimeFuel
        case .matter(let m): return sack.count(of: m)
        }
    }
}

/// "need at least N of this tally". A gate may require all rules, or any K of them.
struct Gate {
    let rules: [(Tally, Int)]
    let needAtLeast: Int   // how many rules must pass (K-of-N)

    static func all(_ rules: [(Tally, Int)]) -> Gate { Gate(rules: rules, needAtLeast: rules.count) }
    static func any(_ k: Int, _ rules: [(Tally, Int)]) -> Gate { Gate(rules: rules, needAtLeast: k) }
    static let open = Gate(rules: [], needAtLeast: 0)

    func cleared(_ p: Progress, _ sack: ResourceSatchel) -> Bool {
        let passed = rules.filter { $0.0.reading(p, sack) >= $0.1 }.count
        return passed >= needAtLeast
    }
}

/// How a world rewrites the flight feel.
struct Climate {
    var gravityScale: CGFloat = 1.0     // <1 floaty, >1 heavy
    var fuelBurn: CGFloat = 1.0         // multiplier on drain
    var hazardRate: CGFloat = 1.0       // spawn frequency multiplier
    var driftWind: CGFloat = 0.0        // constant horizontal nudge
    var haze: CGFloat = 0.0             // 0..1 vignette/fog intensity
    var jitter: Bool = false            // random slow-downs / gusts
}

struct World {
    let id: Int
    let name: String
    let blurb: String
    let skyTop: UIColor
    let skyLow: UIColor
    let orb: UIColor          // the planet disc colour in the atlas
    let gate: Gate
    let climate: Climate
    let drops: [Matter]       // rare matter that can appear here
}

/// The static atlas. A free-standing list, not a manager.
enum PlanetCodex {

    static let worlds: [World] = [
        World(id: 0, name: "Earth Orbit",
              blurb: "Calm skies. Learn the burn.",
              skyTop: Palette.rgb(18, 28, 64), skyLow: Palette.rgb(40, 60, 120),
              orb: Palette.rgb(72, 142, 255), gate: .open,
              climate: Climate(hazardRate: 0.7),
              drops: [.shard]),

        World(id: 1, name: "The Moon",
              blurb: "Low gravity. Everything floats higher.",
              skyTop: Palette.rgb(22, 24, 38), skyLow: Palette.rgb(70, 74, 96),
              orb: Palette.rgb(208, 212, 224),
              gate: .any(2, [(.distance, 500), (.score, 5000), (.fuelTaken, 50)]),
              climate: Climate(gravityScale: 0.62, hazardRate: 0.85),
              drops: [.shard, .lunarOre]),

        World(id: 2, name: "Mars",
              blurb: "Dust storms thin your sightline.",
              skyTop: Palette.rgb(52, 22, 18), skyLow: Palette.rgb(150, 64, 40),
              orb: Palette.rgb(214, 102, 68),
              gate: .all([(.distance, 1500), (.matter(.lunarOre), 30)]),
              climate: Climate(hazardRate: 1.1, haze: 0.35, jitter: true),
              drops: [.shard, .lunarOre]),

        World(id: 3, name: "Venus",
              blurb: "Searing air drinks your fuel.",
              skyTop: Palette.rgb(70, 50, 14), skyLow: Palette.rgb(196, 150, 44),
              orb: Palette.rgb(226, 188, 96),
              gate: .all([(.score, 10000), (.fuelTaken, 80), (.matter(.venusGem), 20)]),
              climate: Climate(fuelBurn: 1.45, hazardRate: 1.15, haze: 0.25),
              drops: [.venusGem, .shard]),

        World(id: 4, name: "Jupiter",
              blurb: "Crosswinds shove the hull sideways.",
              skyTop: Palette.rgb(48, 30, 20), skyLow: Palette.rgb(170, 120, 70),
              orb: Palette.rgb(206, 158, 110),
              gate: .all([(.distance, 5000), (.score, 25000), (.matter(.jupiterCore), 40)]),
              climate: Climate(hazardRate: 1.2, driftWind: 26, jitter: true),
              drops: [.jupiterCore, .shard]),

        World(id: 5, name: "Saturn",
              blurb: "Ring debris crowds the lane.",
              skyTop: Palette.rgb(40, 38, 22), skyLow: Palette.rgb(150, 138, 80),
              orb: Palette.rgb(208, 196, 132),
              gate: .all([(.distance, 8000), (.matter(.shard), 100)]),
              climate: Climate(hazardRate: 1.5),
              drops: [.shard, .jupiterCore]),

        World(id: 6, name: "Uranus",
              blurb: "Frozen air dulls your touch.",
              skyTop: Palette.rgb(16, 44, 52), skyLow: Palette.rgb(80, 168, 180),
              orb: Palette.rgb(150, 214, 220),
              gate: .all([(.score, 50000), (.fuelTaken, 200)]),
              climate: Climate(gravityScale: 1.12, hazardRate: 1.35),
              drops: [.shard, .venusGem]),

        World(id: 7, name: "Neptune",
              blurb: "Glacial storms steal momentum.",
              skyTop: Palette.rgb(14, 22, 60), skyLow: Palette.rgb(52, 70, 168),
              orb: Palette.rgb(88, 110, 224),
              gate: .all([(.distance, 12000), (.matter(.jupiterCore), 80)]),
              climate: Climate(hazardRate: 1.4, jitter: true),
              drops: [.jupiterCore, .voidCore]),

        World(id: 8, name: "Pluto",
              blurb: "The cold edge. Mistakes are final.",
              skyTop: Palette.rgb(20, 20, 34), skyLow: Palette.rgb(64, 60, 92),
              orb: Palette.rgb(150, 144, 170),
              gate: .all([(.distance, 20000), (.matter(.shard), 150)]),
              climate: Climate(gravityScale: 1.18, hazardRate: 1.6),
              drops: [.shard, .voidCore]),

        World(id: 9, name: "Black Hole Edge",
              blurb: "Gravity lies. The lane rewrites itself.",
              skyTop: Palette.rgb(4, 2, 12), skyLow: Palette.rgb(40, 8, 60),
              orb: Palette.rgb(120, 40, 200),
              gate: .all([(.distance, 30000), (.score, 100000),
                          (.matter(.shard), 300), (.matter(.voidCore), 100)]),
              climate: Climate(hazardRate: 1.9, driftWind: 18, haze: 0.2, jitter: true),
              drops: [.voidCore, .shard]),
    ]

    static func world(_ id: Int) -> World { worlds[min(max(id, 0), worlds.count - 1)] }
}
