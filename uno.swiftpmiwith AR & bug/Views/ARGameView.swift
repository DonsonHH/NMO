import SwiftUI
import ARKit
import RealityKit

struct ARGameView: View {
    @StateObject private var gameModel = GameModel()
    @StateObject private var arViewModel = ARViewModel()
    @Environment(\.dismiss) private var dismiss
    
    // 游戏状态
    @State private var showingRules = false
    @State private var isCardDrawn = false
    @State private var isCardPlayed = false
    @State private var animatedCard: Card?
    @State private var isComputerDrawing = false
    
    var body: some View {
        ZStack {
            // AR视图作为背景
            ARViewContainer(arViewModel: arViewModel, gameModel: gameModel)
                .edgesIgnoringSafeArea(.all)
            
            // AR放置提示
            ARPlacementView(arViewModel: arViewModel)
            
            // 如果已经放置游戏板，显示游戏开始提示，然后淡出
            if arViewModel.hasPlacedBoard {
                WithFadeOut(duration: 2.0, delay: 1.5) {
                    SceneStartHint()
                }
            }
            
            // 游戏UI覆盖层 - 仅在游戏桌面已放置后显示
            if arViewModel.hasPlacedBoard {
                VStack {
                    // 顶部信息
                    HStack {
                        Text("电脑手牌: \(gameModel.computerHand.count)")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.6))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.6), lineWidth: 1)
                                    )
                            )
                        
                        Spacer()
                        
                        Button(action: {
                            showingRules = true
                        }) {
                            Image(systemName: "questionmark.circle")
                                .font(.title)
                                .foregroundColor(.white)
                        }
                        
                        Button(action: {
                            withAnimation(.spring()) {
                                gameModel.startNewGame()
                                arViewModel.resetARScene()
                            }
                        }) {
                            Text("新游戏")
                                .font(.headline)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(5)
                        }
                        
                        Button(action: {
                            withAnimation(.easeInOut) {
                                dismiss()
                            }
                        }) {
                            Image(systemName: "house.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .padding(.leading, 10)
                        }
                    }
                    .padding()
                    
                    Spacer()
                    
                    // 游戏状态信息
                    Text(gameModel.message)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.black.opacity(0.5))
                                .shadow(color: .white.opacity(0.1), radius: 5)
                        )
                        .padding(.horizontal)
                    
                    // 玩家手牌 - 底部滚动视图
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 5) {
                            // 抽牌按钮
                            Button(action: {
                                guard !isCardDrawn && !isCardPlayed && !isComputerDrawing else { return }
                                guard gameModel.currentPlayer == .human && gameModel.gameStatus == .playing else { return }
                                
                                isCardDrawn = true
                                
                                // 播放抽牌动画
                                arViewModel.animateDrawCard(isComputer: false) {
                                    isCardDrawn = false
                                    gameModel.drawCard()
                                }
                            }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.black.opacity(0.7))
                                        .frame(width: 70, height: 105)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(gameModel.shouldHighlightDrawButton ? Color.yellow : Color.white, lineWidth: 2)
                                        )
                                        .shadow(color: gameModel.shouldHighlightDrawButton ? .yellow : .white, radius: gameModel.shouldHighlightDrawButton ? 5 : 2)
                                    
                                    VStack {
                                        Image(systemName: "arrow.down.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(gameModel.shouldHighlightDrawButton ? .yellow : .white)
                                        
                                        Text("抽牌")
                                            .font(.caption)
                                            .foregroundColor(gameModel.shouldHighlightDrawButton ? .yellow : .white)
                                            .padding(.top, 5)
                                    }
                                }
                                .scaleEffect(gameModel.shouldHighlightDrawButton ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: gameModel.shouldHighlightDrawButton)
                            }
                            .disabled(gameModel.currentPlayer != .human || gameModel.gameStatus != .playing)
                            .padding(.leading)
                            
                            // 玩家手牌
                            ForEach(gameModel.playerHand) { card in
                                Button(action: {
                                    guard gameModel.currentPlayer == .human && gameModel.gameStatus == .playing && card.isPlayable else { return }
                                    guard !isCardDrawn && !isCardPlayed && !isComputerDrawing else { return }
                                    
                                    isCardPlayed = true
                                    animatedCard = card
                                    
                                    // 播放出牌动画
                                    arViewModel.animatePlayCard(card: card, isComputer: false) {
                                        isCardPlayed = false
                                        gameModel.playCard(card)
                                    }
                                }) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(card.color == .wild ? Color.black : card.color.color)
                                            .frame(width: 70, height: 105)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.white, lineWidth: 1)
                                            )
                                        
                                        Text(card.displayText)
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(card.color == .red ? .white : (card.color == .wild ? .white : .black))
                                    }
                                    .shadow(color: card.isPlayable && gameModel.currentPlayer == .human ? .white : .clear, radius: 5)
                                    .scaleEffect(card.isPlayable && gameModel.currentPlayer == .human ? 1.05 : 1.0)
                                    .padding(.top, card.isPlayable && gameModel.currentPlayer == .human ? -10 : 0)
                                    .animation(.easeInOut(duration: 0.2), value: card.isPlayable && gameModel.currentPlayer == .human)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.bottom, 20)
                    }
                    .background(Color.black.opacity(0.5))
                }
            }
            
            // 颜色选择覆盖层
            if gameModel.gameStatus == .colorSelection {
                Color.black.opacity(0.7)
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)
                
                VStack {
                    Text("选择颜色")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding()
                    
                    HStack(spacing: 20) {
                        ForEach(CardColor.allCases.filter { $0 != .wild }, id: \.self) { color in
                            Button(action: {
                                withAnimation {
                                    gameModel.selectColor(color)
                                    arViewModel.updateDiscardPileCard(gameModel.discardPile.last!)
                                }
                            }) {
                                Circle()
                                    .fill(color.color)
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                    )
                                    .shadow(color: .white, radius: 5)
                            }
                        }
                    }
                }
            }
            
            // 游戏结束覆盖层
            if gameModel.gameStatus == .gameOver {
                Color.black.opacity(0.8)
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)
                
                VStack {
                    Text(gameModel.message)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .multilineTextAlignment(.center)
                    
                    // 胜利/失败图标
                    if gameModel.message.contains("恭喜") {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.yellow)
                            .padding()
                            .shadow(color: .yellow.opacity(0.8), radius: 10)
                    } else {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                            .padding()
                            .shadow(color: .red.opacity(0.8), radius: 10)
                    }
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            withAnimation(.spring()) {
                                gameModel.startNewGame()
                                arViewModel.resetARScene()
                            }
                        }) {
                            Text("再来一局")
                                .font(.headline)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .shadow(color: .blue.opacity(0.5), radius: 5)
                        }
                        
                        Button(action: {
                            withAnimation(.easeInOut) {
                                dismiss()
                            }
                        }) {
                            Text("返回主菜单")
                                .font(.headline)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .shadow(color: .red.opacity(0.5), radius: 5)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingRules) {
            RulesView()
        }
        .onReceive(gameModel.$currentPlayer) { newPlayer in
            if newPlayer == .computer && gameModel.gameStatus == .playing {
                // 仅在未处于其他动画中时执行电脑回合
                guard !isCardPlayed && !isComputerDrawing && !isCardDrawn else { return }
                
                // 电脑回合，延迟一点时间再行动
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    // 再次检查状态
                    if gameModel.currentPlayer == .computer && gameModel.gameStatus == .playing &&
                       !isCardPlayed && !isComputerDrawing && !isCardDrawn {
                        handleComputerTurn()
                    }
                }
            }
        }
        .onReceive(gameModel.$discardPile) { newDiscardPile in
            // 当弃牌堆变化时，更新AR场景中的顶部牌
            if let topCard = newDiscardPile.last {
                arViewModel.updateDiscardPileCard(topCard)
            }
        }
        .onAppear {
            // 开始游戏时设置初始状态
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if let topCard = gameModel.discardPile.last {
                    arViewModel.updateDiscardPileCard(topCard)
                }
                
                // 更新玩家手牌可出状态
                gameModel.updatePlayableCards()
            }
        }
    }
    
    // 处理电脑回合的逻辑
    private func handleComputerTurn() {
        let topCard = gameModel.discardPile.last!
        
        // 检查电脑是否有可出的牌
        let playableCards = gameModel.computerHand.filter { $0.canPlayOn(card: topCard) }
        
        if !playableCards.isEmpty {
            // 电脑有牌可出，触发出牌动画
            isCardPlayed = true
            
            // 让AR视图模型处理电脑出牌的动画
            arViewModel.simulateComputerCardPlay {
                isCardPlayed = false
                gameModel.computerTurn()
            }
        } else {
            // 电脑需要抽牌
            isComputerDrawing = true
            
            // 让AR视图模型处理电脑抽牌的动画
            arViewModel.animateDrawCard(isComputer: true) {
                isComputerDrawing = false
                gameModel.computerTurn()
            }
        }
    }
}

// AR视图容器
struct ARViewContainer: UIViewRepresentable {
    var arViewModel: ARViewModel
    var gameModel: GameModel
    
    func makeUIView(context: Context) -> ARView {
        return arViewModel.arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // 视图更新时的逻辑（如有必要）
    }
}

// AR视图模型，管理AR场景和3D交互
class ARViewModel: ObservableObject {
    let arView = ARView(frame: .zero)
    
    // 用于放置卡牌的锚点
    private var tableAnchor: AnchorEntity?
    private var deckEntity: ModelEntity?
    private var discardPileEntity: ModelEntity?
    private var computerHandEntity: AnchorEntity?
    
    // 标记AR状态
    @Published var hasFoundPlane = false
    @Published var hasPlacedBoard = false
    
    init() {
        setupARView()
    }
    
    private func setupARView() {
        // 配置AR会话
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        arView.session.run(configuration)
        
        // 添加平面检测回调
        arView.session.delegate = self
        
        // 添加点击手势识别器
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        arView.addGestureRecognizer(tapGesture)
    }
    
    @objc private func handleTap(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: arView)
        
        if !hasPlacedBoard {
            // 检查是否点击了平面
            let results = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal)
            
            if let firstResult = results.first {
                // 创建锚点并放置游戏区域
                placeGameBoard(at: firstResult)
                hasPlacedBoard = true
            }
        }
    }
    
    private func placeGameBoard(at raycastResult: ARRaycastResult) {
        // 创建锚点
        tableAnchor = AnchorEntity(world: raycastResult.worldTransform)
        
        // 创建游戏区域
        let gameBoard = createGameBoard()
        tableAnchor?.addChild(gameBoard)
        
        // 创建牌堆
        deckEntity = createDeckEntity()
        deckEntity?.position = [0.15, 0.01, 0]
        tableAnchor?.addChild(deckEntity!)
        
        // 创建弃牌堆位置
        discardPileEntity = createEmptyDiscardPileEntity()
        discardPileEntity?.position = [-0.15, 0.01, 0]
        tableAnchor?.addChild(discardPileEntity!)
        
        // 创建电脑手牌区域
        computerHandEntity = AnchorEntity()
        computerHandEntity?.position = [0, 0.01, -0.3]
        tableAnchor?.addChild(computerHandEntity!)
        
        // 添加到场景
        arView.scene.addAnchor(tableAnchor!)
        
        // 设置已放置游戏板标志
        DispatchQueue.main.async {
            self.hasPlacedBoard = true
        }
    }
    
    private func createGameBoard() -> ModelEntity {
        // 创建游戏桌面
        let boardMesh = MeshResource.generatePlane(width: 0.6, depth: 0.6)
        let boardMaterial = SimpleMaterial(color: .init(red: 0.1, green: 0.3, blue: 0.1, alpha: 1.0), isMetallic: false)
        let boardEntity = ModelEntity(mesh: boardMesh, materials: [boardMaterial])
        boardEntity.position = [0, 0, 0]
        
        // 添加碰撞组件
        boardEntity.collision = CollisionComponent(shapes: [.generateBox(width: 0.6, height: 0.01, depth: 0.6)])
        boardEntity.physicsBody = PhysicsBodyComponent(massProperties: .default, material: .default, mode: .static)
        
        return boardEntity
    }
    
    private func createDeckEntity() -> ModelEntity {
        // 创建牌堆的3D模型
        let cardSize = SIMD3<Float>(0.057, 0.002, 0.089)
        
        // 创建多层卡牌效果
        let cardStack = ModelEntity()
        
        for i in 0..<10 {
            let cardMesh = MeshResource.generateBox(size: cardSize)
            let cardMaterial = SimpleMaterial(color: .blue, isMetallic: false)
            let cardEntity = ModelEntity(mesh: cardMesh, materials: [cardMaterial])
            cardEntity.position = [0, Float(i) * 0.0005, 0]  // 向上堆叠
            cardStack.addChild(cardEntity)
        }
        
        // 添加碰撞组件
        cardStack.collision = CollisionComponent(shapes: [.generateBox(size: SIMD3<Float>(cardSize.x, cardSize.y * 10, cardSize.z))])
        
        return cardStack
    }
    
    private func createEmptyDiscardPileEntity() -> ModelEntity {
        // 创建一个空的弃牌堆位置标记
        let marker = MeshResource.generatePlane(width: 0.057, depth: 0.089)
        let material = SimpleMaterial(color: .init(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.5), isMetallic: false)
        let entity = ModelEntity(mesh: marker, materials: [material])
        return entity
    }
    
    func createCardEntity(for card: Card) -> ModelEntity {
        let cardSize = SIMD3<Float>(0.057, 0.002, 0.089)
        let cardMesh = MeshResource.generateBox(size: cardSize)
        
        // 根据卡牌类型确定材质颜色
        var cardColor: UIColor
        
        switch card.color {
        case .red:
            cardColor = .red
        case .blue:
            cardColor = .blue
        case .green:
            cardColor = .green
        case .yellow:
            cardColor = .yellow
        case .wild:
            cardColor = .black
        }
        
        let cardMaterial = SimpleMaterial(color: cardColor, isMetallic: false)
        let cardEntity = ModelEntity(mesh: cardMesh, materials: [cardMaterial])
        
        // 添加卡牌数字/文字
        let textMesh = MeshResource.generateText(card.displayText,
                                               extrusionDepth: 0.001,
                                               font: .systemFont(ofSize: 0.04),
                                               containerFrame: .zero,
                                               alignment: .center,
                                               lineBreakMode: .byTruncatingTail)
        
        let textColor: UIColor = (card.color == .red || card.color == .wild) ? .white : .black
        let textMaterial = SimpleMaterial(color: textColor, isMetallic: false)
        let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])
        
        // 调整文字位置，使其显示在卡牌表面
        textEntity.position = [0, 0.0011, 0]
        textEntity.scale = [0.5, 0.5, 0.5]
        cardEntity.addChild(textEntity)
        
        return cardEntity
    }
    
    func updateDiscardPileCard(_ card: Card) {
        guard let discardPileEntity = discardPileEntity else { return }
        
        // 移除当前弃牌堆的所有子实体
        discardPileEntity.children.forEach { $0.removeFromParent() }
        
        // 创建新的顶部卡牌实体
        let cardEntity = createCardEntity(for: card)
        discardPileEntity.addChild(cardEntity)
    }
    
    func animateDrawCard(isComputer: Bool, completion: @escaping () -> Void) {
        guard let deckEntity = deckEntity else {
            completion()
            return
        }
        
        // 创建一张通用卡牌背面
        let cardSize = SIMD3<Float>(0.057, 0.002, 0.089)
        let cardMesh = MeshResource.generateBox(size: cardSize)
        let cardMaterial = SimpleMaterial(color: .blue, isMetallic: false)
        let cardEntity = ModelEntity(mesh: cardMesh, materials: [cardMaterial])
        
        // 将卡牌添加到场景，初始位置与牌堆相同
        cardEntity.position = deckEntity.position
        tableAnchor?.addChild(cardEntity)
        
        // 创建动画
        var transform = cardEntity.transform
        transform.translation = isComputer ? [0, 0.1, -0.3] : [0, 0.1, 0.3]
        
        let animation = cardEntity.move(to: transform,
                                     relativeTo: tableAnchor,
                                     duration: 0.8,
                                     timingFunction: .easeInOut)
        
        // 设置动画完成回调
        animation.onCompletion = { _ in
            cardEntity.removeFromParent()
            completion()
        }
        
        // 播放动画
        animation.resume()
    }
    
    func animatePlayCard(card: Card, isComputer: Bool, completion: @escaping () -> Void) {
        guard let tableAnchor = tableAnchor, let discardPileEntity = discardPileEntity else {
            completion()
            return
        }
        
        // 创建卡牌实体
        let cardEntity = createCardEntity(for: card)
        
        // 设置初始位置
        if isComputer {
            cardEntity.position = [0, 0.05, -0.3]  // 电脑位置
        } else {
            cardEntity.position = [0, 0.05, 0.3]   // 玩家位置
        }
        
        tableAnchor.addChild(cardEntity)
        
        // 创建动画 - 移动到弃牌堆位置
        var transform = cardEntity.transform
        transform.translation = discardPileEntity.position + SIMD3<Float>(0, 0.005, 0)
        
        let animation = cardEntity.move(to: transform,
                                     relativeTo: tableAnchor,
                                     duration: 0.7,
                                     timingFunction: .easeInOut)
        
        // 设置动画完成回调
        animation.onCompletion = { _ in
            cardEntity.removeFromParent()
            completion()
        }
        
        // 播放动画
        animation.resume()
    }
    
    func simulateComputerCardPlay(completion: @escaping () -> Void) {
        // 从电脑手牌区域播放一张牌到弃牌堆
        let randomDelay = Double.random(in: 0.3...0.8)
        DispatchQueue.main.asyncAfter(deadline: .now() + randomDelay) {
            self.animatePlayCard(card: Card(color: .red, type: .number, value: 0), isComputer: true) {
                completion()
            }
        }
    }
    
    func resetARScene() {
        // 重置AR场景，保留桌面锚点但移除所有游戏实体
        if let tableAnchor = tableAnchor {
            // 清除弃牌堆
            discardPileEntity?.children.forEach { $0.removeFromParent() }
            
            // 重新创建牌堆
            deckEntity?.removeFromParent()
            deckEntity = createDeckEntity()
            deckEntity?.position = [0.15, 0.01, 0]
            tableAnchor.addChild(deckEntity!)
        }
    }
}

// ARSessionDelegate扩展
extension ARViewModel: ARSessionDelegate {
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if let planeAnchor = anchor as? ARPlaneAnchor, planeAnchor.alignment == .horizontal {
                // 检测到水平平面，提示用户点击放置游戏区域
                if !hasFoundPlane {
                    DispatchQueue.main.async {
                        // 可以在这里添加提示UI
                        // 比如: self.showPlacementHint = true
                    }
                }
            }
        }
    }
} 