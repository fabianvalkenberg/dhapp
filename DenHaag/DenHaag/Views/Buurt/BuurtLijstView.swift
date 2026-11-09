import SwiftUI
import CoreLocation

/// Lijstweergave van Buurt (design review 2026-11, "Geen lijstweergave").
/// Voor wie snel wil zien wat er speelt, of de kaart lastig vindt. Werkt voor
/// buurtnieuws (datumblok) én vaste plekken zoals stallingen (groen icoonblok).
struct BuurtLijstView: View {
    @EnvironmentObject var lang: LanguageManager
    let items: [NeighbourhoodItem]
    let vanaf: CLLocationCoordinate2D
    /// Ruimte onderin, zodat de laatste rij niet achter knop en tabbalk valt.
    var ondermarge: CGFloat = 180
    var onKies: (NeighbourhoodItem) -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                if items.isEmpty {
                    Text(lang.t("buurt_leeg"))
                        .font(AppFont.theSans(size: 17, weight: .plain))
                        .foregroundColor(AppColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 24)
                }
                ForEach(items) { item in
                    Button { onKies(item) } label: { rij(item) }
                        .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppDesign.horizontalPadding)
            .padding(.bottom, ondermarge)
        }
        .background(AppColors.background)
    }

    // Figma: rij 81 hoog (14 boven/onder), blok 52×52, tussenruimte 14,
    // titel 17 vet #2E2E2E, subregel 14 #666, chevron 24, lijn #E6E6E6.
    private func rij(_ item: NeighbourhoodItem) -> some View {
        HStack(spacing: 14) {
            blok(item)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.plek?.title ?? item.title)
                    .font(AppFont.theSans(size: 17, weight: .bold))
                    .foregroundColor(Color(hex: "2E2E2E"))
                    .lineLimit(1)
                subregel(item)
                    .font(AppFont.theSans(size: 14, weight: .plain))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppColors.blauw3)
                .frame(width: 24, height: 24)
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color(hex: "E6E6E6")).frame(height: 1)
        }
    }

    @ViewBuilder
    private func blok(_ item: NeighbourhoodItem) -> some View {
        if item.plek != nil {
            Image(systemName: item.type == .koffie ? "cup.and.saucer.fill" : "bicycle")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 52, height: 52)
                .background(AppColors.groen3)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        } else {
            VStack(spacing: 0) {
                Text(item.day)
                    .font(AppFont.theMix(size: 17, weight: .bold))
                    .foregroundColor(Color(hex: "2E2E2E"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(item.month)
                    .font(AppFont.theSans(size: 12, weight: .bold))
                    .foregroundColor(AppColors.groen3)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.horizontal, 4)
            .frame(width: 52, height: 52)
            .background(Color(hex: "F7F7F5"))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    /// "Evenement · Pleintje om de hoek · 350 m" of "Open · tot 03:00 · 350 m".
    private func subregel(_ item: NeighbourhoodItem) -> Text {
        let afstand = Self.afstand(van: vanaf, naar: item.coordinate)
        if let plek = item.plek {
            if let tot = plek.openTot() {
                return Text(String(format: lang.t("buurt_open_tot"), tot)).foregroundColor(AppColors.groen3)
                    + Text(" · \(afstand)").foregroundColor(Color(hex: "666666"))
            }
            return Text(lang.t("buurt_gesloten")).foregroundColor(AppColors.rood)
                + Text(" · \(afstand)").foregroundColor(Color(hex: "666666"))
        }
        return Text("\(lang.t(item.type.labelKey)) · \(item.location) · \(afstand)")
            .foregroundColor(Color(hex: "666666"))
    }

    static func afstand(van a: CLLocationCoordinate2D, naar b: CLLocationCoordinate2D) -> String {
        let m = CLLocation(latitude: a.latitude, longitude: a.longitude)
            .distance(from: CLLocation(latitude: b.latitude, longitude: b.longitude))
        if m < 1000 { return "\(Int((m / 10).rounded()) * 10) m" }
        return String(format: "%.1f km", m / 1000).replacingOccurrences(of: ".", with: ",")
    }
}
