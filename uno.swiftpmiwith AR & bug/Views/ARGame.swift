import SwiftUI

// 导出AR相关组件使其可被其他文件访问
@_exported import ARKit
@_exported import RealityKit

// 重新导出ARSimpleView
@_exported import struct NMO.ARSimpleView

// 确保引用可用性
#if canImport(ARSimpleView)
@_exported import ARSimpleView
#else
// 如果ARSimpleView找不到，提供一个简单的占位符
public struct ARSimpleViewFallback: View {
    @Environment(\.dismiss) private var dismiss
    
    public var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack {
                Text("AR UNO")
                    .font(.title)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("AR功能暂时不可用")
                    .font(.headline)
                    .foregroundColor(.white)
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
    }
}
#endif

// 简化的AR视图容器
struct ARViewContainer: UIViewRepresentable {
    var arViewModel: ARSimpleViewModel
    
    func makeUIView(context: Context) -> ARView {
        return arViewModel.arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // 无需更新
    }
}

// 简化的AR视图模型
class ARSimpleViewModel: ObservableObject {
    let arView = ARView(frame: .zero)
    
    init() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        arView.session.run(configuration)
    }
}

#if canImport(ARGameView)
// 如果可以直接导入ARGameView，则导入
@_exported import ARGameView
#else
// 否则重新声明一个简单版本的ARGameView，以便编译通过
struct ARGameViewFallback: View {
    var body: some View {
        Text("AR模式不可用")
            .font(.title)
            .foregroundColor(.white)
            .padding()
            .background(Color.black.opacity(0.7))
            .cornerRadius(10)
    }
}

public typealias ARGameView = ARGameViewFallback
#endif 