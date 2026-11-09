import SwiftUI

struct SplashView: View {
    @State private var logoOpacity: Double = 0
    @State private var logoScale: CGFloat = 0.9

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            Image("DH-logo")
                .resizable()
                .scaledToFit()
                .frame(width: 140)
                .opacity(logoOpacity)
                .scaleEffect(logoScale)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                logoOpacity = 1
                logoScale = 1
            }
        }
    }
}
