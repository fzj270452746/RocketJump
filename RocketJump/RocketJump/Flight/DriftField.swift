//
//  DriftField.swift
//  RocketJump
//
//  Parallax scenery — three layers of distant matter sliding at different
//  speeds to fake depth behind the action. A planet disc hangs in the far
//  layer, tinted to the current world.
//

import SpriteKit

final class DriftField: SKNode {

    private let near = SKNode()
    private let mid = SKNode()
    private let far = SKNode()
    private let span: CGSize
    private var wobble: CGFloat = 0

    init(size: CGSize, world: World) {
        span = size
        super.init()
        zPosition = -10
        addChild(far); addChild(mid); addChild(near)
        seed(into: far, count: 5, sizeRange: 1.5...3, alpha: 0.25)
        seed(into: mid, count: 8, sizeRange: 2...4, alpha: 0.45)
        seed(into: near, count: 6, sizeRange: 3...6, alpha: 0.7)
        hangPlanet(world)
    }

    required init?(coder: NSCoder) { fatalError() }

    func advance(_ dt: TimeInterval, jitter: Bool) {
        let gust: CGFloat = jitter ? CGFloat.random(in: 0.6...1.4) : 1
        slide(far, by: 16 * gust * CGFloat(dt))
        slide(mid, by: 42 * gust * CGFloat(dt))
        slide(near, by: 84 * gust * CGFloat(dt))
    }

    private func slide(_ layer: SKNode, by dx: CGFloat) {
        for dot in layer.children {
            dot.position.x -= dx
            if dot.position.x < -10 { dot.position.x = span.width + 10
                dot.position.y = .random(in: 0...span.height) }
        }
    }

    private func seed(into layer: SKNode, count: Int, sizeRange: ClosedRange<CGFloat>, alpha: CGFloat) {
        for _ in 0..<count {
            let r = CGFloat.random(in: sizeRange)
            let dot = SKShapeNode(circleOfRadius: r)
            dot.fillColor = UIColor.white.withAlphaComponent(alpha)
            dot.strokeColor = .clear
            dot.position = CGPoint(x: .random(in: 0...span.width), y: .random(in: 0...span.height))
            layer.addChild(dot)
        }
    }

    private func hangPlanet(_ world: World) {
        let d = span.width * 0.5
        let planet = SKShapeNode(circleOfRadius: d / 2)
        planet.fillColor = world.orb.withAlphaComponent(0.5)
        planet.strokeColor = world.orb.withAlphaComponent(0.8)
        planet.lineWidth = 2
        planet.glowWidth = 8
        planet.position = CGPoint(x: span.width * 0.78, y: span.height * 0.82)
        planet.alpha = 0.55
        far.addChild(planet)
        planet.run(.repeatForever(.sequence([
            .moveBy(x: 0, y: 12, duration: 4), .moveBy(x: 0, y: -12, duration: 4)])))
    }
}
