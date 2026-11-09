import SwiftUI

struct MainTabView: View {
    @ObservedObject var settings: HomeSettingsModel
    @State private var selectedTab: Tab = .home
    @State private var buurtDetailOpen = false
    @State private var showCustomizeSheet = false
    @State private var showSettings = false
    @State private var showAppointment = false
    @State private var showParkeren = false
    @State private var showAfval = false
    @State private var showAfvalkalender = false
    @State private var showZwemmen = false
    @State private var showOoievaarspas = false
    @State private var showKwijtschelding = false
    @State private var showAanvraag = false
    @State private var showPaspoort = false
    /// Onderwerp-filter dat een buurt-snelkoppel-tegel aanvraagt (nil = geen).
    @State private var buurtFilter: String? = nil
    /// Welke info-pagina open is (bieb / rechten); nil = geen.
    @State private var infoKind: InfoKind? = nil

    enum Tab: String {
        case home, regelen, buurt, hulp
    }

    /// Vaste volgorde van de tabs, bepaalt de richting van de push-animatie.
    private func tabIndex(_ tab: Tab) -> Int {
        switch tab {
        case .home: return 0
        case .regelen: return 1
        case .buurt: return 2
        case .hulp: return 3
        }
    }

    /// Horizontale verschuiving van een scherm t.o.v. het actieve scherm:
    /// het actieve scherm staat op 0, de andere staan een schermbreedte links/rechts.
    private func tabOffset(_ tab: Tab) -> CGFloat {
        CGFloat(tabIndex(tab) - tabIndex(selectedTab)) * screenWidth
    }

    private var screenWidth: CGFloat {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen.bounds.width
            ?? UIScreen.main.bounds.width
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content — alle tabs blijven in leven (state behouden) en schuiven
            // horizontaal als een paged push vanaf hun positie in de tabvolgorde.
            ZStack {
                HomeView(
                    settings: settings,
                    showCustomizeSheet: $showCustomizeSheet,
                    showSettings: $showSettings,
                    showAppointment: $showAppointment,
                    showKwijtschelding: $showKwijtschelding,
                    showAanvraag: $showAanvraag,
                    showPaspoort: $showPaspoort,
                    onTile: handleTile
                )
                .modifier(TabSlide(offset: tabOffset(.home), active: selectedTab == .home))

                RegelenView(isActive: selectedTab == .regelen)
                    .modifier(TabSlide(offset: tabOffset(.regelen), active: selectedTab == .regelen))

                BuurtView(detailOpen: $buurtDetailOpen, requestedFilter: $buurtFilter)
                    .modifier(TabSlide(offset: tabOffset(.buurt), active: selectedTab == .buurt))

                HelpView()
                    .modifier(TabSlide(offset: tabOffset(.hulp), active: selectedTab == .hulp))
            }
            // Push met een sterke uitloop aan het einde (easeOutExpo), zelfde
            // gevoel als de camera-beweging in Buurt: snel weg, zacht landen.
            .animation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.45), value: selectedTab)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Bottom navigation — verdwijnt wanneer het buurt-detail open is.
            BottomTabBar(selectedTab: $selectedTab)
                .offset(y: buurtDetailOpen ? 160 : 0)
                .opacity(buurtDetailOpen ? 0 : 1)
                .animation(.easeInOut(duration: 0.25), value: buurtDetailOpen)

            // Full-screen slide-in overlays (over tab bar)
            if showCustomizeSheet {
                CustomizeHomeView(settings: settings, isPresented: $showCustomizeSheet)
                    .transition(.move(edge: .trailing))
                    .zIndex(20)
            }

            if showSettings {
                SettingsView(settings: settings, isPresented: $showSettings)
                    .transition(.move(edge: .trailing))
                    .zIndex(20)
            }

            if showAppointment {
                AppointmentDetailView(onClose: {
                    showAppointment = false
                })
                .transition(.move(edge: .trailing))
                .zIndex(20)
            }

            if showParkeren {
                ParkeerPageView(isPresented: $showParkeren)
                    .transition(.move(edge: .trailing))
                    .zIndex(20)
            }

            if showAfval {
                AfvalView(isPresented: $showAfval)
                    .transition(.move(edge: .trailing))
                    .zIndex(20)
            }

            if showAfvalkalender {
                AfvalkalenderView(isPresented: $showAfvalkalender)
                    .transition(.move(edge: .trailing))
                    .zIndex(20)
            }

            if showZwemmen {
                ZwemmenView(isPresented: $showZwemmen)
                    .transition(.move(edge: .trailing))
                    .zIndex(20)
            }

            if showKwijtschelding {
                KwijtscheldingDetailView(isPresented: $showKwijtschelding)
                    .transition(.move(edge: .trailing))
                    .zIndex(20)
            }

            if showAanvraag {
                AanvraagDetailView(isPresented: $showAanvraag)
                    .transition(.move(edge: .trailing))
                    .zIndex(20)
            }

            if let kind = infoKind {
                InfoDetailView(kind: kind) { infoKind = nil }
                    .transition(.move(edge: .trailing))
                    .zIndex(20)
            }

            if showPaspoort {
                PaspoortAanvraagView(isPresented: $showPaspoort)
                    .transition(.move(edge: .trailing))
                    .zIndex(20)
            }

        }
        .ignoresSafeArea(.keyboard)
        .animation(.easeInOut(duration: 0.35), value: showCustomizeSheet)
        .animation(.easeInOut(duration: 0.35), value: showSettings)
        .animation(.easeInOut(duration: 0.35), value: showAppointment)
        .animation(.easeInOut(duration: 0.35), value: showParkeren)
        .animation(.easeInOut(duration: 0.35), value: showAfval)
        .animation(.easeInOut(duration: 0.35), value: showZwemmen)
        .animation(.easeInOut(duration: 0.35), value: showKwijtschelding)
        .animation(.easeInOut(duration: 0.35), value: showAanvraag)
        .animation(.easeInOut(duration: 0.35), value: infoKind)
        .animation(.easeInOut(duration: 0.35), value: showPaspoort)
        .onChange(of: showAanvraag) { _, v in if v { AnalyticsService.track("open_aanvraag") } }
        .onChange(of: showPaspoort) { _, v in if v { AnalyticsService.track("open_paspoort") } }
        .onChange(of: infoKind) { _, v in if let v { AnalyticsService.track("open_info", ["kind": String(describing: v)]) } }
        .fullScreenCover(isPresented: $showOoievaarspas) {
            PasDetailView(pas: .ooievaarspas)
        }
        .onAppear { AnalyticsService.screen("home") }
        .onChange(of: selectedTab) { _, t in
            AnalyticsService.screen(String(describing: t))
            AnalyticsService.track("tab_switch", ["tab": String(describing: t)])
        }
        .onChange(of: showSettings) { _, v in if v { AnalyticsService.track("open_settings") } }
        .onChange(of: showCustomizeSheet) { _, v in if v { AnalyticsService.track("open_customize_home") } }
        .onChange(of: showAppointment) { _, v in if v { AnalyticsService.track("open_appointment") } }
        .onChange(of: showKwijtschelding) { _, v in if v { AnalyticsService.track("open_kwijtschelding") } }
        .onChange(of: showOoievaarspas) { _, v in if v { AnalyticsService.track("open_ooievaarspas") } }
    }

    /// Centrale routering voor het tikken op een home-tegel.
    private func handleTile(_ destination: TileDestination) {
        AnalyticsService.track("tap_tile", ["dest": String(describing: destination)])
        switch destination {
        case .parkeren:
            showParkeren = true
        case .afval, .grofvuil:
            showAfval = true
        case .afvalkalender:
            showAfvalkalender = true
        case .zwemmen:
            showZwemmen = true
        case .buurt:
            // Eén bron voor de tab-slide: laat de .animation(value: selectedTab)
            // op de content de overgang verzorgen (geen dubbele animatie).
            selectedTab = .buurt
        case .overlast:
            // Melding maken loopt via de Regelen-assistent.
            selectedTab = .regelen
        case .ooievaarspas:
            showOoievaarspas = true
        case .afspraak:
            showAppointment = true
        case .rechten:
            infoKind = .rechten
        case .bieb:
            infoKind = .bieb
        case .buurtFilter(let topic):
            buurtFilter = topic
            selectedTab = .buurt
        }
    }
}

/// Plaatst een tab in de paged-push. Clipt de tab ALLEEN horizontaal (boven- en
/// onderkant blijven vrij), zodat scrollClipDisabled-carrousels niet naar andere
/// tabs doorlekken, maar de gele home-header wél achter de notch mag en de
/// buurt-kaart tot de onderkant doorloopt. Deterministisch — ook op device.
private struct TabSlide: ViewModifier {
    let offset: CGFloat
    let active: Bool

    func body(content: Content) -> some View {
        content
            .clipShape(HorizontalClip())
            .offset(x: offset)
            .allowsHitTesting(active)
    }
}

/// Clip-vorm die de volledige breedte neemt maar verticaal ver buiten de bounds
/// doorloopt — knipt dus enkel links/rechts, niet boven/onder.
private struct HorizontalClip: Shape {
    func path(in rect: CGRect) -> Path {
        Path(CGRect(x: rect.minX, y: rect.minY - 3000, width: rect.width, height: rect.height + 6000))
    }
}
