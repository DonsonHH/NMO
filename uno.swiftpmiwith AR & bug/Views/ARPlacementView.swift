import SwiftUI

struct ARPlacementView: View {
    @ObservedObject var arViewModel: ARViewModel
    
    var body: some View {
        ZStack {
            if !arViewModel.hasFoundPlane {
                VStack {
                    Spacer()
                    
                    // 提示用户移动设备以检测平面
                    VStack(spacing: 15) {
                        Image(systemName: "iphone.radiowaves.left.and.right")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                        
                        Text("请在周围移动设备")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("寻找平坦的平面表面")
                            .font(.callout)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.7))
                    )
                    .padding(.bottom, 50)
                } 
            } else if arViewModel.hasFoundPlane && !arViewModel.hasPlacedBoard {
                VStack {
                    Spacer()
                    
                    // 提示用户点击平面放置游戏桌面
                    VStack(spacing: 15) {
                        Image(systemName: "hand.tap")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                        
                        Text("点击平面以放置游戏桌面")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("游戏将在您选择的位置进行")
                            .font(.callout)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.7))
                    )
                    .padding(.bottom, 50)
                }
            }
        }
    }
}

struct SceneStartHint: View {
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 40))
                .foregroundColor(.white)
            
            Text("AR游戏已开始")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("牌堆和弃牌区已固定在平面上")
                .font(.callout)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.7))
        )
        .transition(.opacity)
    }
} 