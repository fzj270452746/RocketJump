//
//  AccoladeGallery.swift
//  RocketJump
//
//  Achievements as a two-column grid (UICollectionView — yet another layout
//  engine, distinct from the lists and stacks elsewhere). Earned tiles glow;
//  locked ones sit dim with their criterion.
//

import UIKit

final class AccoladeGallery: UIViewController, UICollectionViewDataSource {

    private let holdings: Holdings
    private var grid: UICollectionView!

    init(holdings: Holdings) {
        self.holdings = holdings
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Palette.rgb(12, 14, 30)

        let header = PageHeader(title: "Medals", subtitle: "Marks of the voyage") { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        header.translatesAutoresizingMaskIntoConstraints = false

        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 14
        layout.minimumLineSpacing = 14
        layout.sectionInset = UIEdgeInsets(top: 8, left: 20, bottom: 28, right: 20)
        grid = UICollectionView(frame: .zero, collectionViewLayout: layout)
        grid.backgroundColor = .clear
        grid.dataSource = self
        grid.register(MedalTile.self, forCellWithReuseIdentifier: "medal")
        grid.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(header); view.addSubview(grid)
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            grid.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 8),
            grid.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            grid.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            grid.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if let l = grid.collectionViewLayout as? UICollectionViewFlowLayout {
            let usable = view.bounds.width - 40 - 14
            l.itemSize = CGSize(width: usable / 2, height: 150)
        }
    }

    func collectionView(_ c: UICollectionView, numberOfItemsInSection s: Int) -> Int {
        AccoladeWall.all.count
    }

    func collectionView(_ c: UICollectionView, cellForItemAt ip: IndexPath) -> UICollectionViewCell {
        let cell = c.dequeueReusableCell(withReuseIdentifier: "medal", for: ip) as! MedalTile
        let a = AccoladeWall.all[ip.item]
        cell.fill(a, earned: holdings.accolades.has(a.id))
        return cell
    }
}
