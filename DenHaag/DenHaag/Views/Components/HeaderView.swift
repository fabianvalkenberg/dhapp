import SwiftUI

// MARK: - Home status-kaart (Figma node 2818-250)

/// Eén chip in de detail-regel bovenin een home-kaart (optioneel icoon + tekst).
struct CardChip: Identifiable {
    let id = UUID()
    let icon: String?      // asset-naam; nil = alleen tekst
    let text: String
}

/// Actie die de knop op een home-kaart uitvoert.
enum HomeCardAction {
    case appointment
    case aanvraag
    case paspoort
    case kwijtschelding
    case none
}

/// Klein, kalm pulserend groen bolletje (markeert het eind van de voortgangsbalk).
struct PulsingDot: View {
    @State private var pulse = false
    var body: some View {
        ZStack {
            Circle()
                .fill(AppColors.groen3.opacity(0.35))
                .frame(width: 18, height: 18)
                .scaleEffect(pulse ? 1.0 : 0.4)
                .opacity(pulse ? 0 : 0.6)
            Circle()
                .fill(AppColors.groen3)
                .frame(width: 9, height: 9)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.7).repeatForever(autoreverses: false)) { pulse = true }
        }
    }
}

/// Status-/actiekaart in de gele home-header. Twee varianten in het design:
/// een afspraak-kaart (gevulde groene knop) en een status-kaart met
/// voortgangsbalk (groene outline-knop).
struct HomeStatusCard: Identifiable {
    let id = UUID()
    let details: [CardChip]
    let title: String
    let titleSize: CGFloat     // Figma: kaart 1 = 22, kaart 2 = 20
    let progress: Double?      // nil = geen voortgangsbalk
    let buttonText: String
    let buttonFilled: Bool     // true = gevuld vlak, false = outline
    let borderColor: Color?    // gouden accent-rand (alleen kaart 1, #e3c012)
    let action: HomeCardAction
    var buttonTint: Color = AppColors.groen3  // knop-accentkleur (default groen)

    static let homeCards: [HomeStatusCard] = [
        HomeStatusCard(
            details: [
                CardChip(icon: "calendar", text: "6 juni om 09:00"),
                CardChip(icon: "location-pin", text: "Spui"),
            ],
            title: "Afspraak: nieuw paspoort",
            titleSize: 22,
            progress: nil,
            buttonText: "Bekijk afspraak",
            buttonFilled: true,
            borderColor: Color(hex: "EED249"),
            action: .appointment
        ),
        HomeStatusCard(
            details: [CardChip(icon: nil, text: "Status aanvraag uitbouw")],
            title: "Volgende week antwoord",
            titleSize: 20,
            progress: 191.0 / 251.0,
            buttonText: "Bekijk aanvraag",
            buttonFilled: true,
            borderColor: Color(hex: "EED249"),
            action: .aanvraag
        ),
        HomeStatusCard(
            details: [CardChip(icon: nil, text: "Dit is een herinnering.")],
            title: "Je paspoort verloopt in juli.",
            titleSize: 22,
            progress: nil,
            buttonText: "Aanvragen",
            buttonFilled: true,
            borderColor: Color(hex: "EED249"),
            action: .paspoort,
            buttonTint: AppColors.blauw3
        ),
        HomeStatusCard(
            details: [CardChip(icon: nil, text: "Status kwijtschelding")],
            title: "Je aanvraag is in behandeling",
            titleSize: 20,
            progress: 2.0 / 4.0,
            buttonText: "Bekijk aanvraag",
            buttonFilled: true,
            borderColor: Color(hex: "EED249"),
            action: .kwijtschelding
        ),
    ]
}

// MARK: - Arch Shape (for large header bottom)

/// Animatable bottom transition shape — notch for small header, arch for large header
private struct BottomTransitionShape: Shape {
    var isLarge: Bool

    func path(in rect: CGRect) -> Path {
        if isLarge {
            return archPath(in: rect)
        } else {
            return notchPath(in: rect)
        }
    }

    /// Wide gentle arch: sides at top, middle dips down
    private func archPath(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        path.move(to: CGPoint(x: 0, y: 0))
        path.addQuadCurve(
            to: CGPoint(x: w, y: 0),
            control: CGPoint(x: w / 2, y: h)
        )
        path.addLine(to: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.closeSubpath()
        return path
    }

    /// Small notch tab (same as NotchShape)
    private func notchPath(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        path.move(to: CGPoint(x: 0, y: 0))
        let curveStartX = w * 0.339
        path.addLine(to: CGPoint(x: curveStartX, y: 0))

        let bottomY = h * 0.86
        let leftBottomX = w * 0.386
        path.addCurve(
            to: CGPoint(x: leftBottomX, y: bottomY),
            control1: CGPoint(x: curveStartX + (leftBottomX - curveStartX) * 0.4, y: 0),
            control2: CGPoint(x: curveStartX + (leftBottomX - curveStartX) * 0.7, y: bottomY)
        )

        let rightBottomX = w * 0.592
        path.addLine(to: CGPoint(x: rightBottomX, y: bottomY))

        let curveEndX = w * 0.642
        path.addCurve(
            to: CGPoint(x: curveEndX, y: 0),
            control1: CGPoint(x: rightBottomX + (curveEndX - rightBottomX) * 0.3, y: bottomY),
            control2: CGPoint(x: rightBottomX + (curveEndX - rightBottomX) * 0.6, y: 0)
        )

        path.addLine(to: CGPoint(x: w, y: 0))
        path.addLine(to: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.closeSubpath()
        return path
    }
}

// MARK: - Header

struct HeaderView: View {
    @EnvironmentObject var lang: LanguageManager
    @ObservedObject var settings: HomeSettingsModel
    var onSettingsTapped: () -> Void = {}
    var onAppointmentTapped: () -> Void = {}
    var onKwijtscheldingTapped: () -> Void = {}
    var onAanvraagTapped: () -> Void = {}
    var onPaspoortTapped: () -> Void = {}
    var scrollOffset: CGFloat = 0

    @State private var currentPage: Int = 0
    @State private var scrolledID: Int?
    /// Schermbreedte één keer bepalen i.p.v. elke render via UIScreen.main.bounds.
    @State private var screenW: CGFloat = UIScreen.main.bounds.width
    @State private var facettenOffset: CGFloat = 0
    @State private var cardsRevealed = false

    private var activeCards: [HomeStatusCard] {
        HomeStatusCard.homeCards
    }

    private var safeTop: CGFloat { AppDesign.safeAreaTop }

    private var greetingText: String {
        // "Hi <naam>," — valt terug op Anne als er in de onboarding niets is opgegeven.
        "Hi \(settings.greetingName),"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Settings button (top right)
            HStack {
                Spacer()
                Button(action: onSettingsTapped) {
                    Image("user")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 24, height: 24)
                        .padding(10)
                        .background(Color.white.opacity(0.5))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, AppDesign.horizontalPadding + 6)
            .padding(.top, safeTop + 8)

            // Greeting + subtext ("Dit loopt er nu:")
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    // Figma: TheMixB W8 ExtraBold 38 #1d1a0d
                    .font(AppFont.theMix(size: 38, weight: .extraBold))
                    .foregroundColor(Color(hex: "1D1A0D"))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: screenW * 0.68, alignment: .leading)

                Text("Dit loopt er nu:")
                    .font(AppFont.theMix(size: 22, weight: .semiBold))
                    .foregroundColor(Color(hex: "1D1A0D"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppDesign.horizontalPadding + 6)
            .padding(.top, 12)
            .padding(.bottom, 0)

            // Paging carousel
            let cardWidth = screenW - 104

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(activeCards.enumerated()), id: \.element.id) { index, card in
                        StatusCardView(card: card, settings: settings, isActive: currentPage == index) { action in
                            switch action {
                            case .appointment: onAppointmentTapped()
                            case .aanvraag: onAanvraagTapped()
                            case .paspoort: onPaspoortTapped()
                            case .kwijtschelding: onKwijtscheldingTapped()
                            case .none: break
                            }
                        }
                        .frame(width: cardWidth)
                        .background(
                            GeometryReader { cardGeo in
                                Color.clear.preference(
                                    key: CardCenterKey.self,
                                    value: [index: abs(cardGeo.frame(in: .global).midX - screenW / 2)]
                                )
                            }
                        )
                        .id(index)
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, AppDesign.horizontalPadding + 6)
                .padding(.top, 16)
            }
            .scrollClipDisabled()
            .scrollTargetBehavior(.viewAligned)
            .frame(height: settings.cardShadows ? 230 : 210)
            .scrollPosition(id: $scrolledID)
            // Begrens de carrousel horizontaal: het peekende kaartje kan zo niet
            // buiten het scherm (en achter een andere tab) lekken. Verticaal vrij.
            .clipShape(HorizontalOverflowClip())
            .onPreferenceChange(CardCenterKey.self) { distances in
                if let closest = distances.min(by: { $0.value < $1.value })?.key,
                   closest != currentPage {
                    currentPage = closest
                }
            }
            // Bij het openen schuiven de kaartjes van rechts in; in rust zit er
            // dus nog niets onder "Hi Anne".
            .offset(x: cardsRevealed ? 0 : screenW)
            .opacity(cardsRevealed ? 1 : 0)

            // Page indicators
            HStack(spacing: 8) {
                ForEach(Array(activeCards.indices), id: \.self) { index in
                    Capsule()
                        .fill(index == currentPage ? AppColors.groen3 : Color.white)
                        .frame(
                            width: index == currentPage ? 24 : 8,
                            height: 8
                        )
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentPage)
            .padding(.top, 8)
            .opacity(cardsRevealed ? 1 : 0)

            // Bottom arch space
            Color.clear.frame(height: 8)
            Color.clear.frame(height: 50)
        }
        .background(
            GeometryReader { geo in
                let parallaxX = -CGFloat(currentPage) * 20
                Image("facetten-geel")
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: geo.size.width * 1.4,
                        height: geo.size.height * 1.4
                    )
                    .position(
                        x: geo.size.width / 2 + parallaxX + facettenOffset,
                        y: geo.size.height / 2 - scrollOffset * 0.06
                    )
                    .animation(.spring(response: 0.8, dampingFraction: 0.65), value: currentPage)
            }
            .ignoresSafeArea(edges: .top)
            .clipped()
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 30).repeatForever(autoreverses: true)) {
                facettenOffset = 25
            }
            // Kaartjes laten inschuiven van rechts naar links bij het openen —
            // bewust traag met een lange, zachte uitloop (easeOutExpo).
            if !cardsRevealed {
                withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: 1.5).delay(0.35)) {
                    cardsRevealed = true
                }
            }
        }
        .overlay(alignment: .bottom) {
            BottomTransitionShape(isLarge: true)
                .fill(AppColors.background)
                .frame(height: 50)
                .allowsHitTesting(false)
        }
        .padding(.bottom, 12)
    }
}

// MARK: - Card center tracking (voor paginatie-dots)

struct CardCenterKey: PreferenceKey {
    static var defaultValue: [Int: CGFloat] = [:]
    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        value.merge(nextValue()) { _, new in new }
    }
}

// MARK: - Status-kaart (home-header)

struct StatusCardView: View {
    let card: HomeStatusCard
    @ObservedObject var settings: HomeSettingsModel
    var isActive: Bool = false
    var onAction: (HomeCardAction) -> Void = { _ in }

    /// Voortgang loopt vol zodra dit het actieve (gecentreerde) kaartje wordt.
    @State private var fillProgress: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Detail-regel: datum/locatie (met icoon) of een statuslabel.
            HStack(spacing: 12) {
                ForEach(card.details) { chip in
                    HStack(spacing: 4) {
                        if let icon = chip.icon {
                            Image(icon)
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        Text(chip.text)
                            .font(AppFont.theSans(size: 14, weight: .plain))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .padding(.bottom, 10)

            // Titel — TheMixB W7 Bold, kaart-specifieke grootte, #2d2d2d
            Text(card.title)
                .font(AppFont.theMix(size: card.titleSize, weight: .bold))
                .foregroundColor(AppColors.darkGrey)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Spacer(minLength: 12)

            // Voortgangsbalk (optioneel) met een kalm pulserend bolletje aan het
            // eind, zodat je ziet hoe ver de aanvraag is.
            if let progress = card.progress {
                GeometryReader { geo in
                    let end = max(0, geo.size.width * fillProgress)
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(hex: "D9D9D9"))
                            .frame(height: 3)
                        Capsule()
                            .fill(AppColors.groen3)
                            .frame(width: end, height: 3)
                        if fillProgress > 0.02 {
                            PulsingDot()
                                .offset(x: end - 9)
                        }
                    }
                    .frame(height: geo.size.height, alignment: .center)
                }
                .frame(height: 18)
                .padding(.bottom, 14)
                .onChange(of: isActive) { _, active in
                    withAnimation(.easeOut(duration: 0.9)) { fillProgress = active ? progress : 0 }
                }
                .onAppear {
                    if isActive { withAnimation(.easeOut(duration: 0.9)) { fillProgress = progress } }
                }
            }

            // Knop — gevuld groen of groene outline
            Button {
                onAction(card.action)
            } label: {
                HStack(spacing: 8) {
                    Text(card.buttonText)
                        // Figma denhaag-button V2: TheSans C4s Regular 18
                        .font(AppFont.theSans(size: 18, weight: .plain))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Image("arrow-right")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                }
                .foregroundColor(card.buttonFilled ? .white : card.buttonTint)
                .padding(.vertical, 13)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity)
                .background(card.buttonFilled ? card.buttonTint : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: AppDesign.cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: AppDesign.cornerRadius)
                        .stroke(card.buttonTint, lineWidth: card.buttonFilled ? 0 : 1.5)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 188)
        .background(Color.white)
        .cornerRadius(AppDesign.cornerRadius)
        // Gouden accent-rand (Figma: alleen op de afspraak-kaart, #e3c012)
        .overlay(
            RoundedRectangle(cornerRadius: AppDesign.cornerRadius)
                .stroke(card.borderColor ?? .clear, lineWidth: 1)
        )
        .shadow(color: settings.cardShadows ? Color(red: 79/255, green: 51/255, blue: 3/255).opacity(0.10) : .clear, radius: 1, x: 0, y: 1)
        .shadow(color: settings.cardShadows ? Color(red: 79/255, green: 51/255, blue: 3/255).opacity(0.09) : .clear, radius: 2, x: 0, y: 4)
        .shadow(color: settings.cardShadows ? Color(red: 79/255, green: 51/255, blue: 3/255).opacity(0.05) : .clear, radius: 3, x: 0, y: 10)
    }
}
