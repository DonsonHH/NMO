import SwiftUI

struct WithFadeOut<Content: View>: View {
    let content: Content
    let duration: Double
    let delay: Double
    
    @State private var isVisible = true
    
    init(duration: Double, delay: Double, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.duration = duration
        self.delay = delay
    }
    
    var body: some View {
        content
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.easeInOut(duration: duration)) {
                        isVisible = false
                    }
                }
            }
    }
}

// 便捷扩展
extension View {
    func withFadeOut(duration: Double = 1.0, delay: Double = 0) -> some View {
        WithFadeOut(duration: duration, delay: delay) {
            self
        }
    }
} 