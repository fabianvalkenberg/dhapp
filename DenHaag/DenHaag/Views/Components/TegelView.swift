import SwiftUI

/// Subtiele schaal-feedback bij indrukken — geeft tegels een tactiel gevoel.
struct PressableScaleStyle: ButtonStyle {
    var scale: CGFloat = 0.96
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Herbruikbare tegel volgens Figma-component `tegel` (node 2834:1296).
/// - Achtergrond #F8F7F5, border 1px #EBEAE6, radius 3, padding 24.
/// - Illustratie boven, titel TheSans C4s Bold 18 in #2D2D2D, gecentreerd.
/// - Selected-state: groene vulling met witte content (gebruikt in onboarding).
struct TegelView: View {
    let illustration: String
    let title: String
    var isSelected: Bool = false
    /// Compacte variant voor de Regelen-ticker.
    var compact: Bool = false
    var action: (() -> Void)? = nil

    private var illustrationSize: CGFloat { compact ? 54 : 70 }
    private var minHeight: CGFloat { compact ? 140 : 166 }
    private var titleSize: CGFloat { compact ? 16 : 18 }

    var body: some View {
        Group {
            if let action {
                Button(action: action) { content }
                    .buttonStyle(PressableScaleStyle())
            } else {
                content
            }
        }
    }

    private var content: some View {
        VStack(spacing: 12) {
            // Een naam met "sf:"-prefix valt terug op een SF Symbol (voor tegels
            // zonder eigen illustratie, zoals "Naar de bieb"); anders een asset.
            Group {
                if illustration.hasPrefix("sf:") {
                    Image(systemName: String(illustration.dropFirst(3)))
                        .font(.system(size: illustrationSize * 0.78, weight: .regular))
                        .foregroundColor(isSelected ? .white : AppColors.groen3)
                } else {
                    Image(illustration)
                        .resizable()
                        .scaledToFit()
                }
            }
            .frame(width: illustrationSize, height: illustrationSize * 0.93)

            Text(title)
                .font(AppFont.theSans(size: titleSize, weight: .bold))
                .foregroundColor(isSelected ? .white : AppColors.darkGrey)
                .multilineTextAlignment(.center)
                .lineSpacing(1)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .frame(minHeight: minHeight)
        .background(isSelected ? AppColors.groen3 : AppColors.warmGrijs)
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(isSelected ? Color.clear : AppColors.tegelBorder, lineWidth: 1)
        )
    }
}
