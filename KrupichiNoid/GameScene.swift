import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // Настройка физических категорий (bitmask)
    
    struct PhysicsCategory {
        static let none : UInt32 = 0
        static let ball : UInt32 = 0x1 << 0
        static let paddle : UInt32 = 0x1 << 1
        static let capsule : UInt32 = 0x1 << 2
        static let border : UInt32 = 0x1 << 3
        
    }
    
    
    
    var burger: SKSpriteNode!
    var fatman: SKSpriteNode!
    var capsuleLayer: SKNode! // Контейнер для кирпичей (капсул)
    
    override func didMove(to view: SKView) {

        physicsWorld.contactDelegate = self
        
        
        backgroundColor = .black
        
        // Платформа (толстяк) — внизу экрана, учитываем высоту и небольшой отступ
        fatman = SKSpriteNode(imageNamed: "fatman")
        fatman.size = CGSize(width: 150, height: 90)
        fatman.position = CGPoint(x: frame.midX,
                                  y: fatman.size.height / 2 + 20)  // 20 пунктов от низа
        fatman.zPosition = 3
        addChild(fatman)
        
        // Шар (бургер) — чуть выше платформы
        burger = SKSpriteNode(imageNamed: "burger")
        burger.size = CGSize(width: 30, height: 30)
        burger.position = CGPoint(x: frame.midX,
                                  y: fatman.position.y + fatman.size.height / 2 + burger.size.height / 2 + 10)
        burger.zPosition = 4
        addChild(burger)
        
        // Контейнер для кирпичей (капсул) и вызов создания капсул
        capsuleLayer = SKNode()
        capsuleLayer.zPosition = 2
        addChild(capsuleLayer)
        
        // границы сцены
        
        
        let borderPath = CGMutablePath()
        borderPath.move(to: CGPoint(x: frame.minX, y: frame.minY))
        borderPath.addLine(to: CGPoint(x: frame.minX, y: frame.maxY))
        borderPath.addLine(to: CGPoint(x: frame.maxX, y: frame.maxY))
        borderPath.addLine(to: CGPoint(x: frame.maxX, y: frame.minY))
        
        physicsBody = SKPhysicsBody(edgeChainFrom: borderPath)
        physicsBody?.categoryBitMask = PhysicsCategory.border
        physicsBody?.friction = 0
        
       
        
        // шарик
        
        burger.physicsBody = SKPhysicsBody(circleOfRadius: burger.size.width / 2)
        burger.physicsBody?.isDynamic = true
        burger.physicsBody?.friction = 0
        burger.physicsBody?.restitution = 1
        burger.physicsBody?.linearDamping = 0
        burger.physicsBody?.angularDamping = 0
        burger.physicsBody?.allowsRotation = false
        burger.physicsBody?.categoryBitMask = PhysicsCategory.ball
        burger.physicsBody?.contactTestBitMask = PhysicsCategory.paddle | PhysicsCategory.capsule | PhysicsCategory.border
        burger.physicsBody?.collisionBitMask = PhysicsCategory.paddle | PhysicsCategory.capsule | PhysicsCategory.border
        
        
        burger.physicsBody?.velocity = .zero // обнуляем скорость, чтоб не было базового движения
        burger.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 300))
        
        
        // платформа
        
        fatman.physicsBody = SKPhysicsBody(rectangleOf: fatman.size)
        fatman.physicsBody?.isDynamic = false
        fatman.physicsBody?.restitution = 1
        fatman.physicsBody?.friction = 0
        fatman.physicsBody?.linearDamping = 0
        fatman.physicsBody?.angularDamping = 0
        fatman.physicsBody?.allowsRotation = false
        fatman.physicsBody?.categoryBitMask = PhysicsCategory.paddle
        fatman.physicsBody?.contactTestBitMask = PhysicsCategory.ball
        fatman.physicsBody?.collisionBitMask = PhysicsCategory.ball
        
        
        setupCapsules()
    }
    
    func setupCapsules() {
        let capsuleWidth: CGFloat = 55
        let capsuleHeight: CGFloat = 24
        let rows = 4
        let columns = 10
        
        let horizontalSpacing: CGFloat = 10
        let verticalSpacing: CGFloat = 10
        
        // Вычисляем суммарную ширину ряда капсул с учетом отступов
        let totalCapsulesWidth = CGFloat(columns) * capsuleWidth + CGFloat(columns - 1) * horizontalSpacing
        
        // Отступ слева, чтобы центрировать ряд капсул по экрану
        let leftPadding = (frame.width - totalCapsulesWidth) / 2
        
        // Отступ сверху от верхнего края экрана
        let topPadding: CGFloat = 100
        
        
        
        for row in 0..<rows {
            for col in 0..<columns {
                // Создаем капсулу (заменяем на картинку capsule)
                let capsule = SKSpriteNode(imageNamed: "capsule")
                capsule.size = CGSize(width: capsuleWidth, height: capsuleHeight)

                let x = leftPadding + CGFloat(col) * (capsuleWidth + horizontalSpacing) + capsuleWidth / 2
                let y = frame.height - topPadding - CGFloat(row) * (capsuleHeight + verticalSpacing) - capsuleHeight / 2
                capsule.position = CGPoint(x: x, y: y)
                capsule.zPosition = 2
                
                
                capsule.physicsBody = SKPhysicsBody(rectangleOf: capsule.size)
                capsule.physicsBody?.isDynamic = false
                capsule.physicsBody?.categoryBitMask = PhysicsCategory.capsule
                capsule.physicsBody?.contactTestBitMask = PhysicsCategory.ball
                capsule.physicsBody?.collisionBitMask = PhysicsCategory.ball
                
             
                capsuleLayer.addChild(capsule)
            }
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB

        var ballBody: SKPhysicsBody
        var otherBody: SKPhysicsBody

        if bodyA.categoryBitMask == PhysicsCategory.ball {
            ballBody = bodyA
            otherBody = bodyB
        } else if bodyB.categoryBitMask == PhysicsCategory.ball {
            ballBody = bodyB
            otherBody = bodyA
        } else {
            return
        }

        switch otherBody.categoryBitMask {
        case PhysicsCategory.capsule:
            run(SKAction.playSoundFileNamed("otrizh.wav", waitForCompletion: false))
            otherBody.node?.removeFromParent()
            
        case PhysicsCategory.paddle:
            run(SKAction.playSoundFileNamed("platform.wav", waitForCompletion: false))
            
            if let ballNode = ballBody.node, let paddleNode = otherBody.node {
                let ballX = ballNode.position.x
                let paddleX = paddleNode.position.x
                let halfWidth = paddleNode.frame.width / 2
                
                let offset = (ballX - paddleX) / halfWidth
                
                let horizontalSpeed = offset * 800
                let verticalSpeed: CGFloat = 800
                
                ballBody.velocity = CGVector(dx: horizontalSpeed, dy: verticalSpeed)
            }
            
        case PhysicsCategory.border:
            run(SKAction.playSoundFileNamed("stena.wav", waitForCompletion: false))
        default:
            break
        }
    }


    
    
    // проигрыш
    
    func gameOver() {
        burger.removeFromParent()
        
        let gameOverLabel = SKLabelNode(text: "Game Over")
        gameOverLabel.fontSize = 50
        gameOverLabel.fontColor = .white
        gameOverLabel.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(gameOverLabel)
        
        
    }
    
   
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Ограничиваем движение платформы по ширине экрана
        let halfWidth = fatman.size.width / 2
        var newX = location.x
        newX = max(halfWidth, newX)
        newX = min(frame.width - halfWidth, newX)
        
        fatman.position.x = newX
        
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        guard let velocity = burger.physicsBody?.velocity else { return }
        
        let maxSpeed: CGFloat = 700.0
        
        let speed = sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy)
        
        if speed > maxSpeed {
            let scale = maxSpeed / speed
            burger.physicsBody?.velocity = CGVector(dx: velocity.dx * scale, dy: velocity.dy * scale)
        }
        
        if burger.position.y < 0 {
            gameOver()
        }
    }

    
    
}
