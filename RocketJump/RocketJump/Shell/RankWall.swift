//
//  RankWall.swift
//  RocketJump
//
//  Local leaderboard. Uses a table view (its own reload-based refresh) and a
//  hand-built segmented control to flip between three boards: best scores,
//  farthest flights, longest survival. No network — these are your own runs.
//

import UIKit

final class RankWall: UIViewController, UITableViewDataSource {

    private let holdings: Holdings
    private let table = UITableView(frame: .zero, style: .plain)
    private var board: [(rank: Int, primary: String, detail: String)] = []
    private let tabs = SegPicker(titles: ["Score", "Distance", "Survival"])

    init(holdings: Holdings) {
        self.holdings = holdings
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Palette.rgb(10, 12, 28)

        let header = PageHeader(title: "Ranks", subtitle: "Your finest flights") { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        header.translatesAutoresizingMaskIntoConstraints = false
        tabs.translatesAutoresizingMaskIntoConstraints = false
        tabs.onPick = { [weak self] _ in self?.rebuild() }

        table.translatesAutoresizingMaskIntoConstraints = false
        table.backgroundColor = .clear
        table.separatorStyle = .none
        table.dataSource = self
        table.rowHeight = 60
        table.register(RankCell.self, forCellReuseIdentifier: "rank")

        [header, tabs, table].forEach { view.addSubview($0) }
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabs.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 6),
            tabs.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            tabs.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            table.topAnchor.constraint(equalTo: tabs.bottomAnchor, constant: 10),
            table.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            table.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            table.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        rebuild()
    }

    private func rebuild() {
        let arc = holdings.ranks
        switch tabs.index {
        case 0:
            board = arc.topBy { $0.score }.enumerated().map {
                ($0.offset + 1, "\($0.element.score.grouped)", "\(PlanetCodex.world($0.element.worldId).name)") }
        case 1:
            board = arc.topBy { $0.km }.enumerated().map {
                ($0.offset + 1, "\($0.element.km) km", "\(PlanetCodex.world($0.element.worldId).name)") }
        default:
            board = arc.topBy { $0.seconds }.enumerated().map {
                ($0.offset + 1, "\($0.element.seconds)s", "\(PlanetCodex.world($0.element.worldId).name)") }
        }
        table.reloadData()
        // soft cascade the rows in
        for cell in table.visibleCells { fade(cell) }
    }

    private func fade(_ cell: UITableViewCell) {
        cell.alpha = 0
        cell.transform = CGAffineTransform(translationX: 20, y: 0)
        UIView.animate(withDuration: 0.4) { cell.alpha = 1; cell.transform = .identity }
    }

    func tableView(_ t: UITableView, numberOfRowsInSection s: Int) -> Int {
        max(board.count, 1)
    }

    func tableView(_ t: UITableView, cellForRowAt ip: IndexPath) -> UITableViewCell {
        let cell = t.dequeueReusableCell(withIdentifier: "rank", for: ip) as! RankCell
        if board.isEmpty {
            cell.showEmpty("No flights logged yet")
        } else {
            let row = board[ip.row]
            cell.fill(rank: row.rank, primary: row.primary, detail: row.detail)
        }
        return cell
    }
}
