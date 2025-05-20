import SwiftUI

struct CardView: View {
    let card: Card
    let width: CGFloat
    let height: CGFloat
    let isPlayable: Bool
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        Button(action: {
            if isPlayable, let onTap = onTap {
                onTap()
            }
        }) {
            ZStack {
                // 卡牌背景
                RoundedRectangle(cornerRadius: 12)
                    .fill(card.color.color)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white, lineWidth: 3)
                    )
                    .shadow(color: isPlayable ? .white.opacity(0.6) : .black.opacity(0.3), radius: isPlayable ? 5 : 2)
                
                // 卡牌内部椭圆
                if card.color != .wild {
                    Ellipse()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: width * 0.75, height: height * 0.75)
                        .rotationEffect(.degrees(45))
                }
                
                // 卡牌文字
                if card.type == .number {
                    // 数字牌
                    VStack {
                        Text(card.displayText)
                            .font(.system(size: width * 0.4, weight: .bold))
                            .foregroundColor(card.color.color)
                            .shadow(color: .white.opacity(0.5), radius: 1)
                    }
                } else {
                    // 特殊牌
                    VStack {
                        Text(card.displayText)
                            .font(.system(size: width * 0.35, weight: .bold))
                            .foregroundColor(card.color == .wild ? .white : card.color.color)
                            .shadow(color: card.color == .wild ? .white.opacity(0.5) : .black.opacity(0.3), radius: 1)
                            .padding(.bottom, 2)
                        
                        // 特殊牌图标
                        if card.type == .skip {
                            Image(systemName: "slash.circle")
                                .font(.system(size: width * 0.25))
                                .foregroundColor(card.color == .wild ? .white : card.color.color)
                        } else if card.type == .reverse {
                            Image(systemName: "arrow.2.squarepath")
                                .font(.system(size: width * 0.25))
                                .foregroundColor(card.color == .wild ? .white : card.color.color)
                        } else if card.type == .drawTwo {
                            Image(systemName: "plus.circle")
                                .font(.system(size: width * 0.25))
                                .foregroundColor(card.color == .wild ? .white : card.color.color)
                        } else if card.type == .wild {
                            HStack(spacing: 2) {
                                Circle().fill(Color.red).frame(width: width * 0.12, height: width * 0.12)
                                Circle().fill(Color.blue).frame(width: width * 0.12, height: width * 0.12)
                                Circle().fill(Color.green).frame(width: width * 0.12, height: width * 0.12)
                                Circle().fill(Color.yellow).frame(width: width * 0.12, height: width * 0.12)
                            }
                        } else if card.type == .wildDrawFour {
                            HStack(spacing: 2) {
                                Circle().fill(Color.red).frame(width: width * 0.1, height: width * 0.1)
                                Circle().fill(Color.blue).frame(width: width * 0.1, height: width * 0.1)
                                Circle().fill(Color.green).frame(width: width * 0.1, height: width * 0.1)
                                Circle().fill(Color.yellow).frame(width: width * 0.1, height: width * 0.1)
                            }
                        }
                    }
                }
                
                // 卡牌边角数字/符号
                if card.type == .number {
                    VStack {
                        HStack {
                            Text(card.displayText)
                                .font(.system(size: width * 0.2, weight: .bold))
                                .foregroundColor(card.color.color)
                                .padding(5)
                            
                            Spacer()
                        }
                        
                        Spacer()
                        
                        HStack {
                            Spacer()
                            
                            Text(card.displayText)
                                .font(.system(size: width * 0.2, weight: .bold))
                                .foregroundColor(card.color.color)
                                .padding(5)
                                .rotationEffect(.degrees(180))
                        }
                    }
                }
            }
            .frame(width: width, height: height)
            .opacity(isPlayable ? 1.0 : 0.8)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPlayable ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPlayable)
    }
}

struct CardBackView: View {
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        ZStack {
            // 卡牌背景
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black, Color.black.opacity(0.7)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white, lineWidth: 3)
                )
                .shadow(color: .black.opacity(0.5), radius: 3)
            
            // 中间椭圆
            Ellipse()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.red, Color.blue]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: width * 0.7, height: height * 0.6)
                .rotationEffect(.degrees(45))
                .overlay(
                    Ellipse()
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: width * 0.7, height: height * 0.6)
                        .rotationEffect(.degrees(45))
                )
            
            // UNO标志
            Text("UNO")
                .font(.system(size: width * 0.3, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: .black, radius: 2)
        }
        .frame(width: width, height: height)
    }
}

struct ColorSelectionView: View {
    let onColorSelected: (CardColor) -> Void
    @State private var animateColors = false
    
    var body: some View {
        VStack {
            Text("选择颜色")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding()
            
            HStack(spacing: 20) {
                ForEach([CardColor.red, CardColor.blue, CardColor.green, CardColor.yellow], id: \.self) { color in
                    Button(action: {
                        onColorSelected(color)
                    }) {
                        Circle()
                            .fill(color.color)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                            )
                            .shadow(color: .white.opacity(0.5), radius: 5)
                            .scaleEffect(animateColors ? 1.1 : 1.0)
                            .animation(
                                Animation.spring(response: 0.3, dampingFraction: 0.6)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double([.red, .blue, .green, .yellow].firstIndex(of: color)!) * 0.1),
                                value: animateColors
                            )
                    }
                }
            }
            .onAppear {
                animateColors = true
            }
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.9))
                .shadow(color: .white.opacity(0.2), radius: 10)
        )
    }
} 