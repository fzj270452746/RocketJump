//
//  Floater.swift
//  RocketJump
//
//  Anything that streams in from the right edge: pickups and hazards alike.
//  Each carries its kind so the scene knows what to do on contact. Built
//  from an SF Symbol on a soft disc for pickups, or a rough rock for hazards.
//

import SpriteKit

final class Floater: SKNode {

    enum Role { case pickup(Pickup), meteor, blackhole }
    let role: Role
    private(set) var captured = false

    init(role: Role, size: CGFloat) {
        self.role = role
        super.init()
        switch role {
        case .pickup(let p): buildPickup(p, size)
        case .meteor: buildMeteor(size)
        case .blackhole: buildHole(size)
        }
        physicsBody = makeBody(size)
    }

    required init?(coder: NSCoder) { fatalError() }

    func capture() { captured = true; physicsBody = nil }

    /// Slide toward a point (magnet pull) over a short time.
    func lurch(to point: CGPoint) {
        guard !captured else { return }
        removeAction(forKey: "drift")
        run(.move(to: point, duration: 0.25))
    }

    private func makeBody(_ size: CGFloat) -> SKPhysicsBody {
        let b = SKPhysicsBody(circleOfRadius: size * 0.5)
        b.affectedByGravity = false
        b.collisionBitMask = 0
        switch role {
        case .pickup: b.categoryBitMask = Mask.pickup
        case .meteor, .blackhole: b.categoryBitMask = Mask.hazard
        }
        b.contactTestBitMask = Mask.rocket
        return b
    }

    private func buildPickup(_ p: Pickup, _ size: CGFloat) {
        let disc = SKShapeNode(circleOfRadius: size * 0.6)
        disc.fillColor = p.tint.withAlphaComponent(0.18)
        disc.strokeColor = p.tint.withAlphaComponent(0.7)
        disc.lineWidth = 2
        disc.glowWidth = 3
        addChild(disc)
        addChild(symbolSprite(p.symbol, p.tint, size))
        disc.run(.repeatForever(.sequence([
            .scale(to: 1.12, duration: 0.7), .scale(to: 1.0, duration: 0.7)])))
    }

    private func buildMeteor(_ size: CGFloat) {
        let rock = symbolSprite(Glyph.meteor, Palette.inkSoft, size * 1.15)
        rock.color = Palette.rgb(150, 120, 110)
        rock.colorBlendFactor = 0.6
        addChild(rock)
        run(.repeatForever(.rotate(byAngle: .pi * 2, duration: .random(in: 3...6))))
    }

    private func buildHole(_ size: CGFloat) {
        let ring = symbolSprite(Glyph.blackhole, Palette.doubler, size * 1.3)
        addChild(ring)
        run(.repeatForever(.rotate(byAngle: .pi * 2, duration: 2.4)))
        let pull = SKShapeNode(circleOfRadius: size * 0.9)
        pull.strokeColor = Palette.doubler.withAlphaComponent(0.3)
        pull.lineWidth = 1
        addChild(pull)
    }

    private func symbolSprite(_ name: String, _ tint: UIColor, _ size: CGFloat) -> SKSpriteNode {
        let cfg = UIImage.SymbolConfiguration(pointSize: size, weight: .semibold)
        let img = (UIImage(systemName: name, withConfiguration: cfg)
                   ?? UIImage(systemName: "circle.fill", withConfiguration: cfg))!
            .withTintColor(tint, renderingMode: .alwaysOriginal)
        let s = SKSpriteNode(texture: SKTexture(image: img))
        s.size = CGSize(width: size, height: size)
        return s
    }
}
