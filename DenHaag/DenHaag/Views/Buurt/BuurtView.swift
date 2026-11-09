import SwiftUI
import MapKit

struct BuurtView: View {
    @EnvironmentObject var lang: LanguageManager
    @EnvironmentObject var versie: VersieManager
    @EnvironmentObject var rol: RolManager

    enum LocationMode { case thuis, werk }

    /// Vaste volgorde + labels van de buurt-onderwerpen (matcht de onboarding-chips,
    /// afvalkalender staat bewust niet op de kaart).
    static let topicOrder = ["ondernemen", "evenementen", "sport", "wegwerk", "bouwplannen", "participatie", "fietsparkeren", "koffie"]
    /// Onderwerpen met vaste plekken door de hele stad, niet met wat er rond je huis speelt.
    static let plekTopics: Set<String> = ["fietsparkeren", "koffie"]
    private func topicLabel(_ id: String) -> String {
        switch id {
        case "ondernemen":  return lang.t("buurt_topic_zaak")
        case "fietsparkeren": return lang.t("fiets_parkeren_title")
        case "koffie":      return lang.t("fiets_koffie_title")
        case "evenementen": return "Evenementen"
        case "sport":       return "Sport"
        case "wegwerk":     return "Werk aan de weg"
        case "bouwplannen": return "Bouwplannen"
        case "participatie": return "Participatie"
        default:            return id.capitalized
        }
    }

    /// Native zoom-transitie van kaartje → detailpagina (iOS 18+).
    @Namespace private var zoomNS
    @State private var detailItem: NeighbourhoodItem?
    /// Geeft MainTabView door of het detail open is (om de tab bar te verbergen).
    @Binding var detailOpen: Bool
    /// Een buurt-snelkoppel-tegel op de home kan een onderwerp-filter aanvragen.
    /// nil = geen verzoek. Wordt na toepassen weer leeggemaakt.
    @Binding var requestedFilter: String?

    @State private var locationMode: LocationMode = .thuis
    @AppStorage("werkAddress") private var werkAddress = ""
    @State private var showWerkSheet = false
    @State private var werkInput = ""

    /// nil = "Alles"; anders een onderwerp-id.
    @State private var filter: String? = nil
    // Standaard opent de kaart op je thuisadres, ingezoomd op straatniveau,
    // met de pulserende radar in het midden. Niks geselecteerd.
    @State private var cameraRegion: MKCoordinateRegion = BuurtView.homeRegion(BuurtView.thuisCoord)
    @State private var cameraVersion: Int = 0
    @State private var selectedItemID: UUID? = nil
    @State private var scrolledID: UUID? = nil
    /// Debounce voor de camera: bij snel door de carrousel scrollen niet telkens
    /// een nieuwe lange camera-animatie starten, alleen op de uiteindelijke kaart.
    @State private var cameraWork: DispatchWorkItem? = nil
    /// Bij openen op vaste plekken: zoom zo uit dat jij én de dichtstbijzijnde
    /// plek in beeld zijn, in plaats van strak op de plek in te zoomen.
    @State private var toonOokThuis = false

    private func moveCamera(to region: MKCoordinateRegion) {
        cameraRegion = region
        cameraVersion += 1
    }

    private static let allItems = NeighbourhoodItem.voorOndernemer + NeighbourhoodItem.sample
        + NeighbourhoodItem.stallingen + NeighbourhoodItem.koffieplekken

    /// Alleen de onderwerpen die de gekozen versie van de app heeft.
    private var items: [NeighbourhoodItem] {
        Self.allItems.filter {
            versie.current.allowsBuurtTopic($0.topic)
                && ($0.topic != "ondernemen" || rol.isOndernemer)
                // De ondernemer krijgt de Hoefkade-werkzaamheden in een eigen versie.
                && !(rol.isOndernemer && $0.title == "Werkzaamheden Hoefkade")
        }
    }

    /// Zonder buurtnieuws (versie 1 en 2) staan er alleen vaste plekken op de
    /// kaart. "Alles" zou dan leeg zijn, dus valt die chip weg.
    private var alleenPlekken: Bool {
        !items.contains { $0.plek == nil }
    }

    /// Het filter dat echt geldt: zonder keuze en zonder buurtnieuws het eerste onderwerp.
    private var effectiveFilter: String? {
        filter ?? (alleenPlekken ? allTopics.first : nil)
    }

    private var plekFilterActive: Bool {
        effectiveFilter.map(Self.plekTopics.contains) ?? false
    }

    // Vaste coördinaten (prototype)
    static let thuisCoord = CLLocationCoordinate2D(latitude: 52.0710, longitude: 4.2998)
    static let werkCoord = CLLocationCoordinate2D(latitude: 52.0850, longitude: 4.3100)
    /// Kapsalon Anne, Hoefkade 12 (prototype).
    static let zaakCoord = CLLocationCoordinate2D(latitude: 52.0618, longitude: 4.2994)

    private var homeCoordinate: CLLocationCoordinate2D {
        // Als ondernemer staat de kaart standaard rondom je zaak.
        if locationMode == .thuis { return rol.isOndernemer ? Self.zaakCoord : Self.thuisCoord }
        return Self.werkCoord
    }

    /// Alle onderwerpen die in de data voorkomen, in vaste volgorde. De kaart toont
    /// ALTIJD alle filters — los van de onboarding-keuzes (die bepalen alleen welke
    /// snelkoppel-tegels op de home komen).
    private var allTopics: [String] {
        let present = Set(items.map { $0.topic })
        return Self.topicOrder.filter { present.contains($0) }
    }

    private var filteredItems: [NeighbourhoodItem] {
        // "Alles" gaat over wat er speelt in de buurt; vaste plekken horen daar niet bij.
        guard let f = effectiveFilter else { return items.filter { $0.plek == nil } }
        let lijst = items.filter { $0.topic == f }
        // Vaste plekken (stallingen): dichtstbijzijnde eerst.
        guard Self.plekTopics.contains(f) else { return lijst }
        let thuis = CLLocation(latitude: homeCoordinate.latitude, longitude: homeCoordinate.longitude)
        return lijst.sorted {
            CLLocation(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude).distance(from: thuis)
                < CLLocation(latitude: $1.coordinate.latitude, longitude: $1.coordinate.longitude).distance(from: thuis)
        }
    }

    private var safeTop: CGFloat { AppDesign.safeAreaTop }

    var body: some View {
        NavigationStack {
        VStack(spacing: 0) {
            header

            ZStack(alignment: .top) {
                map

                // Progressieve blur aan de bovenrand: de kaart verzacht geleidelijk
                // naar de filterchips toe, zodat die goed leesbaar blijven.
                VariableBlurView(maxBlurRadius: 22, edge: .top)
                    .frame(height: 84)
                    .allowsHitTesting(false)

                // Chips op de naad: half op de witte header, half op de kaart.
                filterChips
                    .padding(.top, 12)
                    .offset(y: -28)

                VStack {
                    Spacer()
                    carousel
                        .padding(.bottom, 95) // 15px lager dan voorheen (was 110)
                }
            }
        }
        .background(AppColors.background)
        // Ook de top-safe-area negeren: de header rekent de notch-hoogte zelf
        // al mee (safeTop), dus zo voorkomen we dubbeltelling en komt
        // "Rondom thuis" netjes nét onder de notch — de kaart wint die hoogte.
        .ignoresSafeArea(edges: [.top, .bottom])
        .onChange(of: requestedFilter) { _, new in
            // Een snelkoppel-tegel op de home vroeg om een onderwerp-filter.
            guard let new else { return }
            withAnimation(.easeInOut(duration: 0.2)) {
                filter = Self.topicOrder.contains(new) ? new : nil
            }
            requestedFilter = nil  // verzoek verwerkt; weer leeg voor de volgende keer
        }
        .onChange(of: selectedItemID) { _, newID in
            guard let newID else { return }
            if scrolledID != newID {
                withAnimation { scrolledID = newID }
            }
            if let item = items.first(where: { $0.id == newID }) {
                let region = toonOokThuis ? Self.regioMet(homeCoordinate, item.coordinate) : Self.itemRegion(item.coordinate)
                toonOokThuis = false
                cameraWork?.cancel()
                let work = DispatchWorkItem { moveCamera(to: region) }
                cameraWork = work
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: work)
            }
        }
        .onChange(of: scrolledID) { _, newID in
            guard let newID, selectedItemID != newID else { return }
            selectedItemID = newID
        }
        .onChange(of: filter) { _, _ in
            // Na filterwissel direct inzoomen op het eerste passende item; bij
            // vaste plekken zo dat jij er ook op staat.
            if let first = filteredItems.first?.id {
                toonOokThuis = plekFilterActive
                selectedItemID = first
                scrolledID = first
            } else {
                selectedItemID = nil
                scrolledID = nil
                moveCamera(to: Self.homeRegion(homeCoordinate))
            }
        }
        .onChange(of: versie.current) { _, _ in
            // Andere versie, andere onderwerpen: terug naar de begintoestand.
            filter = nil
            selectFirstPlekIfNeeded()
        }
        .onAppear {
            if rol.isOndernemer { moveCamera(to: Self.homeRegion(homeCoordinate)) }
            selectFirstPlekIfNeeded()
        }
        .onChange(of: rol.rol) { _, _ in
            // Andere rol, ander middelpunt (thuis of je zaak) en andere onderwerpen.
            filter = nil
            selectedItemID = nil
            scrolledID = nil
            moveCamera(to: Self.homeRegion(homeCoordinate))
            selectFirstPlekIfNeeded()
        }
        .onChange(of: locationMode) { _, mode in
            selectedItemID = nil
            scrolledID = nil
            moveCamera(to: Self.homeRegion(homeCoordinate))
            AnalyticsService.track("buurt_location", ["mode": String(describing: mode)])
        }
        .onChange(of: detailItem) { _, new in
            // De tab bar verbergen zolang het detail open is.
            withAnimation(.easeInOut(duration: 0.25)) { detailOpen = (new != nil) }
            if let item = new {
                AnalyticsService.track("open_buurt_detail", ["title": item.title])
                AnalyticsService.screen("buurt_detail")
            } else {
                AnalyticsService.screen("buurt")
            }
        }
        .sheet(isPresented: $showWerkSheet) {
            werkSheet
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $detailItem) { item in
            BuurtDetailView(item: item)
                .toolbar(.hidden, for: .navigationBar)
                .modifier(ZoomDestination(id: item.id, ns: zoomNS))
        }
        }
    }

    /// Staan er alleen vaste plekken op de kaart, dan meteen de eerste tonen in
    /// plaats van een kaart rond thuis zonder iets erop.
    private func selectFirstPlekIfNeeded() {
        guard alleenPlekken, filter == nil, let first = filteredItems.first?.id else { return }
        toonOokThuis = true
        selectedItemID = first
        scrolledID = first
    }

    // MARK: - Header (dropdown thuis/werk)

    private var header: some View {
        HStack(spacing: 6) {
            Text(lang.t("buurt_around"))
                .font(AppFont.theMix(size: 26, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            Menu {
                Button(lang.t(rol.isOndernemer ? "buurt_zaak" : "buurt_home")) { locationMode = .thuis }
                if werkAddress.isEmpty {
                    Button(lang.t("buurt_set_work")) {
                        werkInput = ""
                        showWerkSheet = true
                    }
                } else {
                    Button(lang.t("buurt_work")) { locationMode = .werk }
                    Button(lang.t("buurt_change_work")) {
                        werkInput = werkAddress
                        showWerkSheet = true
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(plekFilterActive ? lang.t("buurt_my_location")
                         : locationMode == .thuis ? lang.t(rol.isOndernemer ? "buurt_zaak" : "buurt_home") : lang.t("buurt_work"))
                        .font(AppFont.theMix(size: 26, weight: .bold))
                        .foregroundColor(AppColors.groen3)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.groen3)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, safeTop + 18)
        .padding(.bottom, 24)
        .background(AppColors.background)
    }

    // MARK: - Map

    private var map: some View {
        BuurtMapView(
            items: filteredItems,
            homeCoordinate: homeCoordinate,
            selectedItemID: $selectedItemID,
            region: cameraRegion,
            regionVersion: cameraVersion
        )
    }

    // MARK: - Filter chips

    private var filterChips: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    if !alleenPlekken {
                        chip(lang.t("buurt_filter_all"), nil)
                    }
                    ForEach(allTopics, id: \.self) { topic in
                        chip(topicLabel(topic), topic)
                            .id(topic)
                    }
                }
                .padding(.horizontal, AppDesign.horizontalPadding)
            }
            // Een filter dat van buiten is gezet (home-tegel) kan buiten beeld
            // staan; schuif de gekozen chip dan in beeld.
            .onChange(of: filter) { _, new in
                guard let new else { return }
                // Kort wachten: de koffie-chip bestaat pas ná de filterwissel.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation { proxy.scrollTo(new, anchor: .center) }
                }
            }
        }
    }

    private func chip(_ title: String, _ value: String?) -> some View {
        let isSelected = effectiveFilter == value
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                filter = value
                selectedItemID = nil
                scrolledID = nil
            }
            AnalyticsService.track("buurt_filter", ["filter": value ?? "alles"])
        } label: {
            Text(title)
                .font(AppFont.theSans(size: 13, weight: .semiBold))
                .foregroundColor(isSelected ? AppColors.groen3 : AppColors.textPrimary)
                .padding(.horizontal, 13)
                .padding(.vertical, 8)
                .background(isSelected ? AppColors.groen3.opacity(0.12) : Color.white)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(isSelected ? AppColors.groen3 : AppColors.grijs2, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Carousel

    private var carousel: some View {
        GeometryReader { geo in
            let cardWidth: CGFloat = 290
            let sideInset = max(0, (geo.size.width - cardWidth) / 2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(filteredItems) { item in
                        card(for: item)
                            .frame(width: cardWidth)
                            // Actief kaartje vol formaat; buren kleiner maar
                            // verticaal gecentreerd t.o.v. het grote kaartje
                            // (niet onderaan uitgelijnd — dus geen y-offset).
                            .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                                content
                                    .scaleEffect(phase.isIdentity ? 1.0 : 0.866)
                            }
                            .id(item.id)
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, sideInset, for: .scrollContent)
            .scrollClipDisabled()
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $scrolledID)
            // Begrens de carrousel horizontaal op de eigen breedte: buur-kaartjes
            // kunnen zo niet buiten het scherm (en achter een andere tab) lekken.
            // Verticaal blijft vrij voor schaduw en de schaal van het centrale kaartje.
            .clipShape(HorizontalOverflowClip())
        }
        .frame(height: 330)
    }

    /// Een vaste plek heeft geen detailpagina; tikken zoomt alleen naar de pin.
    @ViewBuilder
    private func card(for item: NeighbourhoodItem) -> some View {
        if let plek = item.plek {
            PlekCardView(plek: plek, isKoffie: item.type == .koffie, actief: selectedItemID == item.id)
                .onTapGesture { selectedItemID = item.id }
        } else {
            BuurtCardView(item: item)
                // Native zoom-transitie: dit kaartje is de bron.
                .modifier(ZoomSource(id: item.id, ns: zoomNS))
                // Tik → open de detailpagina (zoomt vanuit het kaartje).
                .onTapGesture { detailItem = item }
        }
    }

    // MARK: - Werkadres sheet

    private var werkSheet: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(lang.t("buurt_set_work"))
                .font(AppFont.theMix(size: 24, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            TextField(lang.t("buurt_work_placeholder"), text: $werkInput)
                .font(AppFont.theSans(size: 18, weight: .plain))
                .padding(16)
                .overlay(
                    RoundedRectangle(cornerRadius: AppDesign.cornerRadius)
                        .stroke(AppColors.grijs2, lineWidth: 1)
                )

            Button {
                let trimmed = werkInput.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    werkAddress = trimmed
                    locationMode = .werk
                }
                showWerkSheet = false
            } label: {
                Text(lang.t("buurt_save"))
                    .font(AppFont.theSans(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppColors.groen3)
                    .clipShape(RoundedRectangle(cornerRadius: AppDesign.cornerRadius))
            }

            Spacer()
        }
        .padding(AppDesign.horizontalPadding)
        .padding(.top, 32)
        .presentationDetents([.height(260)])
    }

    // MARK: - Regio-helpers

    /// Standaardweergave: ingezoomd op straatniveau rond het thuisadres, met de
    /// locatie iets boven het midden zodat de radar in het zichtbare midden valt
    /// (boven de kaartjes-carrousel).
    static func homeRegion(_ center: CLLocationCoordinate2D) -> MKCoordinateRegion {
        let offsetCenter = CLLocationCoordinate2D(latitude: center.latitude - 0.0017, longitude: center.longitude)
        return MKCoordinateRegion(center: offsetCenter, span: MKCoordinateSpan(latitudeDelta: 0.006, longitudeDelta: 0.006))
    }

    /// Regio waarin zowel jij als de plek staan, met ruimte voor de chips
    /// bovenin en de carrousel onderin.
    static func regioMet(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> MKCoordinateRegion {
        let dLat = abs(a.latitude - b.latitude), dLon = abs(a.longitude - b.longitude)
        // Beide punten in de bovenste ~40% van de kaart, boven het kaartje.
        let span = max(dLat * 3.4, dLon * 1.7, 0.008)
        let midden = CLLocationCoordinate2D(latitude: (a.latitude + b.latitude) / 2 - span * 0.27,
                                            longitude: (a.longitude + b.longitude) / 2)
        return MKCoordinateRegion(center: midden, span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span))
    }

    /// Strak ingezoomd op het gekozen item; het item zit boven het midden
    /// zodat de (vergrote) geselecteerde pin ruim boven de carrousel uitkomt.
    static func itemRegion(_ center: CLLocationCoordinate2D) -> MKCoordinateRegion {
        // Kleine offset: de actieve marker komt nét boven het midden te staan
        // (ruim in beeld, boven het kaartje) — niet meer achter de chips.
        let offsetCenter = CLLocationCoordinate2D(latitude: center.latitude - 0.0015, longitude: center.longitude)
        return MKCoordinateRegion(center: offsetCenter, span: MKCoordinateSpan(latitudeDelta: 0.009, longitudeDelta: 0.009))
    }
}

// MARK: - Native zoom-transitie (iOS 18+)

/// Markeert het bron-element (het kaartje) voor de zoom-transitie.
struct ZoomSource: ViewModifier {
    let id: UUID
    let ns: Namespace.ID

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.matchedTransitionSource(id: id, in: ns)
        } else {
            content
        }
    }
}

/// Koppelt het detailscherm aan de zoom-transitie vanuit het bron-kaartje.
struct ZoomDestination: ViewModifier {
    let id: UUID
    let ns: Namespace.ID

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.navigationTransition(.zoom(sourceID: id, in: ns))
        } else {
            content
        }
    }
}

// MARK: - Pin-vorm

/// Naar beneden wijzende driehoek voor de pin-punt (gebruikt door de kaart-pins).
struct PinTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
