//
//  Resources.swift
//  RocketJump
//
//  The collectible economy. Two distinct kinds on purpose:
//   - Spendable currency that flows every run (fuel cans, coins, energy).
//   - Rare cosmic matter gated to certain biomes, used to unlock maps.
//

import UIKit

/// Rare matter harvested from specific biomes. Drives map unlocks.
enum Matter: String, CaseIterable, Codable {
    case shard      // 星际碎片
    case lunarOre   // 月球矿石
    case venusGem   // 金星晶体
    case jupiterCore // 木星能量核
    case voidCore   // 黑洞核心

    var title: String {
        switch self {
        case .shard: return "Star Shard"
        case .lunarOre: return "Lunar Ore"
        case .venusGem: return "Venus Crystal"
        case .jupiterCore: return "Jovian Core"
        case .voidCore: return "Void Core"
        }
    }

    var symbol: String {
        switch self {
        case .shard: return "sparkles"
        case .lunarOre: return "moon.stars.fill"
        case .venusGem: return "diamond.fill"
        case .jupiterCore: return "atom"
        case .voidCore: return "circle.dashed.inset.filled"
        }
    }

    var tint: UIColor {
        switch self {
        case .shard: return Palette.energy
        case .lunarOre: return Palette.inkSoft
        case .venusGem: return Palette.doubler
        case .jupiterCore: return Palette.thrust
        case .voidCore: return Palette.peril
        }
    }
}

/// Things that fall toward the rocket and can be scooped up mid-flight.
enum Pickup {
    case fuelCan       // +20% fuel
    case superFuel     // +50% fuel
    case coin          // score
    case energy        // score, feeds energy meter
    case shield        // power-up
    case magnet        // power-up
    case doubler       // power-up
    case booster       // power-up (rocket thruster)
    case chest         // mystery
    case matter(Matter)

    var symbol: String {
        switch self {
        case .fuelCan, .superFuel: return Glyph.fuel
        case .coin: return Glyph.coin
        case .energy: return Glyph.energy
        case .shield: return Glyph.shield
        case .magnet: return Glyph.magnet
        case .doubler: return Glyph.doubler
        case .booster: return Glyph.rocket
        case .chest: return Glyph.chest
        case .matter(let m): return m.symbol
        }
    }

    var tint: UIColor {
        switch self {
        case .fuelCan: return Palette.fuel
        case .superFuel: return Palette.shield
        case .coin: return Palette.coin
        case .energy: return Palette.energy
        case .shield: return Palette.shield
        case .magnet: return Palette.magnet
        case .doubler: return Palette.doubler
        case .booster: return Palette.thrust
        case .chest: return Palette.coin
        case .matter(let m): return m.tint
        }
    }

    /// Score awarded on contact (power-ups score nothing; fuel/coins do).
    var bounty: Int {
        switch self {
        case .coin: return 10
        case .energy: return 25
        case .fuelCan, .superFuel: return 10
        case .matter: return 80
        default: return 50
        }
    }
}

/// Active power-up bands with their durations (seconds) from the brief.
enum Boost: CaseIterable {
    case shield, magnet, doubler, booster

    var span: TimeInterval {
        switch self {
        case .shield: return 10
        case .magnet: return 15
        case .doubler: return 20
        case .booster: return 8
        }
    }

    var symbol: String {
        switch self {
        case .shield: return Glyph.shield
        case .magnet: return Glyph.magnet
        case .doubler: return Glyph.doubler
        case .booster: return Glyph.rocket
        }
    }

    var tint: UIColor {
        switch self {
        case .shield: return Palette.shield
        case .magnet: return Palette.magnet
        case .doubler: return Palette.doubler
        case .booster: return Palette.thrust
        }
    }
}
