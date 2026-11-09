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
    /// Illustratievak: altijd even groot, zodat iconen op één lijn staan.
    private var illustrationHeight: CGFloat { (illustrationSize * 0.93).rounded() }
    private var tileHeight: CGFloat { compact ? 140 : 166 }
    private var titleSize: CGFloat { compact ? 16 : 18 }
    private var padding: CGFloat { compact ? 16 : 24 }

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

    /// Design review 2026-11 ("Tiles uitlijning"): vaste opbouw van boven naar
    /// beneden, zodat elke tegel even hoog is en iconen en labels per rij op
    /// één lijn staan. Illustratie in een vast vak bovenin, label in een vak
    /// van max. twee regels direct eronder; de tegel zelf is vast 166 hoog.
    private var content: some View {
        VStack(spacing: 10) {
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
            .frame(width: illustrationSize, height: illustrationHeight)

            Text(title)
                .font(AppFont.theSans(size: titleSize, weight: .bold))
                .foregroundColor(isSelected ? .white : AppColors.darkGrey)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, padding)
        .padding(.top, padding)
        .frame(maxWidth: .infinity)
        .frame(height: tileHeight, alignment: .top)
        .background(isSelected ? AppColors.groen3 : AppColors.warmGrijs)
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(isSelected ? Color.clear : AppColors.tegelBorder, lineWidth: 1)
        )
    }
}
