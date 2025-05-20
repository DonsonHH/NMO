import SwiftUI

@MainActor
class GameModel: ObservableObject {
    @Published var deck: [Card] = []
    @Published var discardPile: [Card] = []
    @Published var playerHand: [Card] = []
    @Published var computerHand: [Card] = []
    @Published var currentPlayer: Player = .human
    @Published var gameDirection: GameDirection = .clockwise
    @Published var selectedColor: CardColor?
    @Published var gameStatus: GameStatus = .playing
    @Published var message: String = ""
    @Published var playerPlayedCards: [Card] = [] // 玩家最近出的牌
    @Published var computerPlayedCards: [Card] = [] // 电脑最近出的牌
    @Published var currentRound: Int = 1 // 当前回合数
    @Published var shouldHighlightDrawButton: Bool = false // 是否应该高亮抽牌按钮
    
    // 递归计数器，用于防止无限循环
    private var recursionCount: Int = 0
    
    // 防止重复抽牌的标志
    private var isDrawingInProgress: Bool = false
    // 防止重复切换回合的标志
    private var isSwitchingTurn: Bool = false
    
    enum Player {
        case human, computer
    }
    
    enum GameDirection {
        case clockwise, counterClockwise
    }
    
    enum GameStatus {
        case playing, colorSelection, gameOver
    }
    
    init() {
        startNewGame()
    }
    
    func startNewGame() {
        // 重置游戏状态
        deck = []
        discardPile = []
        playerHand = []
        computerHand = []
        playerPlayedCards = [] // 重置玩家出牌记录
        computerPlayedCards = [] // 重置电脑出牌记录
        currentPlayer = .human
        gameDirection = .clockwise
        selectedColor = nil
        gameStatus = .playing
        message = "游戏开始！"
        currentRound = 1 // 重置回合数
        
        // 创建一副新牌
        createDeck()
        
        // 洗牌
        deck.shuffle()
        
        // 发牌
        dealInitialCards()
        
        // 翻开第一张牌
        if let firstCard = deck.popLast() {
            // 确保第一张牌不是特殊牌
            if firstCard.type != .number {
                // 如果是特殊牌，将其放回牌堆并重新洗牌
                deck.append(firstCard)
                deck.shuffle()
                startNewGame()
                return
            }
            discardPile.append(firstCard)
        }
        
        // 更新玩家手牌的可玩状态
        updatePlayableCards()
    }
    
    private func createDeck() {
        // 创建数字牌 (0-9)
        for color in CardColor.allCases where color != .wild {
            // 每种颜色一张0
            deck.append(Card(color: color, type: .number, value: 0))
            
            // 每种颜色两张1-9
            for value in 1...9 {
                deck.append(Card(color: color, type: .number, value: value))
                deck.append(Card(color: color, type: .number, value: value))
            }
            
            // 每种颜色两张特殊牌
            for _ in 0...1 {
                deck.append(Card(color: color, type: .skip, value: -1))
                deck.append(Card(color: color, type: .reverse, value: -1))
                deck.append(Card(color: color, type: .drawTwo, value: -1))
            }
        }
        
        // 添加万能牌
        for _ in 0...3 {
            deck.append(Card(color: .wild, type: .wild, value: -1))
            deck.append(Card(color: .wild, type: .wildDrawFour, value: -1))
        }
    }
    
    private func dealInitialCards() {
        // 确保玩家初始手牌有良好的分布
        var playerCards: [Card] = []
        var computerCards: [Card] = []
        
        // 临时牌堆，用于发牌
        var tempDeck = deck
        
        // 为玩家选择至少2种颜色的牌，确保起手较好
        var playerColors = Set<CardColor>()
        
        // 先为玩家挑选5张牌，确保颜色多样性
        while playerCards.count < 5 && !tempDeck.isEmpty {
            // 找到不同颜色的牌
            let colorOptions = tempDeck.filter { card in
                return card.color != .wild && !playerColors.contains(card.color)
            }
            
            if let card = colorOptions.first {
                let index = tempDeck.firstIndex(where: { $0.id == card.id })!
                playerCards.append(tempDeck.remove(at: index))
                playerColors.insert(card.color)
            } else {
                // 如果没有新颜色，则随机抽一张
                let randomIndex = Int.random(in: 0..<tempDeck.count)
                playerCards.append(tempDeck.remove(at: randomIndex))
            }
        }
        
        // 再随机抽2张牌给玩家
        for _ in 0..<2 {
            if tempDeck.isEmpty { break }
            let randomIndex = Int.random(in: 0..<tempDeck.count)
            playerCards.append(tempDeck.remove(at: randomIndex))
        }
        
        // 为电脑选择7张牌
        for _ in 0..<7 {
            if tempDeck.isEmpty { break }
            let randomIndex = Int.random(in: 0..<tempDeck.count)
            computerCards.append(tempDeck.remove(at: randomIndex))
        }
        
        // 更新牌堆和手牌
        deck = tempDeck
        playerHand = playerCards
        computerHand = computerCards
    }
    
    func updatePlayableCards() {
        guard let topCard = discardPile.last else { return }
        
        if currentPlayer == .human {
            var hasPlayableCard = false
            for i in 0..<playerHand.count {
                playerHand[i].isPlayable = playerHand[i].canPlayOn(card: topCard)
                if playerHand[i].isPlayable {
                    hasPlayableCard = true
                }
            }
            
            // 如果玩家没有可以打出的牌，显示提示并高亮抽牌按钮
            if !hasPlayableCard && gameStatus == .playing {
                message = "你没有可出的牌，请抽一张牌"
                shouldHighlightDrawButton = true
            } else {
                shouldHighlightDrawButton = false
            }
        }
    }
    
    func playCard(_ card: Card) {
        guard gameStatus == .playing else { return }
        guard currentPlayer == .human else { return }
        guard let index = playerHand.firstIndex(where: { $0.id == card.id }) else { return }
        
        let playedCard = playerHand.remove(at: index)
        discardPile.append(playedCard)
        
        // 记录玩家出的牌
        addToPlayedCards(playedCard, isPlayer: true)
        
        // 处理特殊牌效果
        let skipOpponentTurn = handleSpecialCardAndReturnSkipStatus(playedCard)
        
        // 检查游戏是否结束
        if playerHand.isEmpty {
            gameStatus = .gameOver
            message = "恭喜！你赢了！"
            return
        }
        
        // 如果不需要选择颜色，且不需要跳过对手回合，才切换到电脑回合
        if gameStatus != .colorSelection && !skipOpponentTurn {
            switchTurn()
        }
    }
    
    func drawCard() {
        guard gameStatus == .playing else { return }
        guard currentPlayer == .human else { return }
        // 防止重复抽牌
        guard !isDrawingInProgress else { return }
        
        // 设置抽牌状态为进行中
        isDrawingInProgress = true
        
        // 如果牌堆为空，重新洗牌
        if deck.isEmpty {
            reshuffleDeck()
        }
        
        // 清除高亮抽牌按钮的状态
        shouldHighlightDrawButton = false
        
        // 运气机制：玩家抽牌时，优先抽取能打出的牌
        if let topCard = discardPile.last {
            // 先检查牌堆中是否有玩家能打出的牌
            let playableIndex = deck.firstIndex { card in
                return card.canPlayOn(card: topCard)
            }
            
            if let index = playableIndex {
                // 找到可打出的牌，将其移到牌堆顶部（不明显地）
                let luckyCard = deck.remove(at: index)
                let drawnCard = luckyCard
                playerHand.append(drawnCard)
                
                // 检查抽到的牌是否可以出
                if let index = playerHand.firstIndex(where: { $0.id == drawnCard.id }) {
                    // 标记为可出的牌
                    playerHand[index].isPlayable = true
                    // 提示玩家可以打出这张牌
                    message = "抽到了\(colorName(drawnCard.color))\(drawnCard.displayText)，可以打出！"
                    // 更新其他牌的可出状态
                    updatePlayableCards()
                    // 抽牌结束
                    isDrawingInProgress = false
                    // 不切换回合，让玩家可以打出刚抽到的牌
                    return
                } else {
                    message = "你抽了一张牌"
                }
            } else {
                // 没有找到可打出的牌，正常抽牌
                if let drawnCard = deck.popLast() {
                    playerHand.append(drawnCard)
                    
                    // 检查抽到的牌是否可以出
                    if drawnCard.canPlayOn(card: topCard) {
                        if let index = playerHand.firstIndex(where: { $0.id == drawnCard.id }) {
                            // 标记为可出的牌
                            playerHand[index].isPlayable = true
                            // 提示玩家可以打出这张牌
                            message = "抽到了\(colorName(drawnCard.color))\(drawnCard.displayText)，可以打出！"
                            // 更新其他牌的可出状态
                            updatePlayableCards()
                            // 抽牌结束
                            isDrawingInProgress = false
                            // 不切换回合，让玩家可以打出刚抽到的牌
                            return
                        }
                    } else {
                        message = "你抽了一张牌，但不能打出"
                        // 抽到的牌不能出，切换到电脑回合
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒延迟
                            isDrawingInProgress = false
                            switchTurn()
                        }
                        return
                    }
                }
            }
        } else {
            // 没有顶部牌，正常抽牌
            if let drawnCard = deck.popLast() {
                playerHand.append(drawnCard)
                message = "你抽了一张牌"
            }
        }
        
        // 主动抽牌后无法出牌，直接结束回合
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒延迟
            isDrawingInProgress = false
            switchTurn()
        }
    }
    
    func selectColor(_ color: CardColor) {
        guard gameStatus == .colorSelection else { return }
        
        // 更新顶部牌的颜色
        if var topCard = discardPile.last {
            discardPile.removeLast()
            topCard = Card(color: color, type: topCard.type, value: topCard.value)
            discardPile.append(topCard)
        }
        
        gameStatus = .playing
        message = "你选择了\(colorName(color))色"
        
        // 继续游戏
        switchTurn()
    }
    
    private func colorName(_ color: CardColor) -> String {
        switch color {
        case .red: return "红"
        case .blue: return "蓝"
        case .green: return "绿"
        case .yellow: return "黄"
        case .wild: return "万能"
        }
    }
    
    private func handleSpecialCardAndReturnSkipStatus(_ card: Card) -> Bool {
        switch card.type {
        case .skip:
            message = "跳过对手回合！"
            // 跳过对手回合，需要玩家继续
            updatePlayableCards() // 立即更新玩家可出的牌
            return true
            
        case .reverse:
            message = "方向反转！"
            gameDirection = gameDirection == .clockwise ? .counterClockwise : .clockwise
            // 在双人游戏中，反转相当于跳过对手回合
            updatePlayableCards() // 立即更新玩家可出的牌
            return true
            
        case .drawTwo:
            message = "对手抽两张牌！"
            // 电脑抽两张牌
            for _ in 0...1 {
                if deck.isEmpty {
                    reshuffleDeck()
                }
                if let card = deck.popLast() {
                    computerHand.append(card)
                }
            }
            return false
            
        case .wild, .wildDrawFour:
            if card.type == .wildDrawFour {
                message = "对手抽四张牌！请选择颜色"
                // 电脑抽四张牌
                for _ in 0...3 {
                    if deck.isEmpty {
                        reshuffleDeck()
                    }
                    if let card = deck.popLast() {
                        computerHand.append(card)
                    }
                }
            } else {
                message = "请选择颜色"
            }
            
            // 进入颜色选择状态
            gameStatus = .colorSelection
            return false
            
        default:
            return false
        }
    }
    
    private func reshuffleDeck() {
        // 保留顶部牌
        let topCard = discardPile.removeLast()
        
        // 将弃牌堆洗入牌堆
        deck.append(contentsOf: discardPile)
        discardPile.removeAll()
        
        // 洗牌但提高玩家获得好牌的机会
        // 将一些好牌（万能、+4、反转、跳过等）放在牌堆中间位置
        // 让玩家更可能抽到这些牌
        let specialCards = deck.filter { $0.type != .number }
        let normalCards = deck.filter { $0.type == .number }
        
        if !specialCards.isEmpty && !normalCards.isEmpty {
            // 确保特殊牌更集中在牌堆中间偏上的位置
            deck = []
            let lowerPart = normalCards.prefix(normalCards.count / 3)
            let middlePart = specialCards
            let upperPart = normalCards.suffix(normalCards.count - normalCards.count / 3)
            
            deck.append(contentsOf: lowerPart)
            deck.append(contentsOf: middlePart)
            deck.append(contentsOf: upperPart)
            deck.shuffle() // 轻微打乱，但保持特殊牌大致在中间偏上位置
        } else {
            deck.shuffle()
        }
        
        // 放回顶部牌
        discardPile.append(topCard)
    }
    
    func switchTurn() {
        // 防止重复切换回合
        guard !isSwitchingTurn else { return }
        
        // 设置切换回合状态为进行中
        isSwitchingTurn = true
        
        currentPlayer = currentPlayer == .human ? .computer : .human
        
        // 如果从电脑切换到玩家，回合数加1
        if currentPlayer == .human {
            currentRound += 1
        }
        
        if currentPlayer == .computer {
            // 电脑回合 - 增加延迟
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5秒
                // 重置切换回合标志
                isSwitchingTurn = false
                computerTurn()
            }
        } else {
            // 玩家回合 - 增加短暂延迟后更新可出牌状态
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3秒
                // 重置切换回合标志
                isSwitchingTurn = false
                updatePlayableCards()
            }
        }
    }
    
    func computerTurn() {
        guard currentPlayer == .computer else { return }
        guard gameStatus == .playing else { return }
        guard let topCard = discardPile.last else { return }
        
        // 增加递归计数
        recursionCount += 1
        
        // 如果递归次数过多，防止无限循环
        if recursionCount > 3 {
            recursionCount = 0
            message = "电脑结束回合"
            isSwitchingTurn = false // 确保可以切换回合
            switchTurn()
            return
        }
        
        // 运气机制：有20%的概率电脑会做出次优选择
        let makesOptimalChoice = Double.random(in: 0...1) > 0.2
        
        // 查找可以打出的牌
        var playableCards = computerHand.indices.filter { index in
            return computerHand[index].canPlayOn(card: topCard)
        }
        
        if !playableCards.isEmpty {
            // 找到可以打出的牌
            var selectedIndex: Int = playableCards[0] // 默认值，避免可能的未初始化错误
            
            if makesOptimalChoice {
                // 电脑做出最优选择
                // 优先级：特殊牌 > 数字牌，同时尽量选择电脑手中最多的颜色
                
                // 计算各颜色的数量
                var colorCounts: [CardColor: Int] = [:]
                for card in computerHand where card.color != .wild {
                    colorCounts[card.color, default: 0] += 1
                }
                let dominantColor = colorCounts.max(by: { $0.value < $1.value })?.key
                
                // 优先选择特殊牌
                let specialCardIndices = playableCards.filter { computerHand[$0].type != .number }
                
                if !specialCardIndices.isEmpty {
                    // 在特殊牌中优先选择跳过/反转/+2/+4
                    let priorityTypes: [CardType] = [.wildDrawFour, .drawTwo, .skip, .reverse, .wild]
                    
                    var foundPriorityCard = false
                    for type in priorityTypes {
                        let typeIndices = specialCardIndices.filter { computerHand[$0].type == type }
                        if !typeIndices.isEmpty {
                            selectedIndex = typeIndices[0]
                            foundPriorityCard = true
                            break
                        }
                    }
                    // 如果没找到优先级高的特殊牌，随机选一张特殊牌
                    if !foundPriorityCard {
                        selectedIndex = specialCardIndices[0]
                    }
                } else {
                    // 如果没有特殊牌，尽量选择占主导的颜色
                    if let color = dominantColor {
                        let colorIndices = playableCards.filter { computerHand[$0].color == color }
                        if !colorIndices.isEmpty {
                            selectedIndex = colorIndices[0]
                        } else {
                            // 如果主导颜色没有可出的牌，随机选择一张
                            selectedIndex = playableCards[0]
                        }
                    } else {
                        // 没有明显的主导颜色，随机选择
                        selectedIndex = playableCards[0]
                    }
                }
            } else {
                // 电脑做出次优选择，随机从可出的牌中选一张
                // 优先避开使用强力牌，如+4、+2、跳过等
                
                // 过滤掉强力牌
                let nonPowerCardIndices = playableCards.filter { 
                    computerHand[$0].type != .wildDrawFour && 
                    computerHand[$0].type != .drawTwo &&
                    computerHand[$0].type != .skip &&
                    computerHand[$0].type != .reverse
                }
                
                if !nonPowerCardIndices.isEmpty {
                    // 从非强力牌中随机选择
                    let randomIndex = Int.random(in: 0..<nonPowerCardIndices.count)
                    selectedIndex = nonPowerCardIndices[randomIndex]
                } else {
                    // 如果只有强力牌，也随机选一张
                    let randomIndex = Int.random(in: 0..<playableCards.count)
                    selectedIndex = playableCards[randomIndex]
                }
            }
            
            // 打出选择的牌
            let playedCard = computerHand.remove(at: selectedIndex)
            discardPile.append(playedCard)
            
            // 记录电脑出的牌
            addToPlayedCards(playedCard, isPlayer: false)
            
            message = "电脑打出了一张牌"
            
            // 处理特殊牌
            var skipPlayerTurn = false
            
            if playedCard.type == .skip {
                message = "电脑打出跳过牌！跳过你的回合"
                skipPlayerTurn = true
            } else if playedCard.type == .reverse {
                message = "电脑打出反转牌！跳过你的回合"
                gameDirection = gameDirection == .clockwise ? .counterClockwise : .clockwise
                skipPlayerTurn = true
            } else if playedCard.type == .drawTwo {
                message = "电脑打出+2！你抽两张牌"
                // 玩家抽两张牌
                for _ in 0...1 {
                    if deck.isEmpty {
                        reshuffleDeck()
                    }
                    if let card = deck.popLast() {
                        playerHand.append(card)
                    }
                }
            } else if playedCard.type == .wild || playedCard.type == .wildDrawFour {
                // 电脑选择颜色
                var colorCounts: [CardColor: Int] = [:]
                
                for card in computerHand where card.color != .wild {
                    colorCounts[card.color, default: 0] += 1
                }
                
                let selectedColor = colorCounts.max(by: { $0.value < $1.value })?.key ?? CardColor.allCases.randomElement() ?? .red
                
                // 更新顶部牌的颜色
                discardPile.removeLast()
                let newCard = Card(color: selectedColor, type: playedCard.type, value: playedCard.value)
                discardPile.append(newCard)
                
                if playedCard.type == .wildDrawFour {
                    message = "电脑打出+4并选择了\(colorName(selectedColor))色！你抽四张牌"
                    // 玩家抽四张牌
                    for _ in 0...3 {
                        if deck.isEmpty {
                            reshuffleDeck()
                        }
                        if let card = deck.popLast() {
                            playerHand.append(card)
                        }
                    }
                } else {
                    message = "电脑打出变色牌并选择了\(colorName(selectedColor))色"
                }
            }
            
            // 检查电脑是否获胜
            if computerHand.isEmpty {
                gameStatus = .gameOver
                message = "电脑赢了！游戏结束"
                recursionCount = 0 // 重置递归计数
                return
            }
            
            // 如果应该跳过玩家回合，电脑继续
            if skipPlayerTurn {
                // 重置递归计数，以便下一次调用可以从0开始
                recursionCount = 0
                
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒
                    isSwitchingTurn = false // 确保可以开始新回合
                    computerTurn()
                }
                return
            }
            
            // 电脑出完牌后，轮到玩家
            recursionCount = 0 // 重置递归计数
            isSwitchingTurn = false // 确保可以切换回合
            switchTurn()
            return
        } else {
            // 没有可以打出的牌，抽一张
            if deck.isEmpty {
                reshuffleDeck()
            }
            
            if let drawnCard = deck.popLast() {
                computerHand.append(drawnCard)
                
                // 检查抽到的牌是否可以出
                if drawnCard.canPlayOn(card: topCard) {
                    message = "电脑抽了一张牌，并打出了它"
                    
                    // 将抽到的牌打出
                    let drawnIndex = computerHand.firstIndex(where: { $0.id == drawnCard.id })!
                    let playedCard = computerHand.remove(at: drawnIndex)
                    discardPile.append(playedCard)
                    
                    // 记录电脑出的牌
                    addToPlayedCards(playedCard, isPlayer: false)
                    
                    // 处理特殊牌效果
                    if playedCard.type == .skip {
                        message = "电脑抽到并打出跳过牌！跳过你的回合"
                        // 电脑继续
                        recursionCount = 0
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒
                            isSwitchingTurn = false // 确保可以开始新回合
                            computerTurn()
                        }
                        return
                    } else if playedCard.type == .reverse {
                        message = "电脑抽到并打出反转牌！跳过你的回合"
                        gameDirection = gameDirection == .clockwise ? .counterClockwise : .clockwise
                        // 电脑继续
                        recursionCount = 0
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒
                            isSwitchingTurn = false // 确保可以开始新回合
                            computerTurn()
                        }
                        return
                    } else if playedCard.type == .wild || playedCard.type == .wildDrawFour {
                        // 选择颜色
                        var colorCounts: [CardColor: Int] = [:]
                        for card in computerHand where card.color != .wild {
                            colorCounts[card.color, default: 0] += 1
                        }
                        let selectedColor = colorCounts.max(by: { $0.value < $1.value })?.key ?? CardColor.allCases.randomElement() ?? .red
                        
                        // 更新顶部牌的颜色
                        discardPile.removeLast()
                        let newCard = Card(color: selectedColor, type: playedCard.type, value: playedCard.value)
                        discardPile.append(newCard)
                        
                        if playedCard.type == .wildDrawFour {
                            message = "电脑抽到并打出+4，选择了\(colorName(selectedColor))色！你抽四张牌"
                            // 玩家抽四张牌
                            for _ in 0...3 {
                                if deck.isEmpty { reshuffleDeck() }
                                if let card = deck.popLast() {
                                    playerHand.append(card)
                                }
                            }
                        } else {
                            message = "电脑抽到并打出变色牌，选择了\(colorName(selectedColor))色"
                        }
                    } else if playedCard.type == .drawTwo {
                        message = "电脑抽到并打出+2！你抽两张牌"
                        // 玩家抽两张牌
                        for _ in 0...1 {
                            if deck.isEmpty { reshuffleDeck() }
                            if let card = deck.popLast() {
                                playerHand.append(card)
                            }
                        }
                    }
                    
                    // 检查电脑是否获胜
                    if computerHand.isEmpty {
                        gameStatus = .gameOver
                        message = "电脑赢了！游戏结束"
                        recursionCount = 0
                        return
                    }
                    
                    // 轮到玩家
                    recursionCount = 0
                    isSwitchingTurn = false // 确保可以切换回合
                    switchTurn()
                    return
                } else {
                    // 抽到的牌不能出
                    message = "电脑没有可出的牌，抽了一张牌并结束回合"
                    
                    // 电脑抽牌后直接结束回合，不再尝试打出抽到的牌
                    recursionCount = 0 // 重置递归计数
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒延迟
                        // 确保当前仍然是电脑回合
                        if currentPlayer == .computer {
                            isSwitchingTurn = false // 确保可以切换回合
                            switchTurn()
                        }
                    }
                    return
                }
            } else {
                // 牌堆已空且无法重新洗牌，轮到玩家
                recursionCount = 0 // 重置递归计数
                isSwitchingTurn = false // 确保可以切换回合
                switchTurn()
                return
            }
        }
    }
    
    // 添加新方法来管理已出牌记录
    private func addToPlayedCards(_ card: Card, isPlayer: Bool) {
        var playedCard = card
        playedCard.round = currentRound // 记录当前回合数
        
        if isPlayer {
            // 只保留最近的三张牌
            if playerPlayedCards.count >= 3 {
                playerPlayedCards.removeFirst()
            }
            playerPlayedCards.append(playedCard)
        } else {
            // 只保留最近的三张牌
            if computerPlayedCards.count >= 3 {
                computerPlayedCards.removeFirst()
            }
            computerPlayedCards.append(playedCard)
        }
    }
} 
