import SwiftUI

/// Detailpagina van een vaste plek (fietsenstalling of koffieplek). Design
/// review 2026-11, "Geen detailpagina stalling": het kaartje liet maar een deel
/// zien en de voorzieningen liepen af. Opbouw zoals het zwembaddetail.
///
/// "Geschikt voor" en de extra voorzieningen komen uit `StallingFeiten`
/// (opgezocht bij Biesieklette); wat niet bekend is, staat er niet.
struct StallingDetailView: View {
    let item: NeighbourhoodItem
    let plek: KaartPlek
    @EnvironmentObject var lang: LanguageManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        ZStack(alignment: .topLeading) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    kop
                    VStack(alignment: .leading, spacing: 32) {
                        adresEnStatus
                        if !voorzieningen.isEmpty { voorzieningenSectie }
                        if !geschiktVoor.isEmpty { geschiktSectie }
                        openingstijden
                    }
                    .padding(.horizontal, ZwStijl.pad)
                    .padding(.top, 24)
                    .padding(.bottom, 80)
                }
            }
            .bovenVervaging()
            .ignoresSafeArea(edges: .top)

            BackCircleButton(stijl: .foto) { dismiss() }
                .terugknopPlek(binnenSafeArea: true)
        }
        .onAppear { AnalyticsService.screen("stalling_detail") }
    }

    // MARK: Kop

    private var kop: some View {
        ZStack(alignment: .bottomLeading) {
            Image(plek.imageName).resizable().scaledToFill()
                .frame(height: AppDesign.safeAreaTop + 178)
                .frame(maxWidth: .infinity)
                .clipped()
            LinearGradient(colors: [.black.opacity(0), .black.opacity(0.5)], startPoint: .top, endPoint: .bottom)
            Text(plek.title)
                .font(ZwStijl.titel(32))
                .foregroundColor(.white)
                .padding(.horizontal, ZwStijl.pad)
                .padding(.bottom, 12)
        }
        .frame(height: AppDesign.safeAreaTop + 178)
        .clipped()
    }

    // MARK: Adres en open/dicht

    private var adresEnStatus: some View {
        ZwLijst {
            ZwRij(icoon: "zw-pin", titel: plek.address) {
                Button(action: route) {
                    HStack(spacing: 4) {
                        ZwIcon(naam: "zw-directions", maat: 20, kleur: AppColors.groen3)
                        Text(lang.t("zw_route")).font(AppFont.theSans(size: 18, weight: .bold))
                    }
                    .foregroundColor(AppColors.groen3)
                }
                .buttonStyle(.plain)
            }
            ZwScheiding()
            HStack(spacing: 12) {
                ZwIcon(naam: "zw-clock")
                statusTekst
                    .font(ZwStijl.tekst)
                Spacer(minLength: 0)
            }
            .padding(16)
        }
    }

    private var statusTekst: Text {
        if let tot = plek.openTot() {
            return Text(lang.t("stalling_open_nu")).font(AppFont.theSans(size: 18, weight: .bold))
                .foregroundColor(AppColors.groen3)
                + Text(" · " + String(format: lang.t("stalling_tot"), tot)).foregroundColor(AppColors.textSecondary)
        }
        return Text(lang.t("buurt_gesloten")).font(AppFont.theSans(size: 18, weight: .bold))
            .foregroundColor(AppColors.rood)
    }

    // MARK: Voorzieningen

    /// Uit de data: eerste dag gratis + de extra's van de plek.
    private var voorzieningen: [(icoon: String, tekst: String)] {
        var lijst: [(String, String)] = []
        if plek.firstDayFree { lijst.append(("gift", lang.t("fiets_first_day_free"))) }
        for e in StallingFilter.voorzieningen(plek) {
            let icoon: String
            switch e.lowercased() {
            case let x where x.contains("toegankelijk") || x.contains("rolstoel"): icoon = "figure.roll"
            case let x where x.contains("toilet"): icoon = "toilet"
            case let x where x.contains("bewaakt"): icoon = "checkmark.shield"
            case let x where x.contains("postnl"): icoon = "shippingbox"
            case let x where x.contains("opladen") || x.contains("laad"): icoon = "bolt"
            case let x where x.contains("kluis"): icoon = "lock"
            case let x where x.contains("lamp"): icoon = "lightbulb"
            case let x where x.contains("pomp"): icoon = "wrench.and.screwdriver"
            default: icoon = "checkmark.circle"
            }
            lijst.append((icoon, e))
        }
        return lijst
    }

    private var voorzieningenSectie: some View {
        ZwSectie(titel: lang.t("zw_facilities")) {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible())],
                      alignment: .leading, spacing: 0) {
                ForEach(voorzieningen, id: \.tekst) { v in
                    HStack(spacing: 12) {
                        Image(systemName: v.icoon)
                            .font(.system(size: 17))
                            .foregroundColor(AppColors.textSecondary)
                            .frame(width: 24, height: 24)
                        Text(v.tekst)
                            .font(ZwStijl.tekst)
                            .foregroundColor(AppColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }

    // MARK: Geschikt voor

    private var geschiktVoor: [FietspasType] {
        [.fiets, .fatbike, .bakfiets, .voordrager].filter { StallingFilter.geschikt(plek, voor: $0) == true }
    }

    /// Figma: twee kolommen met het gekleurde voertuig-icoon van de fietspas.
    private var geschiktSectie: some View {
        ZwSectie(titel: lang.t("sf_geschikt_voor")) {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible())],
                      alignment: .leading, spacing: 0) {
                ForEach(geschiktVoor) { t in
                    HStack(spacing: 12) {
                        Image(t.icoon).renderingMode(.template).resizable().scaledToFit()
                            .foregroundColor(t.kleur)
                            .frame(width: 36, height: 24)
                        Text(lang.t(t.naamKey))
                            .font(ZwStijl.tekst)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }

    // MARK: Openingstijden

    /// Zeven dagen vanaf vandaag: Vandaag, Morgen, dan de weekdagen.
    private var dagen: [(naam: String, tijd: String)] {
        let cal = Calendar.current
        let vandaag = Date()
        let locale = Locale(identifier: lang.current.rawValue)
        let fmt = DateFormatter()
        fmt.locale = locale
        fmt.dateFormat = "EEEE"
        return (0..<7).map { d in
            let datum = cal.date(byAdding: .day, value: d, to: vandaag) ?? vandaag
            let index = (cal.component(.weekday, from: datum) + 5) % 7
            let naam: String
            switch d {
            case 0: naam = lang.t("plek_today")
            case 1: naam = lang.t("zw_tomorrow")
            default: naam = fmt.string(from: datum).capitalized(with: locale)
            }
            return (naam, plek.hours[index] ?? lang.t("stalling_dicht"))
        }
    }

    private var openingstijden: some View {
        ZwSectie(titel: lang.t("stalling_openingstijden")) {
            VStack(spacing: 13) {
                ForEach(dagen, id: \.naam) { dag in
                    HStack {
                        Text(dag.naam)
                        Spacer()
                        Text(dag.tijd).monospacedDigit()
                    }
                    .font(ZwStijl.tekst)
                    .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: ZwStijl.lijstRadius))
            .overlay(RoundedRectangle(cornerRadius: ZwStijl.lijstRadius).stroke(ZwStijl.lijn, lineWidth: 1))
        }
    }

    /// Google Maps met een fietsroute, zoals op het kaartje.
    private func route() {
        AnalyticsService.track("plek_route", ["plek": plek.title, "bron": "detail"])
        let dest = "\(plek.latitude),\(plek.longitude)"
        if let url = URL(string: "https://www.google.com/maps/dir/?api=1&destination=\(dest)&travelmode=bicycling") {
            openURL(url)
        }
    }
}
