import SwiftUI

/// Detailpagina vanuit de blauwe "Vraag een nieuw paspoort aan"-kaart op de home.
/// Legt uit dat een deel van de aanvraag al klaarstaat op basis van wat de gemeente
/// al van je weet; je vult alleen de rest nog aan. Blauw accent (reisdocument).
struct PaspoortAanvraagView: View {
    @Binding var isPresented: Bool

    /// Wat al bekend is en automatisch is ingevuld.
    private let alIngevuld: [String] = [
        "Persoonsgegevens (A. G. Klap)",
        "Burgerservicenummer",
        "Adres uit de Basisregistratie",
        "Gegevens huidig paspoort",
    ]
    /// Wat de aanvrager nog zelf moet doen.
    private let nogTeDoen: [String] = [
        "Pasfoto toevoegen",
        "Ophaalmoment kiezen",
        "Betalen (€ 83,85)",
    ]

    var body: some View {
        ZStack(alignment: .topLeading) {
            AppColors.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    Color.clear.frame(height: AppDesign.safeAreaTop + 44)

                    // Titel (mee-scrollend)
                    Text("Nieuw paspoort aanvragen")
                        .font(AppFont.theMix(size: 30, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)

                    // Blauwe attentie-banner
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 20))
                            .foregroundColor(AppColors.blauw3)
                        Text("Je paspoort verloopt in juli 2026. Vraag het nu vast aan, dan heb je het op tijd.")
                            .font(AppFont.theSans(size: 15, weight: .semiBold))
                            .foregroundColor(AppColors.blauw3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.blauw1)
                    .clipShape(RoundedRectangle(cornerRadius: AppDesign.cornerRadius))

                    // Uitleg: een deel staat al klaar
                    Text("We hebben een deel van de aanvraag al voor je klaargezet op basis van wat we al van je weten. Je hoeft alleen de rest nog aan te vullen.")
                        .font(AppFont.theSans(size: 17, weight: .plain))
                        .foregroundColor(AppColors.textSecondary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    // Nog te doen — staat nu bovenaan (dat is wat je moet doen)
                    section(title: "Dit vul je zelf nog aan") {
                        ForEach(nogTeDoen, id: \.self) { item in
                            statusRow(text: item, done: false)
                        }
                    }

                    // Al klaargezet — eronder
                    section(title: "Staat al voor je klaar") {
                        ForEach(alIngevuld, id: \.self) { item in
                            statusRow(text: item, done: true)
                        }
                    }

                    // Blauwe CTA
                    Button(action: { isPresented = false }) {
                        Text("Aanvraag afronden")
                            .font(AppFont.theSans(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(AppColors.blauw3)
                            .clipShape(RoundedRectangle(cornerRadius: AppDesign.cornerRadius))
                    }
                    .buttonStyle(.plain)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, AppDesign.horizontalPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            BackCircleButton(action: { isPresented = false })
                .padding(.leading, AppDesign.horizontalPadding)
                .padding(.top, AppDesign.safeAreaTop + 6)
        }
    }

    // MARK: - Bouwstenen

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(AppFont.theSans(size: 14, weight: .bold))
                .foregroundColor(AppColors.grijs4)
                .textCase(.uppercase)
            VStack(spacing: 10) { content() }
        }
    }

    private func statusRow(text: String, done: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20))
                .foregroundColor(done ? AppColors.groen3 : AppColors.grijs2)
            Text(text)
                .font(AppFont.theSans(size: 16, weight: done ? .semiBold : .plain))
                .foregroundColor(done ? AppColors.textPrimary : AppColors.textSecondary)
            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: AppDesign.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppDesign.cornerRadius)
                .stroke(AppColors.grijs2, lineWidth: 1)
        )
    }
}
