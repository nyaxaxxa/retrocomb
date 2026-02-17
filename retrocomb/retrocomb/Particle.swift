//
//  Particle.swift
//  retrocomb
//
//  Space Flappy Game - Particle System
//

import SpriteKit

class Particle: SKShapeNode {
    var velocity: CGVector = CGVector.zero
    var lifetime: TimeInterval = 0
    var maxLifetime: TimeInterval = GameConfig.Particle.particleLifetime
    
    init(position: CGPoint, velocity: CGVector, color: SKColor, size: CGFloat = 4) {
        super.init()
        
        self.position = position
        self.velocity = velocity
        
        // Create small circle particle
        let circle = SKShapeNode(circleOfRadius: size)
        circle.fillColor = color
        circle.strokeColor = .clear
        self.path = circle.path
        self.fillColor = color
        self.strokeColor = .clear
        
        // Add glow effect
        self.glowWidth = 2
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(deltaTime: TimeInterval) {
        // Update position
        position.x += velocity.dx
        position.y += velocity.dy
        
        // Apply friction
        velocity.dx *= 0.98
        velocity.dy *= 0.98
        
        // Update lifetime and fade out
        lifetime += deltaTime
        let alpha = CGFloat(1.0 - (lifetime / maxLifetime))
        self.alpha = alpha
    }
    
    var isDead: Bool {
        return lifetime >= maxLifetime
    }
}

// Particle emitter helper
class ParticleEmitter {
    static func createEngineParticles(at position: CGPoint, direction: CGVector, color: SKColor, count: Int = GameConfig.Particle.engineParticleCount) -> [Particle] {
        var particles: [Particle] = []
        
        for _ in 0..<count {
            let angle = CGFloat.random(in: -0.3...0.3)
            let speed = CGFloat.random(in: 2...4)
            
            let dx = direction.dx * speed * cos(angle) - direction.dy * speed * sin(angle)
            let dy = direction.dx * speed * sin(angle) + direction.dy * speed * cos(angle)
            
            let particle = Particle(
                position: position,
                velocity: CGVector(dx: dx, dy: dy),
                color: color,
                size: CGFloat.random(in: 2...4)
            )
            particle.maxLifetime = 0.5
            particles.append(particle)
        }
        
        return particles
    }
    
    static func createExplosion(at position: CGPoint, color: SKColor, count: Int = GameConfig.Particle.explosionParticleCount) -> [Particle] {
        var particles: [Particle] = []
        
        for _ in 0..<count {
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 3...8)
            
            let dx = cos(angle) * speed
            let dy = sin(angle) * speed
            
            let particle = Particle(
                position: position,
                velocity: CGVector(dx: dx, dy: dy),
                color: color,
                size: CGFloat.random(in: 3...6)
            )
            particles.append(particle)
        }
        
        return particles
    }
}
