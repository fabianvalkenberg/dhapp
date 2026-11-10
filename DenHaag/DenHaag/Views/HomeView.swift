import SwiftUI

struct HomeView: View {
    @EnvironmentObject var lang: LanguageManager
    @EnvironmentObject var versie: VersieManager
    @EnvironmentObject var rol: RolManager
    @ObservedObject var settings: HomeSettingsModel
    @Binding var showCustomizeSheet: Bool
    @Binding var showSettings: Bool
    @Binding var showAppointment: Bool
    @Binding var showKwijtschelding: Bool
    @Binding var showAanvraag: Bool
    @Binding var showPaspoort: Bool
    var onTile: (TileDestination) -> Void
    @State private var scrollOffset: CGFloat = 0

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    private var safeTop: CGFloat { AppDesign.safeAreaTop }

    /// Gekozen tegels die in deze versie van de app bestaan. Blijft er niets
    /// over, dan de standaardtegels van deze versie (geen leeg startscherm).
    /// De tegels van deze versie, in vaste volgorde. Met een persoonlijk
    /// startscherm (niet in versie 1) alleen de tegels die je zelf aan hebt.
    private var tiles: [PreferenceTile] {
        let v = versie.current
        let vast = v.tegels.compactMap { id in PreferenceTile.catalog.first { $0.id == id } }
        var basis = vast
        if v.heeft(.personalisatie) {
            let aan = Set(settings.selectedTiles.map(\.id))
            let gekozen = vast.filter { aan.contains($0.id) }
            if !gekozen.isEmpty { basis = gekozen }
        }
        return rol.isOndernemer ? PreferenceTile.alsOndernemer(basis, metVergunningen: v != .v1) : basis
    }

    /// Versie 2 en 3 tonen bovenaan wat er voor jou loopt.
    private var toonVoorJou: Bool { versie.current.heeft(.voorJou) }

    /// De drie stallingen die het dichtst bij huis liggen.
    private var stallingenDichtbij: [KaartPlek] {
        Array(KaartPlek.stallingen.sorted { $0.bikeMinutes < $1.bikeMinutes }.prefix(3))
    }

    var body: some View {
        ZStack(alignment: .top) {
            AppColors.background
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Geel header-vlak met facetten + kaarten-carrousel (behouden)
                    HeaderView(
                        settings: settings,
                        onSettingsTapped: { showSettings = true },
                        onAppointmentTapped: { showAppointment = true },
                        onKwijtscheldingTapped: { showKwijtschelding = true },
                        onAanvraagTapped: { showAanvraag = true },
                        onPaspoortTapped: { showPaspoort = true },
                        scrollOffset: scrollOffset,
                        toonVoorJou: toonVoorJou,
                        onMeldingTapped: { onTile(.overlast) },
                        onBerichtenTapped: { onTile(.berichten) },
                        onVergunningenTapped: { onTile(.vergunningen) },
                        onBedrijfsafvalTapped: { onTile(.afval) },
                        onMeldingStatusTapped: { onTile(.meldingStatus) },
                        onAfvalkalenderTapped: { onTile(.afvalkalender) }
                    )

                    VStack(spacing: 28) {
                        // Springplank: alleen de gekozen tegels
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(tiles) { tile in
                                TegelView(
                                    illustration: tile.illustration,
                                    title: lang.t(tile.titleKey),
                                    action: tile.isInteractive ? { onTile(tile.destination) } : nil
                                )
                            }
                        }
                        .padding(.horizontal, AppDesign.horizontalPadding + 6)
                        // Opnieuw opbouwen bij een rolwissel; anders bleven de oude tegels staan.
                        .id(rol.rol)

                        // Startscherm aanpassen (personalisatie; niet in versie 1)
                        if versie.current.heeft(.personalisatie) {
                        Button {
                            showCustomizeSheet = true
                        } label: {
                            HStack(spacing: 8) {
                                Image("preferences")
                                    .renderingMode(.template)
                                    .resizable()
                                    .frame(width: 18, height: 18)
                                Text(lang.t("customize_home"))
                                    .font(AppFont.theSans(size: 16, weight: .semiBold))
                            }
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppDesign.cornerRadius)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        }
                        }

                        // Onderkant-ruimte voor de tab bar
                        Spacer().frame(height: 100)
                    }
                    .padding(.top, 8)
                }
                // Gele facetten-band achter de notch. Zit vast aan de scroll-inhoud
                // (niet aan het scherm), zodat hij altijd met de header mee wegscrolt.
                // Loopt ver naar boven door voor het geel bij omlaag trekken.
                .background(alignment: .top) {
                    Image("facetten-geel")
                        .resizable()
                        .scaledToFill()
                        .frame(height: safeTop + 30 + 800)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .offset(y: -800)
                        .allowsHitTesting(false)
                }
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: ScrollOffsetKey.self,
                            value: geo.frame(in: .named("scroll")).minY
                        )
                    }
                )
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetKey.self) { value in
                scrollOffset = value
            }
            .ignoresSafeArea(edges: .top)
        }
    }
}

// MARK: - Stallingen dichtbij (staat nu nergens; bewaard voor later)

extension HomeView {
    var stallingenBlok: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(lang.t("home_v1_stallingen"))
                .font(AppFont.theMix(size: 22, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            VStack(spacing: 0) {
                ForEach(Array(stallingenDichtbij.enumerated()), id: \.element.id) { index, plek in
                    Button { onTile(.fietsParkeren) } label: { stallingRij(plek) }
                        .buttonStyle(.plain)
                    if index < stallingenDichtbij.count - 1 {
                        Divider().padding(.leading, 88)
                    }
                }
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppDesign.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppDesign.cornerRadius)
                    .stroke(AppColors.grijs2, lineWidth: 1)
            )

            Button { onTile(.fietsParkeren) } label: {
                HStack(spacing: 6) {
                    Text(lang.t("home_v1_alle_stallingen"))
                        .font(AppFont.theSans(size: 16, weight: .bold))
                    Image("arrow-right")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 18, height: 18)
                }
                .foregroundColor(AppColors.groen3)
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
        }
    }

    private func stallingRij(_ plek: KaartPlek) -> some View {
        HStack(spacing: 14) {
            Color.clear
                .frame(width: 60, height: 60)
                .overlay(
                    Image(UIImage(named: plek.imageName) != nil ? plek.imageName : "facetten-geel")
                        .resizable()
                        .scaledToFill()
                )
                .clipShape(RoundedRectangle(cornerRadius: 4))

            VStack(alignment: .leading, spacing: 4) {
                Text(plek.title)
                    .font(AppFont.theSans(size: 18, weight: .bold))
                    .foregroundColor(AppColors.darkGrey)
                    .lineLimit(1)
                Text(String(format: lang.t("plek_bike_minutes"), plek.bikeMinutes)
                     + " · "
                     + (plek.hoursToday.map { "\(lang.t("plek_today")) \($0)" } ?? lang.t("home_v1_gesloten")))
                    .font(AppFont.theSans(size: 14, weight: .plain))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            Spacer(minLength: 0)
            Image("arrow-right")
                .renderingMode(.template)
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(14)
        .contentShape(Rectangle())
    }
}

private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
