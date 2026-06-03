//
//  ResourceSatchel.swift
//  RocketJump
//
//  Rare-matter inventory. Deliberately a flat [String: Int] ledger in
//  UserDefaults — a different storage shape from the career snapshot, so the
//  two systems never share a save format.
//

import Foundation

final class ResourceSatchel {

    private var bag: [String: Int]
    private let key = "rj.matter.ledger"

    init() {
        bag = UserDefaults.standard.dictionary(forKey: key) as? [String: Int] ?? [:]
    }

    func count(of m: Matter) -> Int { bag[m.rawValue] ?? 0 }

    func deposit(_ m: Matter, _ n: Int = 1) {
        bag[m.rawValue, default: 0] += n
        UserDefaults.standard.set(bag, forKey: key)
    }

    /// Snapshot for display, in catalogue order.
    var contents: [(Matter, Int)] {
        Matter.allCases.map { ($0, count(of: $0)) }
    }
}
