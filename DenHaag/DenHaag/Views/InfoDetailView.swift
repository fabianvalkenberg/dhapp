import SwiftUI

/// Welke info-pagina getoond wordt vanuit een home-tegel.
enum InfoKind: String, Identifiable {
    case bieb
    case rechten
    var id: String { rawValue }
}

/// Eenvoudige info/voorzieningen-pagina (prototype) voor tegels die geen eigen
/// flow hebben: "Naar de bieb" en "Waar heb ik recht op". Mee-scrollende titel +
/// ronde terug-knop, conform de detail-conventies.
struct InfoDetailView: View {
    let kind: InfoKind
    var onClose: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            AppColors.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Ruimte voor de zwevende terug-knop.
                    Color.clear.frame(height: AppDesign.safeAreaTop + 44)

                    VStack(alignment: .leading, spacing: 12) {
                        Text(title)
                            .font(AppFont.theMix(size: 30, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                        Text(intro)
                            .font(AppFont.theSans(size: 17, weight: .plain))
                            .foregroundColor(AppColors.textSecondary)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(spacing: 12) {
                        ForEach(rows.indices, id: \.self) { i in
                            infoRow(rows[i])
                        }
                    }

                    primaryCTA

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, AppDesign.horizontalPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .bovenVervaging()

            BackCircleButton(action: onClose)
                .terugknopPlek()
        }
    }

    // MARK: - Rij

    private func infoRow(_ row: InfoRow) -> some View {
        HStack(spacing: 14) {
            Image(systemName: row.icon)
                .font(.system(size: 18))
                .foregroundColor(AppColors.groen3)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(row.title)
                    .font(AppFont.theSans(size: 16, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                Text(row.detail)
                    .font(AppFont.theSans(size: 14, weight: .plain))
                    .foregroundColor(AppColors.textSecondary)
            }
            Spacer()
            if let badge = row.badge {
                Text(badge)
                    .font(AppFont.theSans(size: 12, weight: .bold))
                    .foregroundColor(AppColors.groen3)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppColors.groen3.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: AppDesign.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppDesign.cornerRadius)
                .stroke(AppColors.grijs2, lineWidth: 1)
        )
    }

    private var primaryCTA: some View {
        Button(action: onClose) {
            Text(ctaLabel)
                .font(AppFont.theSans(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(AppColors.groen3)
                .clipShape(RoundedRectangle(cornerRadius: AppDesign.cornerRadius))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Inhoud per type

    private var title: String {
        switch kind {
        case .bieb:    return "Naar de bieb"
        case .rechten: return "Waar heb ik recht op"
        }
    }

    private var intro: String {
        switch kind {
        case .bieb:
            return "De Haagse bibliotheken: lenen, studeren of langskomen voor een activiteit. Dit is de dichtstbijzijnde vestiging."
        case .rechten:
            return "Op basis van jouw situatie laten we zien welke regelingen en voorzieningen je mogelijk laat liggen. Snel checken, zonder zoeken."
        }
    }

    private var ctaLabel: String {
        switch kind {
        case .bieb:    return "Route naar de bibliotheek"
        case .rechten: return "Check waar je recht op hebt"
        }
    }

    private var rows: [InfoRow] {
        switch kind {
        case .bieb:
            return [
                InfoRow(icon: "building.columns", title: "Bibliotheek Centrum", detail: "Spui 68, Den Haag", badge: "Nu open"),
                InfoRow(icon: "clock", title: "Openingstijden", detail: "Vandaag open tot 20:00", badge: nil),
                InfoRow(icon: "book", title: "Lenen en verlengen", detail: "Beheer je leningen met je bibliotheekpas", badge: nil),
            ]
        case .rechten:
            return [
                InfoRow(icon: "creditcard", title: "Ooievaarspas", detail: "Korting op sport, cultuur en meer", badge: "Mogelijk"),
                InfoRow(icon: "eurosign.circle", title: "Kwijtschelding gemeentebelasting", detail: "Bij een laag inkomen", badge: "Check"),
                InfoRow(icon: "gift", title: "Individuele inkomenstoeslag", detail: "Voor langdurig laag inkomen", badge: "Check"),
            ]
        }
    }
}

/// Eén regel op een info-pagina.
private struct InfoRow {
    let icon: String
    let title: String
    let detail: String
    let badge: String?
}
