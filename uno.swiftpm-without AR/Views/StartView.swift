import SwiftUI

struct StartView: View {
    @State private var showGame = false
    @State private var showRules = false
    @State private var animateTitle = false
    @State private var animateCards = false
    
    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.blue.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                // 标题
                Text("UNO")
                    .font(.system(size: 80, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .red, radius: 10, x: 0, y: 0)
                    .scaleEffect(animateTitle ? 1.2 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                        value: animateTitle
                    )
                    .onAppear {
                        animateTitle = true
                    }
                
                Spacer()
                
                // 卡牌动画
                HStack(spacing: -30) {
                    ForEach(0..<4) { index in
                        CardView(
                            card: Card(
                                color: [.red, .blue, .green, .yellow][index],
                                type: .number,
                                value: index + 1
                            ),
                            width: 80,
                            height: 120,
                            isPlayable: true
                        )
                        .rotationEffect(.degrees(Double(index * 5 - 7)))
                        .offset(y: animateCards ? -20 : 0)
                        .animation(
                            Animation.easeInOut(duration: 0.8)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                            value: animateCards
                        )
                    }
                }
                .onAppear {
                    animateCards = true
                }
                
                Spacer()
                
                // 开始按钮
                Button(action: {
                    showGame = true
                }) {
                    Text("开始游戏")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.vertical, 15)
                        .padding(.horizontal, 50)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.red)
                                .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 5)
                        )
                }
                .buttonStyle(PlainButtonStyle())
                
                // 规则按钮
                Button(action: {
                    showRules = true
                }) {
                    Text("游戏规则")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 30)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white, lineWidth: 2)
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 20)
                
                Spacer()
                
                // 版权信息
                Text("© 2025 杨远望 游戏")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, 20)
            }
            .padding()
        }
        .fullScreenCover(isPresented: $showGame) {
            GameView()
        }
        .sheet(isPresented: $showRules) {
            RulesView()
        }
    }
} 
