//
//  ProgressVault.swift
//  RocketJump
//
//  Career progress as a Codable snapshot stored as one JSON blob in
//  UserDefaults. Reads are cheap; we persist on meaningful change only.
//

import Foundation

/// Lifetime career figures + the set of worlds the pilot has opened.
struct Progress: Codable {
    var topScore = 0
    var farthestKm = 0
    var longestLife = 0           // seconds survived, best run
    var lifetimeFuel = 0          // fuel pickups ever grabbed
    var lifetimeKm = 0
    var runs = 0
    var unlockedWorlds: Set<Int> = [0]
    var lastWorld = 0
}

/// Owns the career snapshot. A plain object the shell hands around — no
/// global access point.
final class ProgressVault {

    private(set) var snap: Progress
    private let key = "rj.career.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(Progress.self, from: data) {
            snap = decoded
        } else {
            snap = Progress()
        }
    }

    func mutate(_ change: (inout Progress) -> Void) {
        change(&snap)
        flush()
    }

    private func flush() {
        if let data = try? JSONEncoder().encode(snap) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
