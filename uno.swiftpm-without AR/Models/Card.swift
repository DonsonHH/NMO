import SwiftUI

enum CardColor: String, CaseIterable {
    case red, blue, green, yellow, wild
    
    var color: Color {
        switch self {
        case .red: return .red
        case .blue: return .blue
        case .green: return .green
        case .yellow: return .yellow
        case .wild: return .black
        }
    }
}

enum CardType: String, CaseIterable {
    case number, skip, reverse, drawTwo, wild, wildDrawFour
    
    var symbol: String {
        switch self {
        case .number: return ""
        case .skip: return "禁"
        case .reverse: return "反"
        case .drawTwo: return "+2"
        case .wild: return "变"
        case .wildDrawFour: return "+4"
        }
    }
}

struct Card: Identifiable, Equatable {
    let id = UUID()
    let color: CardColor
    let type: CardType
    let value: Int
    
    var isPlayable: Bool = true
    var round: Int = 0 // 记录出牌时的回合数
    
    static func == (lhs: Card, rhs: Card) -> Bool {
        return lhs.color == rhs.color && lhs.type == rhs.type && lhs.value == rhs.value
    }
    
    var displayText: String {
        if type == .number {
            return "\(value)"
        } else {
            return type.symbol
        }
    }
    
    func canPlayOn(card: Card) -> Bool {
        // 万能牌可以在任何牌上打出
        if color == .wild {
            return true
        }
        
        // 颜色相同可以打出
        if color == card.color {
            return true
        }
        
        // 数字或类型相同可以打出
        if type == .number && card.type == .number && value == card.value {
            return true
        }
        
        if type == card.type && type != .number {
            return true
        }
        
        return false
    }
} 