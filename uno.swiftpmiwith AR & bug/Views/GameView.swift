import SwiftUI

struct GameView: View {
    @StateObject private var gameModel = GameModel()
    @State private var showingRules = false
    @Environment(\.dismiss) private var dismiss
    
    // 动画状态
    @State private var isCardDrawn = false
    @State private var isCardPlayed = false
    @State private var animatedCard: Card?
    @State private var animationOffset: CGSize = .zero
    @State private var animationRotation: Double = 0
    @State private var animationScale: CGFloat = 1.0
    @State private var deckShakeAmount: CGFloat = 0
    @State private var deckGlowAmount: CGFloat = 0
    @State private var isComputerDrawing = false
    @State private var messageOpacity: Double = 1.0 // 消息闪烁效果的透明度
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景
                LinearGradient(
                    gradient: Gradient(colors: [Color.black, Color.blue.opacity(0.5), Color.black]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                
                // 游戏内容
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
                    
                    // 电脑手牌（背面朝上）
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: -15) {
                            ForEach(0..<gameModel.computerHand.count, id: \.self) { index in
                                CardBackView(width: 60, height: 90)
                                    .rotationEffect(.degrees(Double.random(in: -2...2)))
                                    .offset(y: index % 2 == 0 ? -2 : 2)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    // 中间区域：弃牌堆和牌堆
                    HStack(spacing: 40) {
                        // 牌堆
                        ZStack {
                            // 底层牌堆效果
                            ForEach(0..<3) { i in
                                CardBackView(width: 80, height: 120)
                                    .offset(x: CGFloat(i) * 1, y: CGFloat(i) * 1)
                                    .opacity(0.8 - Double(i) * 0.2)
                            }
                            
                            // 顶层可点击牌堆
                            Button(action: {
                                drawCardWithAnimation(geometry: geometry)
                            }) {
                                CardBackView(width: 80, height: 120)
                                    .overlay(
                                        VStack {
                                            Text("抽牌")
                                                .font(.headline)
                                                .foregroundColor(gameModel.shouldHighlightDrawButton ? .yellow : .white)
                                                .padding(5)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 5)
                                                        .fill(gameModel.shouldHighlightDrawButton ? 
                                                             Color.red.opacity(0.8) : Color.black.opacity(0.7))
                                                )
                                                .scaleEffect(gameModel.shouldHighlightDrawButton ? 1.2 : 1.0)
                                            
                                            if gameModel.shouldHighlightDrawButton {
                                                Image(systemName: "arrow.down.circle.fill")
                                                    .font(.system(size: 20))
                                                    .foregroundColor(.yellow)
                                                    .padding(.top, 5)
                                            }
                                        }
                                        .offset(y: 45)
                                    )
                                    .shadow(color: gameModel.shouldHighlightDrawButton ? 
                                            Color.yellow.opacity(0.8) : 
                                            (gameModel.currentPlayer == .human && gameModel.gameStatus == .playing ? 
                                             Color.white.opacity(deckGlowAmount) : Color.clear), 
                                            radius: gameModel.shouldHighlightDrawButton ? 15 : 10)
                                    .overlay(
                                        gameModel.shouldHighlightDrawButton ?
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.yellow, lineWidth: 3)
                                                .opacity(deckGlowAmount)
                                            : nil
                                    )
                            }
                            .disabled(gameModel.currentPlayer != .human || gameModel.gameStatus != .playing)
                            .offset(x: deckShakeAmount)
                            .animation(
                                Animation.spring(response: 0.2, dampingFraction: 0.2)
                                    .repeatCount(3, autoreverses: true),
                                value: deckShakeAmount
                            )
                            .onAppear {
                                // 添加牌堆呼吸效果
                                withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                    deckGlowAmount = 0.6
                                }
                            }
                            .onChange(of: gameModel.shouldHighlightDrawButton) { needsHighlight in
                                // 当需要高亮抽牌时，添加抖动效果
                                if needsHighlight {
                                    deckShakeAmount = 5
                                    // 一段时间后停止抖动但保持高亮
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                        withAnimation {
                                            deckShakeAmount = 0
                                        }
                                    }
                                }
                            }
                        }
                        
                        // 弃牌堆
                        ZStack {
                            // 底层弃牌堆效果
                            ForEach(0..<min(3, gameModel.discardPile.count - 1), id: \.self) { i in
                                if gameModel.discardPile.count > i + 1 {
                                    let card = gameModel.discardPile[gameModel.discardPile.count - i - 2]
                                    CardView(
                                        card: card,
                                        width: 80,
                                        height: 120,
                                        isPlayable: false
                                    )
                                    .rotationEffect(.degrees(Double.random(in: -5...5)))
                                    .offset(x: CGFloat.random(in: -3...3), y: CGFloat.random(in: -3...3))
                                    .opacity(1.0 - Double(i) * 0.3)
                                }
                            }
                            
                            // 顶层牌
                            if let topCard = gameModel.discardPile.last {
                                CardView(
                                    card: topCard,
                                    width: 80,
                                    height: 120,
                                    isPlayable: false
                                )
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .slide),
                                    removal: .opacity
                                ))
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white, lineWidth: 2)
                                    .frame(width: 80, height: 120)
                            }
                        }
                    }
                    
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
                        .opacity(messageOpacity) // 应用闪烁效果的透明度
                        .onChange(of: gameModel.message) { newMessage in
                            // 检查消息是否包含"没有可出的牌"
                            if newMessage.contains("没有可出的牌") {
                                // 创建闪烁动画
                                withAnimation(Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                                    messageOpacity = 0.5
                                }
                            } else {
                                withAnimation {
                                    messageOpacity = 1.0
                                }
                            }
                        }
                    
                    // 最近三回合出牌历史记录
                    RecentPlayedCardsView(playerCards: gameModel.playerPlayedCards, computerCards: gameModel.computerPlayedCards)
                        .padding(.vertical, 5)
                    
                    // 当前玩家指示
                    Text(gameModel.currentPlayer == .human ? "你的回合" : "电脑回合")
                        .font(.headline)
                        .foregroundColor(gameModel.currentPlayer == .human ? .green : .red)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 15)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.7))
                                .overlay(
                                    Capsule()
                                        .stroke(gameModel.currentPlayer == .human ? .green : .red, lineWidth: 2)
                                )
                        )
                        .padding(.bottom)
                    
                    Spacer()
                    
                    // 玩家手牌
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: -15) {
                            ForEach(gameModel.playerHand) { card in
                                CardView(
                                    card: card,
                                    width: 70,
                                    height: 105,
                                    isPlayable: card.isPlayable && gameModel.currentPlayer == .human && gameModel.gameStatus == .playing
                                ) {
                                    playCardWithAnimation(card)
                                }
                                .padding(.bottom, card.isPlayable && gameModel.currentPlayer == .human ? 20 : 0)
                                .rotationEffect(.degrees(Double.random(in: -2...2)))
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .scale.combined(with: .opacity)
                                ))
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom)
                }
                
                // 动画中的卡牌
                if let card = animatedCard {
                    if isCardDrawn || isComputerDrawing {
                        // 抽牌动画显示卡牌背面
                        CardBackView(width: 70, height: 105)
                            .offset(animationOffset)
                            .rotationEffect(.degrees(animationRotation))
                            .scaleEffect(animationScale)
                            .opacity(isCardDrawn || isComputerDrawing ? 1 : 0)
                            .shadow(color: .white, radius: 5)
                    } else if isCardPlayed {
                        // 出牌动画显示卡牌正面
                        CardView(
                            card: card,
                            width: 70,
                            height: 105,
                            isPlayable: false
                        )
                        .offset(animationOffset)
                        .rotationEffect(.degrees(animationRotation))
                        .scaleEffect(animationScale)
                        .opacity(isCardPlayed ? 1 : 0)
                        .shadow(color: .white, radius: 5)
                    }
                }
                
                // 颜色选择覆盖层
                if gameModel.gameStatus == .colorSelection {
                    Color.black.opacity(0.7)
                        .edgesIgnoringSafeArea(.all)
                        .transition(.opacity)
                    
                    ColorSelectionView { color in
                        withAnimation(.spring()) {
                            gameModel.selectColor(color)
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
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
                    .padding(30)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.black.opacity(0.9), Color.blue.opacity(0.3)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: .white.opacity(0.3), radius: 15)
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .sheet(isPresented: $showingRules) {
                RulesView()
            }
            .onReceive(gameModel.$currentPlayer) { newPlayer in
                if newPlayer == .computer && gameModel.gameStatus == .playing {
                    // 添加状态检查以避免重复触发
                    guard !isCardPlayed && !isComputerDrawing else { return }
                    
                    // 创建一个任务标识符，防止重复执行
                    let taskID = UUID()
                    let currentTaskID = taskID
                    
                    // 电脑回合，延迟一点时间再行动，让玩家能看清楚
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        // 检查是否是最新的任务，防止多个任务同时执行
                        guard currentTaskID == taskID else { return }
                        
                        // 再次检查当前玩家，因为可能在延迟期间已经改变
                        if gameModel.currentPlayer == .computer && gameModel.gameStatus == .playing &&
                           !isCardPlayed && !isComputerDrawing {
                            // 检查电脑是否有可出的牌
                            let hasPlayableCard = gameModel.computerHand.contains { card in
                                if let topCard = gameModel.discardPile.last {
                                    return canPlayCard(card, after: topCard)
                                }
                                return true
                            }
                            
                            if !hasPlayableCard {
                                // 电脑需要抽牌
                                computerDrawCardWithAnimation(geometry: geometry)
                            } else {
                                // 电脑有可出的牌，直接出牌
                                computerPlayCardWithAnimation()
                            }
                        }
                    }
                }
            }
            .onReceive(gameModel.$playerHand) { newHand in
                // 监听玩家手牌变化，检查是否有可出的牌
                if gameModel.currentPlayer == .human && gameModel.gameStatus == .playing {
                    // 检查玩家是否有可出的牌
                    let hasPlayableCard = newHand.contains { card in
                        if let topCard = gameModel.discardPile.last {
                            return card.isPlayable && canPlayCard(card, after: topCard)
                        }
                        return false
                    }
                    
                    // 如果没有可出的牌，且手牌状态已经更新过，自动抽牌
                    if !hasPlayableCard && !isCardDrawn && !isCardPlayed {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            // 再次检查，确保状态没有变化，并且没有可出的牌
                            if gameModel.currentPlayer == .human && gameModel.gameStatus == .playing {
                                let stillNoPlayableCard = !gameModel.playerHand.contains { $0.isPlayable }
                                if stillNoPlayableCard {
                                    drawCardWithAnimation(geometry: geometry)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // 判断卡牌是否可以出
    private func canPlayCard(_ card: Card, after topCard: Card) -> Bool {
        // 通配牌总是可以出
        if card.color == .wild {
            return true
        }
        
        // 颜色相同或者类型/数值相同
        return card.color == topCard.color || 
               (card.type == topCard.type && card.type != .number) || 
               (card.type == .number && topCard.type == .number && card.value == topCard.value)
    }
    
    // 抽牌动画
    private func drawCardWithAnimation(geometry: GeometryProxy) {
        // 防止玩家连续点击抽牌按钮
        guard !isCardDrawn && !isCardPlayed && !isComputerDrawing else { return }
        
        // 设置动画初始状态
        // 使用不可见的卡牌而不是通配牌，避免显示错误
        let drawnCard = Card(color: .red, type: .number, value: 0) // 临时卡牌用于动画
        animatedCard = drawnCard
        animationOffset = CGSize(width: 0, height: 0)
        animationRotation = 0
        animationScale = 1.0
        isCardDrawn = true
        
        // 隐藏动画卡牌的内容，仅显示背面效果
        animationScale = 0.001 // 几乎不可见，但动画效果仍然存在
        
        // 牌堆抖动效果
        deckShakeAmount = 3
        
        // 简单的抽牌动画 - 从牌堆到手牌，增加动画时间
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
            animationOffset = CGSize(width: 0, height: 200)
            animationRotation = Double.random(in: -10...10)
            animationScale = 1.0 // 逐渐变大
        }
        
        // 动画结束后执行实际抽牌逻辑，增加延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.2)) {
                isCardDrawn = false
                deckShakeAmount = 0
                animationScale = 0.001 // 动画结束后再次缩小
            }
            
            // 执行实际抽牌
            gameModel.drawCard()
        }
    }
    
    // 电脑抽牌动画
    private func computerDrawCardWithAnimation(geometry: GeometryProxy) {
        // 设置动画初始状态
        // 使用不可见的卡牌而不是通配牌，避免显示错误
        let drawnCard = Card(color: .red, type: .number, value: 0) // 临时卡牌用于动画
        animatedCard = drawnCard
        animationOffset = CGSize(width: 0, height: 0)
        animationRotation = 0
        animationScale = 0.001 // 几乎不可见
        isComputerDrawing = true
        
        // 牌堆抖动效果
        deckShakeAmount = 3
        
        // 简单的抽牌动画 - 从牌堆到电脑手牌，增加动画时间
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
            animationOffset = CGSize(width: 0, height: -200)
            animationRotation = Double.random(in: -10...10)
            animationScale = 1.0 // 逐渐变大
        }
        
        // 动画结束后执行实际抽牌逻辑，增加延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.2)) {
                isComputerDrawing = false
                deckShakeAmount = 0
                animationScale = 0.001 // 动画结束后再次缩小
            }
            
            // 执行实际抽牌
            if gameModel.currentPlayer == .computer {
                gameModel.computerTurn() // 使用现有的computerTurn方法
            }
            
            // 在自动抽牌的情况下，不再进行任何额外检查，避免电脑在被禁止的回合中出牌
        }
    }
    
    // 出牌动画
    private func playCardWithAnimation(_ card: Card) {
        // 设置动画初始状态
        animatedCard = card
        animationOffset = CGSize(width: 0, height: 100)
        animationRotation = Double.random(in: -5...5)
        animationScale = 1.0
        isCardPlayed = true
        
        // 播放出牌动画 - 增加动画时间
        withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
            animationOffset = CGSize(width: 0, height: -50)
            animationRotation = Double.random(in: -20...20)
        }
        
        // 动画结束后执行实际出牌逻辑 - 增加延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.2)) {
                isCardPlayed = false
            }
            
            // 执行实际出牌
            gameModel.playCard(card)
        }
    }
    
    // 电脑出牌动画
    private func computerPlayCardWithAnimation() {
        // 找出电脑可以出的牌
        if let cardToPlay = findComputerCardToPlay() {
            // 设置动画初始状态
            animatedCard = cardToPlay
            animationOffset = CGSize(width: 0, height: -100)
            animationRotation = Double.random(in: -5...5)
            animationScale = 1.0
            isCardPlayed = true
            
            // 播放出牌动画 - 增加动画时间
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
                animationOffset = CGSize(width: 0, height: 50)
                animationRotation = Double.random(in: -20...20)
            }
            
            // 动画结束后执行实际出牌逻辑 - 增加延迟
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeOut(duration: 0.2)) {
                    isCardPlayed = false
                }
                
                // 执行实际出牌 - 使用现有的computerTurn方法
                if gameModel.currentPlayer == .computer {
                    gameModel.computerTurn()
                }
            }
        } else {
            // 如果没有可出的牌，增加延迟后执行电脑回合
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if gameModel.currentPlayer == .computer {
                    gameModel.computerTurn()
                }
            }
        }
    }
    
    // 辅助方法：找出电脑可以出的牌
    private func findComputerCardToPlay() -> Card? {
        if let topCard = gameModel.discardPile.last {
            // 找出第一张可以出的牌
            return gameModel.computerHand.first { card in
                return canPlayCard(card, after: topCard)
            }
        }
        return nil
    }
}

// 显示最近三个回合出牌历史的视图组件
struct RecentPlayedCardsView: View {
    let playerCards: [Card]
    let computerCards: [Card]
    
    var body: some View {
        VStack(spacing: 5) {
            Text("出牌记录 (当前第\(playerCards.last?.round ?? computerCards.last?.round ?? 1)回合)")
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(Color.black.opacity(0.7))
                .cornerRadius(5)
            
            HStack(spacing: 5) {
                // 玩家出牌历史
                VStack(alignment: .leading, spacing: 2) {
                    Text("你:")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    HStack(spacing: 2) {
                        if playerCards.isEmpty {
                            Text("暂无")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(5)
                        } else {
                            ForEach(playerCards) { card in
                                MiniCardView(card: card)
                            }
                        }
                    }
                }
                .padding(5)
                .background(Color.black.opacity(0.3))
                .cornerRadius(5)
                
                Spacer().frame(width: 10)
                
                // 电脑出牌历史
                VStack(alignment: .leading, spacing: 2) {
                    Text("电脑:")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    
                    HStack(spacing: 2) {
                        if computerCards.isEmpty {
                            Text("暂无")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(5)
                        } else {
                            ForEach(computerCards) { card in
                                MiniCardView(card: card)
                            }
                        }
                    }
                }
                .padding(5)
                .background(Color.black.opacity(0.3))
                .cornerRadius(5)
            }
        }
        .padding(.horizontal)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.5))
                .shadow(color: .white.opacity(0.1), radius: 3)
        )
        .padding(.horizontal)
    }
}

// 迷你卡牌视图
struct MiniCardView: View {
    let card: Card
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(card.color == .wild ? Color.black : card.color.color)
                .frame(width: 35, height: 30)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                )
            
            Text(card.displayText)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(card.color == .red ? .white : (card.color == .wild ? .white : .black))
            
            // 显示回合数
            if card.round > 0 {
                Text("\(card.round)")
                    .font(.system(size: 8))
                    .foregroundColor(.white)
                    .padding(2)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(4)
                    .offset(x: 12, y: -12)
            }
        }
    }
}

