//
//  Holdings.swift
//  RocketJump
//
//  The pilot's persistent belongings, bundled so the shell can hand one
//  reference to whichever surface needs it. This is plain dependency
//  injection — created once at launch and passed down, never reached for
//  through a global accessor.
//

import Foundation

/// What a finished flight produced. Folded into Holdings to advance the career.
struct RunReport {
    let score: Int
    let km: Int
    let seconds: Int
    let fuelGrabbed: Int
    let matter: [Matter: Int]
    let worldId: Int
}

final class Holdings {

    let career = ProgressVault()
    let satchel = ResourceSatchel()
    let ranks = RankArchive()
    let quests = QuestLog()
    let accolades = AccoladeRegistry()

    /// Worlds the pilot could open right now given current totals.
    func unlockableNow() -> [World] {
        PlanetCodex.worlds.filter {
            !career.snap.unlockedWorlds.contains($0.id) &&
            $0.gate.cleared(career.snap, satchel)
        }
    }

    /// Fold a finished run into every store, then surface what changed.
    @discardableResult
    func absorb(_ r: RunReport) -> Aftermath {
        for (m, n) in r.matter where n > 0 { satchel.deposit(m, n) }

        career.mutate { c in
            c.runs += 1
            c.topScore = max(c.topScore, r.score)
            c.farthestKm = max(c.farthestKm, r.km)
            c.longestLife = max(c.longestLife, r.seconds)
            c.lifetimeFuel += r.fuelGrabbed
            c.lifetimeKm += r.km
            c.lastWorld = r.worldId
        }

        ranks.enter(Standing(score: r.score, km: r.km, seconds: r.seconds,
                             worldId: r.worldId, stamp: Date()))

        // Opening worlds may itself satisfy further gates, so loop until stable.
        var opened: [World] = []
        while true {
            let ready = unlockableNow()
            if ready.isEmpty { break }
            career.mutate { c in ready.forEach { c.unlockedWorlds.insert($0.id) } }
            opened.append(contentsOf: ready)
        }

        let medals = accolades.reconcile(career.snap)
        return Aftermath(report: r, opened: opened, medals: medals,
                         isBestScore: r.score >= career.snap.topScore && r.score > 0)
    }
}

/// The digested outcome a debrief screen reads from.
struct Aftermath {
    let report: RunReport
    let opened: [World]
    let medals: [Accolade]
    let isBestScore: Bool
}
