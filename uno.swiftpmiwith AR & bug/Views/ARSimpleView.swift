import SwiftUI
import ARKit
import RealityKit

// AR游戏视图 - 简化版
struct ARSimpleView: View {
    @StateObject private var gameModel = GameModel()
    @StateObject private var arViewModel = ARSimpleViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // AR视图作为背景
            ARViewContainer(arViewModel: arViewModel)
                .edgesIgnoringSafeArea(.all)
            
            // UI覆盖层
            VStack {
                // 顶部信息
                HStack {
                    Text("AR UNO")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.6))
                        )
                    
                    Spacer()
                    
                    // 增强现实模式选择
                    if arViewModel.hasPlacedCard {
                        Menu {
                            Button(action: {
                                arViewModel.currentMode = .freestyle
                                arViewModel.statusMessage = "自由模式：点击添加卡牌"
                            }) {
                                Label("自由模式", systemImage: "square.stack.3d.up")
                            }
                            
                            Button(action: {
                                arViewModel.startMemoryGame()
                                arViewModel.currentMode = .memoryGame
                            }) {
                                Label("记忆游戏", systemImage: "brain")
                            }
                            
                            Button(action: {
                                arViewModel.currentMode = .cardStacking
                                arViewModel.statusMessage = "堆叠模式：堆叠卡牌越高越好"
                            }) {
                                Label("堆叠挑战", systemImage: "square.stack.3d.up.fill")
                            }
                        } label: {
                            Image(systemName: "gamecontroller.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Circle().fill(Color.purple.opacity(0.8)))
                        }
                    }
                    
                    // 重置按钮
                    Button(action: {
                        arViewModel.resetARScene()
                    }) {
                        Image(systemName: "arrow.clockwise.circle")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                    }
                    
                    // 返回按钮
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                }
                .padding()
                
                Spacer()
                
                // 卡牌计数器和状态
                if arViewModel.hasPlacedCard {
                    HStack {
                        Text("已放置卡牌: \(arViewModel.placedCardCount)")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.6))
                            )
                        
                        Spacer()
                        
                        // 显示当前模式
                        Text(arViewModel.currentModeText)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(
                                Capsule()
                                    .fill(Color(arViewModel.currentModeColor))
                            )
                        
                        Spacer()
                        
                        // 添加随机卡牌按钮
                        Button(action: {
                            arViewModel.addRandomCardManually()
                        }) {
                            Label("添加卡牌", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(
                                    Capsule()
                                        .fill(Color.green.opacity(0.8))
                                )
                        }
                        .disabled(arViewModel.isAnimating)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                }
                
                // 提示信息
                Text(arViewModel.statusMessage)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                    .padding()
                
                // 初始AR指导
                if !arViewModel.hasPlacedCard {
                    VStack(spacing: 10) {
                        Text("AR使用指南:")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("1. 慢慢移动设备扫描周围环境")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Text("2. 找到平面后，点击屏幕放置游戏区域")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Text("3. 继续点击添加更多UNO卡牌")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Text("4. 使用右上角菜单选择不同AR模式")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                    .padding(.bottom, 30)
                }
            }
        }
    }
}

// AR视图容器
struct ARViewContainer: UIViewRepresentable {
    var arViewModel: ARSimpleViewModel
    
    func makeUIView(context: Context) -> ARView {
        return arViewModel.arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // 无需更新，所有更新都在ViewModel中处理
    }
}

// 定义AR交互模式
enum ARMode {
    case freestyle    // 自由放置卡牌
    case memoryGame   // 记忆游戏
    case cardStacking // 堆叠挑战
}

// AR视图模型
class ARSimpleViewModel: ObservableObject {
    let arView = ARView(frame: .zero)
    @Published var statusMessage = "寻找平面放置卡牌..."
    @Published var hasPlacedCard = false
    @Published var placedCardCount = 0
    @Published var isAnimating = false
    @Published var currentMode: ARMode = .freestyle {
        didSet {
            updateModeSettings()
        }
    }
    @Published var currentModeText: String = "自由模式"
    @Published var currentModeColor: UIColor = .green
    
    private var cardAnchor: AnchorEntity?
    private var gameCards: [ModelEntity] = []
    private var stackHeight: Int = 0
    
    // 更新模式设置
    private func updateModeSettings() {
        switch currentMode {
        case .freestyle:
            currentModeText = "自由模式"
            currentModeColor = .green
        case .memoryGame:
            currentModeText = "记忆游戏"
            currentModeColor = .purple
        case .cardStacking:
            currentModeText = "堆叠挑战"
            currentModeColor = .orange
            stackHeight = 0
        }
    }
    
    init() {
        setupARView()
        updateModeSettings()
    }
    
    private func setupARView() {
        // 配置AR会话
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        arView.session.run(configuration)
        
        // 添加点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        arView.addGestureRecognizer(tapGesture)
        
        // 添加会话委托
        arView.session.delegate = self
    }
    
    @objc private func handleTap(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: arView)
        
        if !hasPlacedCard {
            let results = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal)
            
            if let firstResult = results.first {
                // 初次点击，创建游戏区域
                createGameArea(at: firstResult)
                hasPlacedCard = true
                statusMessage = "游戏区域已创建！点击继续添加卡牌"
            }
        } else if !isAnimating {
            // 基于当前模式处理点击
            switch currentMode {
            case .freestyle:
                // 自由模式：添加卡牌
                addRandomCard()
            case .memoryGame:
                // 记忆游戏：检查是否点击了卡牌
                checkCardTap(at: location)
            case .cardStacking:
                // 堆叠挑战：在上一张卡牌上方添加卡牌
                addStackingCard()
            }
        }
    }
    
    // 检查是否点击了卡牌
    private func checkCardTap(at location: CGPoint) {
        // 执行射线检测来查找点击的实体
        let results = arView.raycast(from: location, allowing: .estimatedPlaneExtent, alignment: .any)
        
        if let hitTest = arView.hitTest(location).first {
            // 向上遍历实体层次结构查找ModelEntity
            var currentEntity: Entity? = hitTest.entity
            var modelEntity: ModelEntity? = nil
            
            while currentEntity != nil && modelEntity == nil {
                if let entity = currentEntity as? ModelEntity {
                    modelEntity = entity
                }
                currentEntity = currentEntity?.parent
            }
            
            if let entity = modelEntity {
                // 基于当前模式处理卡牌点击
                switch currentMode {
                case .freestyle:
                    // 自由模式：执行通用卡牌交互
                    handleCardTap(entity: entity)
                case .memoryGame:
                    // 记忆游戏：执行记忆游戏卡牌交互
                    handleMemoryCardTap(entity: entity)
                case .cardStacking:
                    // 堆叠模式：跳过卡牌点击处理，点击背景添加新卡牌
                    break
                }
            }
        } else if currentMode == .cardStacking {
            // 堆叠模式下，点击背景时添加新卡牌
            addStackingCard()
        }
    }
    
    // 添加堆叠卡牌
    private func addStackingCard() {
        guard let anchor = cardAnchor else { return }
        
        // 创建新卡牌
        let colors: [UIColor] = [.red, .blue, .green, .yellow]
        let randomColor = colors.randomElement()!
        let cardEntity = createCardEntity(color: randomColor, value: "\(Int.random(in: 1...9))")
        
        // 计算堆叠高度
        let stackingHeight: Float = 0.005 * Float(stackHeight)
        cardEntity.position = [0, stackingHeight, 0]
        
        // 添加微弱的旋转，增加挑战性
        let angle = Float.random(in: -0.05...0.05)
        cardEntity.orientation = simd_quatf(angle: angle, axis: [0, 1, 0])
        
        // 添加到游戏区域
        anchor.addChild(cardEntity)
        
        // 更新状态
        stackHeight += 1
        placedCardCount += 1
        
        // 更新成就消息
        if stackHeight >= 10 {
            statusMessage = "太厉害了！你已经堆了\(stackHeight)层卡牌！"
        } else {
            statusMessage = "成功堆叠！当前高度: \(stackHeight)层"
        }
        
        // 动画效果
        let dropAnimation = AnimationResource.animation(with: [
            AnimationKeyframe(time: 0, position: cardEntity.position + SIMD3<Float>(0, 0.2, 0)),
            AnimationKeyframe(time: 0.3, position: cardEntity.position)
        ])
        
        cardEntity.playAnimation(dropAnimation)
    }
    
    // 手动添加卡牌的公开方法
    func addRandomCardManually() {
        if hasPlacedCard && !isAnimating {
            addRandomCard()
        }
    }
    
    // 重置AR场景
    func resetARScene() {
        // 移除所有锚点
        arView.scene.anchors.removeAll()
        
        // 重置状态
        hasPlacedCard = false
        placedCardCount = 0
        cardAnchor = nil
        statusMessage = "场景已重置，请重新扫描平面"
        
        // 重新启动AR会话
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    private func createGameArea(at raycastResult: ARRaycastResult) {
        // 创建锚点
        cardAnchor = AnchorEntity(world: raycastResult.worldTransform)
        
        // 创建游戏区域平面
        let planeMesh = MeshResource.generatePlane(width: 0.3, depth: 0.3)
        let planeMaterial = SimpleMaterial(color: UIColor(red: 0.0, green: 0.3, blue: 0.1, alpha: 0.7), isMetallic: false)
        let planeEntity = ModelEntity(mesh: planeMesh, materials: [planeMaterial])
        planeEntity.position = [0, 0, 0]
        
        // 添加到锚点
        cardAnchor?.addChild(planeEntity)
        
        // 添加到场景
        arView.scene.addAnchor(cardAnchor!)
        
        // 添加初始卡牌
        addRandomCard()
    }
    
    private func addRandomCard() {
        guard let cardAnchor = cardAnchor else { return }
        
        isAnimating = true
        
        // 随机选择卡牌颜色和数字
        let colors: [UIColor] = [.red, .blue, .green, .yellow]
        let values = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "+2", "Skip", "Reverse", "Wild", "+4"]
        
        let randomColor = colors.randomElement()!
        let randomValue = values.randomElement()!
        
        // 创建卡牌
        let cardEntity = createUnoCardEntity(color: randomColor, value: randomValue)
        
        // 设置初始位置（上方高处）
        cardEntity.position = [0, 0.5, 0]
        cardEntity.scale = [0.1, 0.1, 0.1]
        
        // 计算放置位置（稍微错开）
        let xOffset = Float(placedCardCount % 3) * 0.08 - 0.08
        let zOffset = Float(placedCardCount / 3) * 0.08 - 0.08
        let finalPosition = SIMD3<Float>(xOffset, 0.01, zOffset)
        
        // 添加到锚点
        cardAnchor.addChild(cardEntity)
        
        // 创建下落动画
        let fallAnimation = MoveAnimation(
            to: finalPosition,
            duration: 1.0,
            timingFunction: .easeInOut
        )
        
        // 创建旋转动画
        let rotateAnimation = RotateAnimation(
            to: simd_quatf(angle: .pi * 2, axis: [0, 1, 0]),
            duration: 1.0,
            timingFunction: .easeInOut
        )
        
        // 播放下落动画
        cardEntity.playAnimation(fallAnimation)
        
        // 下落后播放旋转动画
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            cardEntity.playAnimation(rotateAnimation) { _ in
                self.placedCardCount += 1
                self.statusMessage = "已放置 \(self.placedCardCount) 张卡牌"
                self.isAnimating = false
            }
        }
    }
    
    private func createUnoCardEntity(color: UIColor, value: String) -> ModelEntity {
        // 卡牌大小
        let cardSize: SIMD3<Float> = [0.05, 0.001, 0.08]
        
        // 创建卡牌实体
        let cardMesh = MeshResource.generateBox(size: cardSize)
        var cardMaterial = SimpleMaterial(color: color, isMetallic: false)
        
        // 对于特殊卡牌使用不同颜色
        if value == "Wild" || value == "+4" {
            cardMaterial = SimpleMaterial(color: .black, isMetallic: false)
        }
        
        let cardEntity = ModelEntity(mesh: cardMesh, materials: [cardMaterial])
        
        // 添加文字
        let textMesh = MeshResource.generateText(
            value,
            extrusionDepth: 0.001,
            font: .systemFont(ofSize: 0.04),
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byTruncatingTail
        )
        
        let textColor: UIColor = (color == .yellow || color == .green) ? .black : .white
        let textMaterial = SimpleMaterial(color: textColor, isMetallic: false)
        let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])
        
        // 调整文本位置和大小
        textEntity.position = [0, 0.003, 0]
        textEntity.scale = [0.7, 0.7, 0.7]
        
        cardEntity.addChild(textEntity)
        
        // 添加边框
        let borderMesh = MeshResource.generateBox(size: [cardSize.x + 0.002, cardSize.y, cardSize.z + 0.002])
        let borderMaterial = SimpleMaterial(color: .white, isMetallic: false)
        let borderEntity = ModelEntity(mesh: borderMesh, materials: [borderMaterial])
        borderEntity.position = [0, -0.0005, 0]
        
        cardEntity.addChild(borderEntity)
        
        return cardEntity
    }
    
    // 添加卡牌翻转和交互功能
    func flipCard(_ entity: ModelEntity) {
        isAnimating = true
        
        // 创建翻转动画
        var flipTransform = entity.transform
        let originalRotation = entity.orientation
        
        // 设置动画时间线
        let duration: TimeInterval = 0.5
        
        // 执行翻转动画
        var flipAnimation = AnimationResource.animation(with: [
            AnimationKeyframe(time: 0, rotation: originalRotation),
            AnimationKeyframe(time: duration/2, rotation: simd_quatf(angle: .pi, axis: [0, 1, 0])),
            AnimationKeyframe(time: duration, rotation: simd_quatf(angle: 2 * .pi, axis: [0, 1, 0]))
        ])
        
        entity.playAnimation(flipAnimation, transitionDuration: 0.5)
        
        // 动画完成后恢复状态
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.isAnimating = false
            self.statusMessage = "卡牌已翻转！点击继续添加更多卡牌"
            self.placedCardCount += 1
        }
    }
    
    // 处理卡牌点击
    func handleCardTap(entity: ModelEntity) {
        guard !isAnimating else { return }
        
        // 随机选择交互效果
        let effectType = Int.random(in: 0...2)
        
        switch effectType {
        case 0:
            // 翻转效果
            flipCard(entity)
        case 1:
            // 颜色变化效果
            changeCardColor(entity)
        case 2:
            // 跳跃效果
            bounceCard(entity)
        default:
            flipCard(entity)
        }
    }
    
    // 改变卡牌颜色
    private func changeCardColor(_ entity: ModelEntity) {
        isAnimating = true
        
        // 随机选择新颜色
        let colors: [UIColor] = [.red, .blue, .green, .yellow]
        let randomColor = colors.randomElement()!
        
        // 查找主体材质并更新
        if let cardComponent = entity.children.first {
            if var material = cardComponent.model?.materials.first as? SimpleMaterial {
                material.color = SimpleMaterial.Color(tint: randomColor, texture: nil)
                cardComponent.model?.materials = [material]
            }
        }
        
        // 动画完成后恢复状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isAnimating = false
            self.statusMessage = "卡牌颜色已变化！点击继续互动"
        }
    }
    
    // 卡牌跳跃动画
    private func bounceCard(_ entity: ModelEntity) {
        isAnimating = true
        
        // 获取原始位置
        let originalPosition = entity.position
        let jumpHeight: Float = 0.1
        
        // 创建跳跃动画
        var bounceAnimation = AnimationResource.animation(with: [
            AnimationKeyframe(time: 0, position: originalPosition),
            AnimationKeyframe(time: 0.15, position: originalPosition + SIMD3<Float>(0, jumpHeight, 0)),
            AnimationKeyframe(time: 0.3, position: originalPosition)
        ])
        
        entity.playAnimation(bounceAnimation, transitionDuration: 0.3)
        
        // 动画完成后恢复状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.isAnimating = false
            self.statusMessage = "卡牌跳跃！点击继续互动"
        }
    }
    
    // 添加AR卡牌游戏逻辑
    func startMemoryGame() {
        // 清除现有卡牌
        resetARScene(keepGameArea: true)
        
        // 重置游戏状态
        gameCards = []
        
        // 更新状态
        statusMessage = "记忆游戏：记住卡牌位置和颜色！"
        
        // 创建游戏区域（如果尚未创建）
        if cardAnchor == nil {
            let anchor = AnchorEntity(plane: .horizontal)
            arView.scene.addAnchor(anchor)
            cardAnchor = anchor
        }
        
        // 创建游戏区域
        if let anchor = cardAnchor {
            // 创建4张卡牌的网格
            let spacing: Float = 0.12
            let positions: [SIMD3<Float>] = [
                [-spacing, 0, -spacing],  // 左上
                [spacing, 0, -spacing],   // 右上
                [-spacing, 0, spacing],   // 左下
                [spacing, 0, spacing]     // 右下
            ]
            
            // 创建卡牌颜色配对（2对相同颜色）
            let cardColors: [UIColor] = [.red, .blue, .green, .yellow].shuffled()
            var pairColors: [UIColor] = []
            pairColors.append(contentsOf: [cardColors[0], cardColors[0], cardColors[1], cardColors[1]])
            pairColors.shuffle()
            
            // 创建记忆游戏卡牌
            for (index, position) in positions.enumerated() {
                let color = pairColors[index]
                let cardEntity = createCardEntity(color: color, value: "")
                cardEntity.position = position
                
                // 添加标识以跟踪卡牌
                cardEntity.name = "memoryCard_\(index)_\(color.description)"
                
                // 添加到游戏区域
                anchor.addChild(cardEntity)
                gameCards.append(cardEntity)
            }
            
            isAnimating = true
            
            // 3秒后自动翻转所有卡牌
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.statusMessage = "记住卡牌位置！查找配对"
                
                // 创建翻转动画使卡牌背面朝上
                for card in self.gameCards {
                    // 先翻转卡牌使背面朝上
                    let flipAnimation = AnimationResource.animation(with: [
                        AnimationKeyframe(time: 0, rotation: card.orientation),
                        AnimationKeyframe(time: 0.5, rotation: simd_quatf(angle: .pi, axis: [0, 1, 0]))
                    ])
                    
                    // 替换卡牌表面为背面
                    if let cardComponent = card.children.first {
                        if var material = cardComponent.model?.materials.first as? SimpleMaterial {
                            material.color = SimpleMaterial.Color(tint: .gray, texture: nil)
                            cardComponent.model?.materials = [material]
                        }
                    }
                    
                    card.playAnimation(flipAnimation)
                }
                
                self.isAnimating = false
                self.selectedCards = []
                self.matchedPairs = 0
            }
            
            hasPlacedCard = true
        }
    }
    
    // 记忆游戏变量
    private var selectedCards: [ModelEntity] = []
    private var matchedPairs: Int = 0
    
    // 处理记忆游戏卡牌点击
    func handleMemoryCardTap(entity: ModelEntity) {
        guard !isAnimating, selectedCards.count < 2, !selectedCards.contains(entity) else { return }
        
        isAnimating = true
        
        // 翻转卡牌
        let flipAnimation = AnimationResource.animation(with: [
            AnimationKeyframe(time: 0, rotation: entity.orientation),
            AnimationKeyframe(time: 0.5, rotation: simd_quatf(angle: 0, axis: [0, 1, 0]))
        ])
        
        entity.playAnimation(flipAnimation)
        
        // 恢复卡牌原始颜色
        if let originalColor = getOriginalColor(from: entity.name) {
            if let cardComponent = entity.children.first {
                if var material = cardComponent.model?.materials.first as? SimpleMaterial {
                    material.color = SimpleMaterial.Color(tint: originalColor, texture: nil)
                    cardComponent.model?.materials = [material]
                }
            }
        }
        
        // 添加到选中卡牌
        selectedCards.append(entity)
        
        // 检查配对
        if selectedCards.count == 2 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.checkForMatch()
            }
        } else {
            isAnimating = false
        }
    }
    
    // 从卡牌名称获取原始颜色
    private func getOriginalColor(from name: String) -> UIColor? {
        if name.contains("red") {
            return .red
        } else if name.contains("blue") {
            return .blue
        } else if name.contains("green") {
            return .green
        } else if name.contains("yellow") {
            return .yellow
        }
        return nil
    }
    
    // 检查卡牌是否配对
    private func checkForMatch() {
        guard selectedCards.count == 2 else { return }
        
        let card1 = selectedCards[0]
        let card2 = selectedCards[1]
        
        // 提取颜色信息
        let color1 = getOriginalColor(from: card1.name)
        let color2 = getOriginalColor(from: card2.name)
        
        if color1 == color2 {
            // 配对成功
            matchedPairs += 1
            statusMessage = "配对成功！已找到\(matchedPairs)对"
            
            // 配对成功动画
            for card in selectedCards {
                let bounceAnimation = AnimationResource.animation(with: [
                    AnimationKeyframe(time: 0, position: card.position),
                    AnimationKeyframe(time: 0.15, position: card.position + SIMD3<Float>(0, 0.05, 0)),
                    AnimationKeyframe(time: 0.3, position: card.position)
                ])
                
                card.playAnimation(bounceAnimation)
            }
            
            // 检查游戏是否结束
            if matchedPairs >= 2 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.statusMessage = "恭喜！你完成了记忆游戏！"
                    
                    // 胜利动画
                    for card in self.gameCards {
                        let randomDuration = Double.random(in: 0.5...1.0)
                        let randomHeight = Float.random(in: 0.1...0.2)
                        
                        let celebrationAnimation = AnimationResource.animation(with: [
                            AnimationKeyframe(time: 0, position: card.position),
                            AnimationKeyframe(time: randomDuration/2, position: card.position + SIMD3<Float>(0, randomHeight, 0)),
                            AnimationKeyframe(time: randomDuration, position: card.position)
                        ])
                        
                        card.playAnimation(celebrationAnimation, transitionDuration: 0.5)
                    }
                }
            }
        } else {
            // 配对失败，翻回卡牌
            statusMessage = "配对失败，再试一次！"
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                for card in self.selectedCards {
                    // 翻转卡牌使背面朝上
                    let flipAnimation = AnimationResource.animation(with: [
                        AnimationKeyframe(time: 0, rotation: card.orientation),
                        AnimationKeyframe(time: 0.5, rotation: simd_quatf(angle: .pi, axis: [0, 1, 0]))
                    ])
                    
                    // 替换卡牌表面为背面
                    if let cardComponent = card.children.first {
                        if var material = cardComponent.model?.materials.first as? SimpleMaterial {
                            material.color = SimpleMaterial.Color(tint: .gray, texture: nil)
                            cardComponent.model?.materials = [material]
                        }
                    }
                    
                    card.playAnimation(flipAnimation)
                }
            }
        }
        
        // 重置选中状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.selectedCards = []
            self.isAnimating = false
        }
    }
    
    // 重置AR场景，可选择保留游戏区域
    func resetARScene(keepGameArea: Bool = false) {
        if !keepGameArea {
            // 移除所有锚点
            arView.scene.anchors.removeAll()
            
            // 重置状态
            hasPlacedCard = false
            cardAnchor = nil
        } else {
            // 仅移除卡牌，保留游戏区域
            if let anchor = cardAnchor {
                for child in anchor.children {
                    child.removeFromParent()
                }
            }
        }
        
        // 重置通用状态
        placedCardCount = 0
        gameCards = []
        selectedCards = []
        matchedPairs = 0
        stackHeight = 0
        
        // 更新状态消息
        if !keepGameArea {
            statusMessage = "寻找平面放置卡牌..."
        } else {
            statusMessage = "游戏区域已重置！"
        }
    }
}

// AR会话委托
extension ARSimpleViewModel: ARSessionDelegate {
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        // 检测到平面时更新状态
        for anchor in anchors {
            if anchor is ARPlaneAnchor {
                DispatchQueue.main.async {
                    self.statusMessage = "检测到平面！点击屏幕放置卡牌"
                }
                break
            }
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // 会话失败时更新状态
        DispatchQueue.main.async {
            self.statusMessage = "AR会话发生错误: \(error.localizedDescription)"
        }
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // 会话中断时更新状态
        DispatchQueue.main.async {
            self.statusMessage = "AR会话被中断，请稍候..."
        }
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // 会话中断结束时更新状态
        DispatchQueue.main.async {
            if self.hasPlacedCard {
                self.statusMessage = "已放置 \(self.placedCardCount) 张卡牌"
            } else {
                self.statusMessage = "AR会话已恢复，请继续扫描平面"
            }
        }
    }
} 