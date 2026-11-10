import SwiftUI

/// Statuspagina van de "aanvraag uitbouw" (de tweede home-kaart). Toont de
/// voortgang met dezelfde voortgangsbalk + kalm pulserend bolletje.
struct AanvraagDetailView: View {
    @Binding var isPresented: Bool

    private var safeTop: CGFloat { AppDesign.safeAreaTop }
    private let progress: Double = 191.0 / 251.0

    private struct Stap: Identifiable {
        let id = UUID()
        let titel: String
        let datum: String
        let done: Bool
        let actief: Bool
    }
    private let stappen: [Stap] = [
        Stap(titel: "Aanvraag ingediend", datum: "28 mei", done: true, actief: false),
        Stap(titel: "Ontvangstbevestiging", datum: "29 mei", done: true, actief: false),
        Stap(titel: "In behandeling", datum: "Sinds 3 juni", done: false, actief: true),
        Stap(titel: "Besluit", datum: "Verwacht volgende week", done: false, actief: false),
    ]

    var body: some View {
        ZStack(alignment: .topLeading) {
            AppColors.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Ruimte voor de zwevende back-knop; titel staat eronder (zelfde
                    // template als de paspoort- en afspraak-pagina).
                    Color.clear.frame(height: safeTop + 44)

                    Text("Aanvraag uitbouw")
                        .font(AppFont.theMix(size: 30, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)

                    // Statuskaart met voortgang
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Status aanvraag")
                            .font(AppFont.theSans(size: 14, weight: .plain))
                            .foregroundColor(AppColors.textSecondary)
                        Text("Volgende week antwoord")
                            .font(AppFont.theMix(size: 22, weight: .bold))
                            .foregroundColor(AppColors.darkGrey)

                        GeometryReader { geo in
                            let end = max(0, geo.size.width * progress)
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color(hex: "D9D9D9")).frame(height: 3)
                                Capsule().fill(AppColors.groen3).frame(width: end, height: 3)
                                PulsingDot().offset(x: end - 9)
                            }
                            .frame(height: geo.size.height, alignment: .center)
                        }
                        .frame(height: 18)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppDesign.cornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppDesign.cornerRadius)
                            .stroke(AppColors.grijs2, lineWidth: 1)
                    )

                    // Stappen-tijdlijn
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(stappen.enumerated()), id: \.element.id) { i, stap in
                            stapRij(stap, isLast: i == stappen.count - 1)
                        }
                    }

                    // Toelichting
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Over je aanvraag")
                            .font(AppFont.theSans(size: 18, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                        Text("Je aanvraag voor de uitbouw aan de achterzijde wordt beoordeeld op het bestemmingsplan en de welstand. Je hoeft nu niets te doen — we laten het je weten zodra er een besluit is.")
                            .font(AppFont.theSans(size: 18, weight: .plain))
                            .foregroundColor(AppColors.textSecondary)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Enige actie: de volledige aanvraag op MijnDenHaag bekijken.
                    Button {} label: {
                        HStack(spacing: 8) {
                            Text("Bekijk hele aanvraag op MijnDenHaag")
                                .font(AppFont.theSans(size: 17, weight: .bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Spacer()
                            Image("arrow-right")
                                .renderingMode(.template).resizable().scaledToFit()
                                .frame(width: 18, height: 18)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 15)
                        .frame(maxWidth: .infinity)
                        .background(AppColors.groen3)
                        .clipShape(RoundedRectangle(cornerRadius: AppDesign.cornerRadius))
                    }
                    .buttonStyle(.plain)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, AppDesign.horizontalPadding)
            }
            .bovenVervaging()

            // Zwevende back-knop (titel scrollt eronder weg) — zelfde patroon overal.
            BackCircleButton { isPresented = false }
                .terugknopPlek(binnenSafeArea: true)
        }
    }

    private func stapRij(_ stap: Stap, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(stap.done ? AppColors.groen3 : (stap.actief ? AppColors.groen3.opacity(0.15) : Color.white))
                        .frame(width: 26, height: 26)
                        .overlay(Circle().stroke(stap.done || stap.actief ? AppColors.groen3 : AppColors.grijs2, lineWidth: 1.5))
                    if stap.done {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    } else if stap.actief {
                        Circle().fill(AppColors.groen3).frame(width: 9, height: 9)
                    }
                }
                if !isLast {
                    Rectangle()
                        .fill(stap.done ? AppColors.groen3 : AppColors.grijs2)
                        .frame(width: 2, height: 34)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(stap.titel)
                    .font(AppFont.theSans(size: 17, weight: stap.actief ? .bold : .semiBold))
                    .foregroundColor(stap.actief || stap.done ? AppColors.textPrimary : AppColors.textSecondary)
                Text(stap.datum)
                    .font(AppFont.theSans(size: 14, weight: .plain))
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.top, 2)
            Spacer()
        }
    }
}
