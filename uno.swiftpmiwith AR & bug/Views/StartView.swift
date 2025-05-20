import SwiftUI
import ARKit
import RealityKit

// 简化的AR视图，用于解决引用问题
fileprivate struct ARSimpleView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack {
                Text("AR UNO")
                    .font(.title)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("AR功能加载中...")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                    .padding()
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Text("返回主菜单")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding()
            }
            .padding()
        }
        .onAppear {
            // 尝试加载完整AR视图
            // 这里可以添加异步加载AR资源的代码
        }
    }
}

// 使用新的ARSimpleView替代原来的ARGameView
struct ARGameView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        // 使用新创建的ARSimpleView
        ARSimpleView()
    }
}

struct StartView: View {
    @State private var showGame = false
    @State private var showARGame = false
    @State private var showRules = false
    @State private var animateTitle = false
    @State private var animateCards = false
    @State private var showARNotSupportedAlert = false
    
    // 检查设备是否支持AR
    private var isARSupported: Bool {
        return ARWorldTrackingConfiguration.isSupported
    }
    
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
                
                // 游戏模式按钮
                VStack(spacing: 20) {
                    // 标准模式按钮
                    Button(action: {
                        showGame = true
                    }) {
                        Text("标准模式")
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
                    
                    // AR模式按钮
                    Button(action: {
                        if isARSupported {
                            showARGame = true
                        } else {
                            showARNotSupportedAlert = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "arkit")
                                .font(.system(size: 20))
                            Text("AR模式")
                                .font(.system(size: 24, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 15)
                        .padding(.horizontal, 50)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(isARSupported ? Color.green : Color.gray)
                                .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 5)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!isARSupported)
                }
                
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
        .fullScreenCover(isPresented: $showARGame) {
            ARGameView()
        }
        .sheet(isPresented: $showRules) {
            RulesView()
        }
        .alert(isPresented: $showARNotSupportedAlert) {
            Alert(
                title: Text("设备不支持AR"),
                message: Text("您的设备不支持增强现实功能，请使用标准模式进行游戏。"),
                dismissButton: .default(Text("确定"))
            )
        }
    }
} 
