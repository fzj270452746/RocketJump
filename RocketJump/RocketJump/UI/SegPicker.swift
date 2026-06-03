//
//  SegPicker.swift
//  RocketJump
//
//  A hand-built segmented control with a sliding highlight — replaces the
//  stock UISegmentedControl so the chrome matches the rest of the app.
//

import UIKit

final class SegPicker: UIView {

    var onPick: ((Int) -> Void)?
    private(set) var index = 0
    private var buttons: [UIButton] = []
    private let pill = UIView()

    init(titles: [String]) {
        super.init(frame: .zero)
        backgroundColor = Palette.glass
        layer.cornerRadius = 16
        layer.cornerCurve = .continuous

        pill.backgroundColor = Palette.thrust.withAlphaComponent(0.28)
        pill.layer.cornerRadius = 13
        pill.layer.borderWidth = 1
        pill.layer.borderColor = Palette.thrust.withAlphaComponent(0.6).cgColor
        addSubview(pill)

        for (i, t) in titles.enumerated() {
            let b = UIButton(type: .system)
            b.setTitle(t, for: .normal)
            b.titleLabel?.font = Typeset.display(14, .bold)
            b.tintColor = Palette.ink
            b.tag = i
            b.addTarget(self, action: #selector(pick(_:)), for: .touchUpInside)
            addSubview(b); buttons.append(b)
        }
        heightAnchor.constraint(equalToConstant: 46).isActive = true
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        let w = bounds.width / CGFloat(buttons.count)
        for (i, b) in buttons.enumerated() {
            b.frame = CGRect(x: w * CGFloat(i), y: 0, width: w, height: bounds.height)
        }
        placePill(animated: false)
    }

    @objc private func pick(_ b: UIButton) {
        guard b.tag != index else { return }
        index = b.tag
        Buzz.tap()
        placePill(animated: true)
        onPick?(index)
    }

    private func placePill(animated: Bool) {
        let w = bounds.width / CGFloat(max(buttons.count, 1))
        let frame = CGRect(x: w * CGFloat(index) + 3, y: 3, width: w - 6, height: bounds.height - 6)
        let block = { self.pill.frame = frame }
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8,
                           initialSpringVelocity: 0.5, options: [], animations: block)
        } else { block() }
    }
}
