import SwiftUI

/// Zelfde opbouw als `BuurtCardView`: foto bovenaan, titel, korte regel en
/// detailregels. Zonder datum-badge, want een plek heeft geen datum.
struct PlekCardView: View {
    @EnvironmentObject var lang: LanguageManager
    @Environment(\.openURL) private var openURL
    let plek: KaartPlek
    let isKoffie: Bool
    /// Geselecteerd op de kaart: dan staat de routeknop erbij.
    var actief = true

    /// nil = vandaag gesloten; de regel met tijden valt dan weg.
    private var hoursText: String? {
        plek.hoursToday.map { "\(lang.t("plek_today")) \($0)" }
    }

    /// Spaarplekken tonen hun bijdrage, stallingen hun voorzieningen.
    private var subtitle: String? {
        if isKoffie { return plek.bijdrage.map { String(format: lang.t("plek_bijdrage"), $0) } }
        let parts = (plek.firstDayFree ? [lang.t("fiets_first_day_free")] : []) + plek.extras
        return parts.isEmpty ? lang.t("fiets_stalling_subtitle") : parts.joined(separator: " · ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Als overlay, zodat een breed beeld het kaartje niet oprekt.
            Color.clear
                .frame(height: 105)
                .overlay(
                    Image(UIImage(named: plek.imageName) != nil ? plek.imageName : "facetten-geel")
                        .resizable()
                        .scaledToFill()
                )
                .clipped()

            VStack(alignment: .leading, spacing: isKoffie ? 16 : 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plek.title)
                        .font(AppFont.theMix(size: 20, weight: .bold))
                        .foregroundColor(.black)
                        .lineLimit(1)

                    if let subtitle {
                        Text(subtitle)
                            .font(AppFont.theSans(size: 18, weight: .plain))
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(isKoffie ? 2 : 1)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    // Fietstijd staat bij stallingen in de routeknop.
                    if isKoffie {
                        detailRow(text: String(format: lang.t("plek_bike_minutes"), plek.bikeMinutes)) {
                            Image(systemName: "bicycle")
                                .font(.system(size: 12, weight: .medium))
                        }
                    }
                    if let hoursText {
                        detailRow(text: hoursText) {
                            Image(systemName: "clock")
                                .font(.system(size: 13, weight: .medium))
                        }
                    }
                    detailRow(text: plek.address) {
                        Image("location-pin")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                    }
                }

                // Route in Google Maps, op de fiets vanaf waar je nu bent.
                if !isKoffie {
                    Button(action: openRoute) {
                        HStack(spacing: 8) {
                            Image(systemName: "bicycle")
                                .font(.system(size: 15, weight: .semibold))
                            Text(String(format: lang.t("plek_route"), plek.bikeMinutes))
                                .font(AppFont.theSans(size: 16, weight: .bold))
                            Spacer(minLength: 0)
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .background(AppColors.groen3)
                        .clipShape(RoundedRectangle(cornerRadius: AppDesign.cornerRadius))
                    }
                    .buttonStyle(PressableScaleStyle())
                    .opacity(actief ? 1 : 0.5)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(AppColors.grijs2, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.10), radius: 1.5, x: 0, y: 2)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 10)
    }

    /// Google Maps met een fietsroute naar deze plek. Is de app er niet, dan
    /// opent dezelfde link Google Maps in de browser.
    private func openRoute() {
        AnalyticsService.track("plek_route", ["plek": plek.title])
        let dest = "\(plek.latitude),\(plek.longitude)"
        if let url = URL(string: "https://www.google.com/maps/dir/?api=1&destination=\(dest)&travelmode=bicycling") {
            openURL(url)
        }
    }

    private func detailRow<Icon: View>(text: String, @ViewBuilder icon: () -> Icon) -> some View {
        HStack(spacing: 8) {
            icon()
                .frame(width: 16, height: 16)
                .foregroundColor(AppColors.textSecondary)
            Text(text)
                .font(AppFont.theSans(size: 14, weight: .plain))
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(1)
        }
    }
}
