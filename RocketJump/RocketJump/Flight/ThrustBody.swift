//
//  ThrustBody.swift
//  RocketJump
//
//  The rocket node. A physics body the player nudges upward with taps; a
//  flame plume and a tilt that reads the vertical velocity. Drawn from a
//  rocket.fill symbol rendered into a texture so it stays crisp at scale.
//

import SpriteKit

enum Mask {
    static let rocket: UInt32 = 0x1 << 0
    static let pickup: UInt32 = 0x1 << 1
    static let hazard: UInt32 = 0x1 << 2
}

final class ThrustBody: SKNode {

    private let hull = SKSpriteNode()
    private let plume = SKEmitterNode()
    private var tilt: CGFloat = 0

    let radius: CGFloat

    init(diameter: CGFloat, tint: UIColor) {
        radius = diameter / 2
        super.init()

        hull.texture = ThrustBody.bake(diameter: diameter, tint: tint)
        hull.size = CGSize(width: diameter, height: diameter)
        hull.zRotation = -.pi / 12
        addChild(hull)

        configurePlume()
        addChild(plume)

        let body = SKPhysicsBody(circleOfRadius: radius * 0.7)
        body.categoryBitMask = Mask.rocket
        body.contactTestBitMask = Mask.pickup | Mask.hazard
        body.collisionBitMask = 0
        body.allowsRotation = false
        // The stage moves the rocket by setting position directly, so the body
        // is non-dynamic: the engine never integrates it, but contact tests
        // against pickups and hazards still fire.
        body.isDynamic = false
        physicsBody = body
    }

    required init?(coder: NSCoder) { fatalError() }

    /// Visual kick for a tap — flame surge + a quick squash. The stage owns the
    /// actual vertical motion (in screen points), so this touches no physics.
    func flap() {
        plume.particleBirthRate = 520
        let kick = SKAction.sequence([
            .scale(to: 1.12, duration: 0.08),
            .scale(to: 1.0, duration: 0.16),
        ])
        hull.run(kick)
    }

    func easeFlame() { plume.particleBirthRate = 180 }

    /// Lean the hull toward the direction of travel each frame.
    func lean(toVelocity vy: CGFloat) {
        let want = max(-0.5, min(0.5, vy / 1400))
        tilt += (want - tilt) * 0.16
        hull.zRotation = -.pi / 12 + tilt
    }

    func flashShield(_ on: Bool) {
        if on, childNode(withName: "halo") == nil {
            let halo = SKShapeNode(circleOfRadius: radius * 1.3)
            halo.name = "halo"
            halo.strokeColor = Palette.shield
            halo.lineWidth = 3
            halo.glowWidth = 6
            halo.fillColor = Palette.shield.withAlphaComponent(0.08)
            halo.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.4, duration: 0.6), .fadeAlpha(to: 1, duration: 0.6)])))
            insertChild(halo, at: 0)
        } else if !on {
            childNode(withName: "halo")?.removeFromParent()
        }
    }

    private func configurePlume() {
        plume.particleTexture = ThrustBody.spark()
        plume.particleBirthRate = 180
        plume.particleLifetime = 0.4
        plume.particleLifetimeRange = 0.2
        plume.particlePositionRange = CGVector(dx: radius * 0.4, dy: 2)
        plume.emissionAngle = -.pi / 2
        plume.emissionAngleRange = 0.5
        plume.particleSpeed = 220
        plume.particleSpeedRange = 80
        plume.particleAlpha = 0.9
        plume.particleAlphaSpeed = -2
        plume.particleScale = 0.5
        plume.particleScaleRange = 0.3
        plume.particleScaleSpeed = -0.8
        plume.particleColor = Palette.thrust
        plume.particleColorBlendFactor = 1
        plume.particleBlendMode = .add
        plume.position = CGPoint(x: 0, y: -radius * 0.9)
    }

    // MARK: textures

    private static func bake(diameter: CGFloat, tint: UIColor) -> SKTexture {
        let cfg = UIImage.SymbolConfiguration(pointSize: diameter * 0.9, weight: .bold)
        let img = (UIImage(systemName: Glyph.rocket, withConfiguration: cfg)
                   ?? UIImage(systemName: "paperplane.fill", withConfiguration: cfg))!
            .withTintColor(tint, renderingMode: .alwaysOriginal)
        return SKTexture(image: img)
    }

    private static func spark() -> SKTexture {
        let s: CGFloat = 16
        let r = UIGraphicsImageRenderer(size: CGSize(width: s, height: s))
        let img = r.image { ctx in
            let c = ctx.cgContext
            let colors = [UIColor.white.cgColor, UIColor.white.withAlphaComponent(0).cgColor]
            let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                  colors: colors as CFArray, locations: [0, 1])!
            c.drawRadialGradient(grad, startCenter: CGPoint(x: s/2, y: s/2), startRadius: 0,
                                 endCenter: CGPoint(x: s/2, y: s/2), endRadius: s/2,
                                 options: [])
        }
        return SKTexture(image: img)
    }
}
