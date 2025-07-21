import SpriteKit
import AVFoundation

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
    var capsulesRemaining = 0
    var isWinShown = false
    var currentLevel = 1
    var speedMultiplier: CGFloat = 1.0
    var levelLabel: SKLabelNode!
    var isGameOver = false
    
    var backgroundMusicPlayer: AVAudioPlayer?
    let winSound = SKAction.playSoundFileNamed("krpw", waitForCompletion: false)
    let loseSound = SKAction.playSoundFileNamed("krpl", waitForCompletion: false)
    
    
    
    
    override func didMove(to view: SKView) {
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        backgroundColor = .black
        
        
        playBackgroundMusic(filename: "8bitfon.wav")
        backgroundMusicPlayer?.play()
        isGameOver = false
        
        
        
        
        
        func playBackgroundMusic(filename: String) {
            
            backgroundMusicPlayer?.stop()
            backgroundMusicPlayer = nil
            
            if let bundle = Bundle.main.path(forResource: filename, ofType: nil) {
                let musicURL = URL(fileURLWithPath: bundle)
                do {
                    backgroundMusicPlayer = try AVAudioPlayer(contentsOf: musicURL)
                    backgroundMusicPlayer?.numberOfLoops = -1
                    backgroundMusicPlayer?.prepareToPlay()
                    backgroundMusicPlayer?.play()
                } catch {
                    print("Could not load file: \(filename)")
                }
            }
        }


        // добавление левала
        
        levelLabel = SKLabelNode(fontNamed: "Avenir-Black")
        levelLabel.fontSize = 24
        levelLabel.fontColor = .white
        
        levelLabel.position = CGPoint(x: 16, y: frame.height - 80)
        
        levelLabel.horizontalAlignmentMode = .left
        levelLabel.verticalAlignmentMode = .baseline
        
        levelLabel.zPosition = 100
        addChild(levelLabel)
        
        
        
        // Платформа
        fatman = SKSpriteNode(imageNamed: "fatman")
        fatman.size = CGSize(width: 150, height: 90)
        fatman.position = CGPoint(x: frame.midX, y: fatman.size.height / 2 + 20)
        fatman.zPosition = 3
        addChild(fatman)
        
        let adjustedPlatformSize = CGSize(width: fatman.size.width * 0.8, height: fatman.size.height * 0.8)
        fatman.physicsBody = SKPhysicsBody(rectangleOf: adjustedPlatformSize)
        fatman.physicsBody?.isDynamic = false
        fatman.physicsBody?.restitution = 1
        fatman.physicsBody?.friction = 0
        fatman.physicsBody?.linearDamping = 0
        fatman.physicsBody?.angularDamping = 0
        fatman.physicsBody?.allowsRotation = false
        fatman.physicsBody?.categoryBitMask = PhysicsCategory.paddle
        fatman.physicsBody?.contactTestBitMask = PhysicsCategory.ball
        fatman.physicsBody?.collisionBitMask = PhysicsCategory.ball
        
        // Границы сцены
        let borderPath = CGMutablePath()
        borderPath.move(to: CGPoint(x: frame.minX, y: frame.minY))
        borderPath.addLine(to: CGPoint(x: frame.minX, y: frame.maxY))
        borderPath.addLine(to: CGPoint(x: frame.maxX, y: frame.maxY))
        borderPath.addLine(to: CGPoint(x: frame.maxX, y: frame.minY))
        borderPath.closeSubpath()

        physicsBody = SKPhysicsBody(edgeChainFrom: borderPath)
        physicsBody?.categoryBitMask = PhysicsCategory.border
        physicsBody?.friction = 0
        physicsBody?.restitution = 1

        // Контейнер капсул
        capsuleLayer = SKNode()
        capsuleLayer.zPosition = 2
        addChild(capsuleLayer)
        
        // Запускаем уровень (создание капсул и шарика)
        startLevel()
    }



    func startLevel() {
        // сбрасываем флаг победы
     isWinShown = false
        
        levelLabel.text = "Level \(currentLevel)"
        
        
        // удаляем старый шар
        
        burger?.removeFromParent()
        //очищаем капсулы
        for node in capsuleLayer.children {
            node.removeFromParent()
        }
        
        // Сброс счетчика капсул
        capsulesRemaining = 0
        
        // создаем капсулы
        setupCapsules()
        
        // Создаем шарик
        burger = SKSpriteNode(imageNamed: "burger")
        burger.size = CGSize(width: 30, height: 30)
        burger.position = CGPoint(x: frame.midX, y: fatman.position.y + fatman.size.height / 2 + burger.size.height / 2 + 10)
        burger.zPosition = 4
        addChild(burger)
        
        
        let adjustedRadius = burger.size.width / 2 * 0.8
        burger.physicsBody = SKPhysicsBody(circleOfRadius: adjustedRadius)
        burger.physicsBody?.isDynamic = true
        burger.physicsBody?.friction = 0
        burger.physicsBody?.restitution = 1
        burger.physicsBody?.linearDamping = 0
        burger.physicsBody?.angularDamping = 0
        burger.physicsBody?.allowsRotation = false
        burger.physicsBody?.categoryBitMask = PhysicsCategory.ball
        burger.physicsBody?.contactTestBitMask = PhysicsCategory.paddle |
        PhysicsCategory.capsule | PhysicsCategory.border
        burger.physicsBody?.collisionBitMask = PhysicsCategory.paddle |
        PhysicsCategory.capsule | PhysicsCategory.border
        burger.physicsBody?.velocity = .zero
        
        // Начальный импульс с учётом текущего множителя скорости
        let baseImpulse: CGFloat = 200
        let impulse = baseImpulse * speedMultiplier
        burger.physicsBody?.applyImpulse(CGVector(dx: impulse, dy: impulse))
        
        if !(backgroundMusicPlayer?.isPlaying ?? false) && !isGameOver {
            backgroundMusicPlayer?.play()
        }
        
    }
    
    
    func setupCapsules() {
        
        
        
        let capsuleWidth: CGFloat = 55
        let capsuleHeight: CGFloat = 24
        let rows = 4
        let columns = 6
        
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
                capsule.name = "capsuleBrick"

                let x = leftPadding + CGFloat(col) * (capsuleWidth + horizontalSpacing) + capsuleWidth / 2
                let y = frame.height - topPadding - CGFloat(row) * (capsuleHeight + verticalSpacing) - capsuleHeight / 2
                capsule.position = CGPoint(x: x, y: y)
                capsule.zPosition = 2
                
                
                let adjustedCapsuleSize = CGSize(width: capsule.size.width * 0.8, height: capsule.size.height * 0.8)
                capsule.physicsBody = SKPhysicsBody(rectangleOf: adjustedCapsuleSize)
                capsule.physicsBody?.isDynamic = false
                capsule.physicsBody?.categoryBitMask = PhysicsCategory.capsule
                capsule.physicsBody?.contactTestBitMask = PhysicsCategory.ball
                capsule.physicsBody?.collisionBitMask = PhysicsCategory.ball
                
                
           
                capsuleLayer.addChild(capsule)
                capsulesRemaining += 1
            }
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB
        
        // Чтобы удобнее работать, сортируем тела по категории
        let firstBody: SKPhysicsBody
        let secondBody: SKPhysicsBody
        
        if bodyA.categoryBitMask < bodyB.categoryBitMask {
            firstBody = bodyA
            secondBody = bodyB
        } else {
            firstBody = bodyB
            secondBody = bodyA
        }
        
        // Исправляем движение шарика если он "застрял" в горизонтали
        if firstBody.categoryBitMask == PhysicsCategory.ball && secondBody.categoryBitMask == PhysicsCategory.border {

               if let ball = firstBody.node as? SKSpriteNode {
                   correctBallAngle(ball)
               }
            // 🔊 звук столкновения со стеной
                    run(SKAction.playSoundFileNamed("stena.wav", waitForCompletion: false))
            
           }
        
        
        
        // 1. Отскок бургера от платформы
        if firstBody.categoryBitMask == PhysicsCategory.ball &&
           secondBody.categoryBitMask == PhysicsCategory.paddle {
            
            guard let burgerNode = firstBody.node as? SKSpriteNode,
                  let platformNode = secondBody.node as? SKSpriteNode else { return }
            
            let contactX = contact.contactPoint.x
            let platformX = platformNode.position.x
            let deltaX = contactX - platformX
            
            let normalized = deltaX / (platformNode.size.width / 2)
            
            // Максимальный угол отклонения - 60 градусов (π/3 радиан)
            let maxBounceAngle = CGFloat.pi / 3
            let bounceAngle = maxBounceAngle * normalized
            
            let currentVelocity = burgerNode.physicsBody?.velocity ?? CGVector(dx: 0, dy: 0)
            let speed = sqrt(currentVelocity.dx * currentVelocity.dx + currentVelocity.dy * currentVelocity.dy)
            
            // Вычисляем скорость по X и Y
            let dx = cos(bounceAngle) * speed
            let dy = abs(sin(bounceAngle) * speed)  // всегда вверх
            
            // 🔊 звук столкновения с платформой
                    run(SKAction.playSoundFileNamed("platform.wav", waitForCompletion: false))
            
            
            burgerNode.physicsBody?.velocity = CGVector(dx: dx, dy: dy)
        }
        
        // 2. Уничтожение капсулы с анимацией
        if firstBody.categoryBitMask == PhysicsCategory.ball &&
           secondBody.categoryBitMask == PhysicsCategory.capsule {
            
            guard let capsuleNode = secondBody.node else { return }
            
            // 🔊 звук столкновения с капсулой
                    run(SKAction.playSoundFileNamed("otrizh.wav", waitForCompletion: false))
            
            // Запускаем анимацию взрыва
            runCapsuleDestructionEffect(at: capsuleNode.position)
            
            // Удаляем капсулу из сцены после анимации
            capsuleNode.removeFromParent()
            capsulesRemaining -= 1
            print("capsulesRemaining: \(capsulesRemaining)") // для отладки
            if capsulesRemaining <= 0 && !isWinShown {
                isWinShown = true
                goToNextLevel()
            }
        }
    }

    // новый уровень
    
    func goToNextLevel() {
        
        backgroundMusicPlayer?.stop()
        run(winSound)
        
        
        // отображаем надпись
        let winLabel = SKLabelNode(text: "YOU WIN")
        winLabel.fontSize = 50
        winLabel.fontColor = .yellow
        winLabel.fontName = "Avenir-Black"
        winLabel.position = CGPoint(x: frame.midX, y: frame.midY)
        winLabel.zPosition = 100
        addChild(winLabel)
        
        let winImage = SKSpriteNode(imageNamed: "krpw")
        winImage.position = CGPoint(x: frame.midX, y: frame.midY - 80)
        winImage.zPosition = 100
        winImage.name = "krpw"
        addChild(winImage)
        
        
        // увеличиваем уровень и скорость шарика
        currentLevel += 1
        speedMultiplier *= 1.08 // 8%
        
        // удаляем шар
        
        burger.removeFromParent()
        
        let wait = SKAction.wait(forDuration: 3)
        let nextLevelAction = SKAction.run {
            winLabel.removeFromParent()
            self.childNode(withName: "krpw")?.removeFromParent()
            self.backgroundMusicPlayer?.play()
            self.startLevel()
        }
        
        run(SKAction.sequence([wait, nextLevelAction]))
        
    }
    
 
    
    // победа в игре
    
    
    func showWinScreen() {
        // удаляем мяч
        burger.removeFromParent()
        
        let winLabel = SKLabelNode(text: "YOU WIN")
        winLabel.fontSize = 50
        winLabel.fontColor = .yellow
        winLabel.fontName = "Avenir-Black"
        winLabel.position = CGPoint(x: frame.midX, y: frame.midY)
        winLabel.zPosition = 100
        addChild(winLabel)
        
        // рестарт через паузу
        
        let wait = SKAction.wait(forDuration: 5)
        let restartAction = SKAction.run {
            if let view = self.view {
                let scene  = GameScene(size: self.size)
                scene.scaleMode = .aspectFill
                view.presentScene(scene, transition: SKTransition.fade(withDuration: 0.5))
            }
            
        }
        run(SKAction.sequence([wait,restartAction]))
        
    }
    
    
    
    
    
    
// коррекция шарика
    func correctBallAngle(_ ball: SKSpriteNode) {
        var velocity = ball.physicsBody?.velocity ?? .zero
        let minVerticalSpeed: CGFloat = 300.0
        let minHorizontalSpeed: CGFloat = 100.0

        // Если вертикальная скорость почти нулевая, корректируем угол отскока
        if abs(velocity.dy) < minVerticalSpeed {
            let totalSpeed = sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy)
            let signY: CGFloat = velocity.dy >= 0 ? 1 : -1
            // Новое направление: сохранение "знака" движения, но задаём нужный угол
            velocity.dy = signY * minVerticalSpeed
            // Пересчитываем X, чтобы общий модуль остался прежним
            velocity.dx = copysign(sqrt(max(0, totalSpeed * totalSpeed - velocity.dy * velocity.dy)), velocity.dx)
            // Если dx стал слишком маленьким — задаём минимум для динамики
            if abs(velocity.dx) < minHorizontalSpeed {
                velocity.dx = copysign(minHorizontalSpeed, velocity.dx != 0 ? velocity.dx : 1)
            }
            ball.physicsBody?.velocity = velocity
        }
    }
    
    
    
    
// разрушение капсулы
    
    func runCapsuleDestructionEffect(at position: CGPoint) {
        let explosion = SKEmitterNode(fileNamed: "CapsuleExplosion.sks") ?? SKEmitterNode()
        explosion.position = position
        explosion.zPosition = 5
        addChild(explosion)
        
        let wait = SKAction.wait(forDuration: 1.0)
        let remove = SKAction.removeFromParent()
        explosion.run(SKAction.sequence([wait, remove]))
    }

    
    
    // проигрыш
    
    func gameOver() {
        
        if isGameOver { return }
        isGameOver = true
        
        backgroundMusicPlayer?.stop()
        run(loseSound)
        
        burger.removeFromParent()
        
        let gameOverLabel = SKLabelNode(text: "Game Over")
        gameOverLabel.fontSize = 50
        gameOverLabel.fontColor = .white
        gameOverLabel.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(gameOverLabel)
        
        
        let gameOverImage = SKSpriteNode(imageNamed: "krpl")
        gameOverImage.position = CGPoint(x: frame.midX, y: frame.midY - 80)
        gameOverImage.zPosition = 100
        gameOverImage.name = "krpl"
        addChild(gameOverImage)
        
        
        
        // сбрасываем прогресс
        currentLevel = 1
        speedMultiplier = 1.0
        
        // автомат. рестарт через 3 секунды
        let wait = SKAction.wait(forDuration: 3)
        let restart = SKAction.run {
            gameOverLabel.removeFromParent()
            self.childNode(withName: "krpl")?.removeFromParent()
            self.startLevel()
        }
        run(SKAction.sequence([wait, restart]))
        
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
        
        let maxSpeed: CGFloat = 750.0
        
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
