//
//  RankArchive.swift
//  RocketJump
//
//  Local leaderboard. Stored as a JSON file in the Documents directory — a
//  third, file-based persistence shape distinct from the UserDefaults stores.
//  Keeps three independent boards: best scores, best distances, best survival.
//

import Foundation

struct Standing: Codable {
    let score: Int
    let km: Int
    let seconds: Int
    let worldId: Int
    let stamp: Date
}

final class RankArchive {

    private(set) var entries: [Standing] = []
    private let url: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        url = docs.appendingPathComponent("standings.json")
        load()
    }

    func enter(_ s: Standing) {
        entries.append(s)
        // keep the archive bounded
        if entries.count > 60 {
            entries = Array(entries.sorted { $0.score > $1.score }.prefix(60))
        }
        save()
    }

    func topBy(_ field: (Standing) -> Int, limit: Int = 8) -> [Standing] {
        entries.sorted { field($0) > field($1) }.prefix(limit).map { $0 }
    }

    private func load() {
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Standing].self, from: data) else { return }
        entries = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
