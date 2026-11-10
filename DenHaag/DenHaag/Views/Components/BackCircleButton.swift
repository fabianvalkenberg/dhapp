import SwiftUI

/// De ene terugknop van de app (design review 2026-11, Figma "Terugknop").
/// Altijd 43 pt rond met de blauwe Den Haag-pijl; alleen de vulling hangt af
/// van wat erachter ligt. Plaats hem met `.terugknopPlek()`: linksboven in het
/// grid, 8 pt onder de statusbalk.
struct BackCircleButton: View {
    @EnvironmentObject private var lang: LanguageManager

    enum Stijl {
        /// Op wit: warm-grijs rondje zonder rand.
        case wit
        /// Op een gekleurd vlak (lichtblauw, geel): wit rondje met grijze rand.
        case kleur
        /// Op een foto: glazen rondje met witte pijl.
        case foto
    }

    var stijl: Stijl
    var action: () -> Void

    init(stijl: Stijl = .wit, action: @escaping () -> Void) {
        self.stijl = stijl
        self.action = action
    }

    static let maat: CGFloat = 43

    var body: some View {
        Button(action: action) {
            Image("arrow-left")
                .renderingMode(.template)
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundColor(stijl == .foto ? .white : AppColors.blauw3)
                .frame(width: Self.maat, height: Self.maat)
                .background(achtergrond)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(AppColors.grijs2, lineWidth: stijl == .kleur ? 1 : 0)
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(lang.t("terug")))
    }

    @ViewBuilder private var achtergrond: some View {
        switch stijl {
        case .wit: Color(hex: "F2F2F1")
        case .kleur: Color.white
        case .foto: ZStack { Rectangle().fill(.ultraThinMaterial); Color.white.opacity(0.2) }
        }
    }
}

extension AppDesign {
    /// Afstand tussen de onderkant van de statusbalk en de terugknop.
    static let terugknopTop: CGFloat = 8
}

extension View {
    /// Zet een terugknop (of de balk waar hij in staat) op de vaste plek:
    /// links op de grid-marge, 8 pt onder de statusbalk. Staat de container zelf
    /// al onder de statusbalk (respecteert hij de safe area), geef dan
    /// `binnenSafeArea: true`.
    func terugknopPlek(binnenSafeArea: Bool = false) -> some View {
        self
            .padding(.leading, AppDesign.horizontalPadding)
            .padding(.top, (binnenSafeArea ? 0 : AppDesign.safeAreaTop) + AppDesign.terugknopTop)
    }
}
