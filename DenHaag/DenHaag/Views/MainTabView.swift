import SwiftUI

struct MainTabView: View {
    @ObservedObject var settings: HomeSettingsModel
    @EnvironmentObject var versie: VersieManager
    @EnvironmentObject var berichten: BerichtenStore
    @EnvironmentObject var lang: LanguageManager
    @EnvironmentObject var melding: MeldingStore
    @EnvironmentObject var rol: RolManager
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
    @State private var showFietspas = false
    @State private var showMelding = false
    @State private var showBerichten = false
    @State private var showVergunningen = false
    @State private var showMeldingStatus = false
    /// Testversie: bij openen eerst je naam (één keer per sessie en bij wisselen).
    @State private var vraagNaam = false
    @StateObject private var fietspassen = FietspasStore()
    @State private var fietspasVolScherm = false
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
                // Opnieuw opbouwen bij een versie- of rolwissel; anders bleven
                // tegels en kop van de vorige keuze staan.
                .id("\(versie.current.rawValue)-\(rol.rol.rawValue)")
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

            // Mijn fietspassen ligt ónder de tabbalk (Figma C2): de tabs blijven zichtbaar.
            if showFietspas {
                MijnFietspassenView(
                    store: fietspassen,
                    isPresented: $showFietspas,
                    verbergTabbalk: $fietspasVolScherm,
                    onStallingen: {
                        showFietspas = false
                        buurtFilter = "fietsparkeren"
                        selectedTab = .buurt
                    }
                )
                .transition(.move(edge: .bottom))
                // Vaste laag: zonder zIndex slaat SwiftUI de wegschuif-animatie over.
                .zIndex(1)
            }

            // Bottom navigation — verdwijnt wanneer het buurt-detail open is.
            BottomTabBar(selectedTab: $selectedTab)
                .offset(y: (buurtDetailOpen || fietspasVolScherm) ? 160 : 0)
                .opacity((buurtDetailOpen || fietspasVolScherm) ? 0 : 1)
                .animation(.easeInOut(duration: 0.25), value: buurtDetailOpen)
                .animation(.easeInOut(duration: 0.25), value: fietspasVolScherm)
                .zIndex(2)

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

            if showBerichten {
                BerichtenView(isPresented: $showBerichten)
                    .transition(.move(edge: .trailing))
                    .zIndex(20)
            }

            if showMeldingStatus {
                MeldingStatusView(isPresented: $showMeldingStatus) {
                    showMeldingStatus = false
                    showMelding = true
                }
                .transition(.move(edge: .trailing))
                .zIndex(20)
            }

            if showVergunningen {
                VergunningenPageView(isPresented: $showVergunningen)
                    .transition(.move(edge: .trailing))
                    .zIndex(20)
            }

            // Nagebootste pushmelding, boven alles.
            if let push = berichten.push {
                VStack {
                    PushBannerView(bericht: push) {
                        withAnimation(.easeInOut(duration: 0.3)) { berichten.push = nil }
                        berichten.markeerGelezen(push.id)
                        showMelding = false
                        showBerichten = true
                    }
                    .padding(.top, AppDesign.safeAreaTop - 6)
                    Spacer()
                }
                .ignoresSafeArea(edges: .top)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(30)
            }

            if showMelding {
                MeldingView(isPresented: $showMelding) { wat, waar, nummer in
                    melding.nieuw(wat: wat, waar: waar, nummer: nummer)
                    // Na een paar tellen "in behandeling" (gelijk met de pushmelding).
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        if melding.laatste.nummer == nummer { melding.laatste.stap = 1 }
                    }
                    guard versie.current.heeft(.notificaties) else { return }
                    berichten.stuur(.meldingen, titel: lang.t("push_melding_titel"),
                                    tekst: String(format: lang.t("push_melding_tekst"), wat.lowercased(), nummer), na: 5)
                }
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
        .animation(.easeInOut(duration: 0.35), value: showMelding)
        .animation(.easeInOut(duration: 0.35), value: showFietspas)
        .animation(.easeInOut(duration: 0.35), value: showBerichten)
        .animation(.easeInOut(duration: 0.35), value: showVergunningen)
        .animation(.easeInOut(duration: 0.35), value: showMeldingStatus)
        .fullScreenCover(isPresented: $vraagNaam) {
            NaamOnboardingView(settings: settings) { vraagNaam = false }
                .environmentObject(lang)
        }
        .onChange(of: showMelding) { _, v in if v { AnalyticsService.track("open_melding") } }
        .onChange(of: showAanvraag) { _, v in if v { AnalyticsService.track("open_aanvraag") } }
        .onChange(of: showPaspoort) { _, v in if v { AnalyticsService.track("open_paspoort") } }
        .onChange(of: infoKind) { _, v in if let v { AnalyticsService.track("open_info", ["kind": String(describing: v)]) } }
        .fullScreenCover(isPresented: $showOoievaarspas) {
            PasDetailView(pas: .ooievaarspas)
        }
        .onChange(of: showFietspas) { _, v in if v { AnalyticsService.track("open_fietspas") } }
        .onAppear {
            AnalyticsService.screen("home")
            #if DEBUG
            // Testharnas: `-zwemmen` opent direct de mini-app Zwemmen.
            if ProcessInfo.processInfo.arguments.contains("-zwemmen") { showZwemmen = true }
            // `-melding` opent direct de meldflow.
            if ProcessInfo.processInfo.arguments.contains("-melding") { showMelding = true }
            // `-fietspas` opent direct Mijn fietspassen.
            if ProcessInfo.processInfo.arguments.contains("-fietspas") { showFietspas = true }
            // `-tab buurt` opent direct die tab.
            if let i = ProcessInfo.processInfo.arguments.firstIndex(of: "-tab"),
               i + 1 < ProcessInfo.processInfo.arguments.count,
               ProcessInfo.processInfo.arguments[i + 1] == "buurt" { selectedTab = .buurt }
            // `-tab regelen|hulp` opent die tab.
            if let i = ProcessInfo.processInfo.arguments.firstIndex(of: "-tab"),
               i + 1 < ProcessInfo.processInfo.arguments.count {
                switch ProcessInfo.processInfo.arguments[i + 1] {
                case "regelen": selectedTab = .regelen
                case "hulp": selectedTab = .hulp
                default: break
                }
            }
            // `-scherm <naam>` opent direct een detailscherm (voor screenshots).
            if let i = ProcessInfo.processInfo.arguments.firstIndex(of: "-scherm"),
               i + 1 < ProcessInfo.processInfo.arguments.count {
                switch ProcessInfo.processInfo.arguments[i + 1] {
                case "instellingen": showSettings = true
                case "startscherm": showCustomizeSheet = true
                case "afspraak": showAppointment = true
                case "parkeren": showParkeren = true
                case "afval": showAfval = true
                case "afvalkalender": showAfvalkalender = true
                case "kwijtschelding": showKwijtschelding = true
                case "aanvraag": showAanvraag = true
                case "paspoort": showPaspoort = true
                case "berichten": showBerichten = true
                case "vergunningen": showVergunningen = true
                case "meldingstatus": showMeldingStatus = true
                default: break
                }
            }
            // `-geennaam` slaat de naamvraag van de testversie over.
            if ProcessInfo.processInfo.arguments.contains("-geennaam") { return }
            #endif
            if versie.current.vraagtNaam { vraagNaam = true }
        }
        .onChange(of: versie.current) { _, nieuw in
            // Sta je op een tab die de nieuwe versie niet heeft, dan terug naar home.
            // Versie gekozen: direct terug naar home, met de tegels van die versie.
            showSettings = false
            selectedTab = .home
            settings.setSelection(ids: PreferenceTile.standaard(voor: nieuw))
            // Naar de testversie: eerst de naam vragen.
            if nieuw.vraagtNaam { vraagNaam = true }
        }
        .onChange(of: selectedTab) { _, t in
            // Een andere tab kiezen sluit de fietspassen.
            showFietspas = false
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
            // Melden loopt in elke versie via de meldflow (Figma "prototype MOR '26").
            showMelding = true
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
        case .fietsParkeren:
            buurtFilter = "fietsparkeren"
            selectedTab = .buurt
        case .berichten:
            showBerichten = true
        case .vergunningen:
            showVergunningen = true
        case .meldingStatus:
            showMeldingStatus = true
        case .fietspas:
            showFietspas = true
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
