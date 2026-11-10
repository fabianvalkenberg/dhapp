import SwiftUI
import MapKit

struct OnboardingView: View {
    @EnvironmentObject var lang: LanguageManager
    @EnvironmentObject var versie: VersieManager
    @ObservedObject var settings: HomeSettingsModel
    var onFinish: () -> Void

    @State private var step: Int
    @State private var isLoggingIn = false
    @State private var loggedIn = false
    // Twee voorkeuren-stappen — niets vooraf aangevinkt, de gebruiker kiest zelf.
    @State private var selectedTaken: Set<String> = []         // stap 1: gemeente-taken
    @State private var selectedOnderwerpen: Set<String> = []   // stap 2: buurt-onderwerpen
    // Zorgt dat we de naam per sessie precies één keer leegmaken.
    @State private var didResetName = false

    /// Zonder buurtnieuws (versie 1 en 2) valt de laatste stap weg: er is dan
    /// niets te volgen in de buurt.
    private var totalSteps: Int { versie.current.heeft(.buurtLeven) ? 7 : 6 }
    private let gemeenteStep = 5
    private let buurtStep = 6

    /// Alleen de keuzes waarvan de tegel in deze versie bestaat.
    private var takenInVersie: [OnboardChip] {
        Self.gemeenteTaken.filter { $0.tileID.map(versie.current.allowsTile) ?? true }
    }
    private var onderwerpenInVersie: [OnboardChip] {
        Self.buurtOnderwerpen.filter { $0.tileID.map(versie.current.allowsTile) ?? true }
    }

    /// Uitleg "Met deze app kan je …" past zich aan wat er in de versie zit.
    private var regelenTekst: (String, String) {
        if versie.current.heeft(.regelen) { return (lang.t("onb_regelen_title"), lang.t("onb_regelen_body")) }
        if versie.current.heeft(.voorJou) { return (lang.t("onb_v2_regelen_title"), lang.t("onb_v2_regelen_body")) }
        return (lang.t("onb_v1_regelen_title"), lang.t("onb_v1_regelen_body"))
    }
    private var buurtTekst: (String, String) {
        versie.current.heeft(.buurtLeven)
            ? (lang.t("onb_buurt_title"), lang.t("onb_buurt_body"))
            : (lang.t("onb_fiets_title"), lang.t("onb_fiets_body"))
    }

    init(settings: HomeSettingsModel, onFinish: @escaping () -> Void) {
        self.settings = settings
        self.onFinish = onFinish
        _step = State(initialValue: 0)
    }

    // MARK: - Voorkeuren-chips

    /// Stap 1 — gemeente-taken. `tileID` koppelt aan een home-tegel (nil = geen
    /// directe tegel; selectie wordt wel gelogd).
    static let gemeenteTaken: [OnboardChip] = [
        OnboardChip(id: "parkeren",     label: "Parkeerbezoek aanmelden",   tileID: "parkeerbezoek", illustration: nil),
        OnboardChip(id: "melden",       label: "Iets melden op straat",     tileID: "overlast",      illustration: nil),
        OnboardChip(id: "afspraak",     label: "Afspraak maken",            tileID: "afspraak",      illustration: nil),
        OnboardChip(id: "afvalkalender", label: "Afvalkalender",            tileID: "afvalkalender", illustration: nil),
        OnboardChip(id: "afval",        label: "Afval wegbrengen",          tileID: "afval",         illustration: nil),
        OnboardChip(id: "ooievaarspas", label: "Ooievaarspas",              tileID: "ooievaarspas",  illustration: nil),
        OnboardChip(id: "rechten",      label: "Waar heb ik recht op",      tileID: "rechten",       illustration: nil),
        OnboardChip(id: "bieb",         label: "Naar de bieb",              tileID: "bieb",          illustration: nil),
        OnboardChip(id: "fietsparkeren", label: "Fiets stallen",            tileID: "fietsparkeren", illustration: nil),
        OnboardChip(id: "fietspas",     label: "Fietspas",                  tileID: "fietspas",      illustration: nil),
    ]

    /// Stap 2 — buurt-onderwerpen. Elke keuze levert een snelkoppel-tegel op die
    /// de buurt-kaart opent met dat onderwerp aan. De keuze beïnvloedt NIET de
    /// filters op de kaart zelf — daar staat altijd alles aan. `tileID` koppelt aan
    /// de buurt-snelkoppel-tegel; `id` is het kaart-onderwerp (voor logging).
    static let buurtOnderwerpen: [OnboardChip] = [
        OnboardChip(id: "evenementen",   label: "Evenementen",               tileID: "buurt_evenementen", illustration: nil),
        OnboardChip(id: "sport",         label: "Sport",                     tileID: "buurt_sport",       illustration: nil),
        OnboardChip(id: "wegwerk",       label: "Wegwerkzaamheden",          tileID: "buurt_wegwerk",     illustration: nil),
        OnboardChip(id: "bouwplannen",   label: "Bouwplannen",               tileID: "buurt_bouwplannen", illustration: nil),
        OnboardChip(id: "participatie",  label: "Participatiemogelijkheden", tileID: "buurt_participatie", illustration: nil),
    ]

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Stap-inhoud
                ZStack {
                    switch step {
                    case 0: digidIntroStep
                    case 1: gegevensStep
                    case 2: naamStep
                    case 3: uitlegRegelenStep
                    case 4: uitlegBuurtStep
                    case 5: gemeenteVoorkeurenStep
                    default: buurtVoorkeurenStep
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .id(step)

                // Onderkant: knoppen + paginadots
                controls
            }
            .padding(.horizontal, AppDesign.horizontalPadding)
        }
        .animation(.easeInOut(duration: 0.35), value: step)
        .onChange(of: step) { _, s in
            AnalyticsService.track("onboarding_step", ["step": s])
        }
        .onAppear {
            // Elke nieuwe onboarding-sessie vraagt opnieuw om de naam: maak het
            // eventueel onthouden veld leeg zodat het invulveld weer blanco start
            // (en een 'overslaan' terugvalt op "Anne").
            if !didResetName {
                didResetName = true
                settings.userName = ""
            }
        }
    }

    // MARK: - Stappen

    private var digidIntroStep: some View {
        VStack(spacing: 0) {
            Spacer()
            digidLogo
            Spacer().frame(height: 40)
            textBlock(
                title: lang.t("onb_digid_title"),
                body: lang.t(versie.current.heeft(.voorJou) ? "onb_digid_body" : "onb_v1_digid_body")
            )
            Spacer()
        }
    }

    /// "Gegevens ophalen": laat compact zien wat er voor je is opgehaald — geen
    /// volledige kaarten met knoppen, alleen de titels als korte regels.
    private var gegevensStep: some View {
        VStack(spacing: 0) {
            Spacer()
            digidLogo
            Spacer().frame(height: 28)
            // Zonder "voor jou" (versie 1) zijn er geen lopende zaken om op te halen.
            textBlock(
                title: lang.t("onb_gegevens_title"),
                body: lang.t(versie.current.heeft(.voorJou) ? "onb_gegevens_body" : "onb_v1_gegevens_body")
            )
            Spacer().frame(height: 28)

            VStack(spacing: 12) {
                if versie.current.heeft(.voorJou) {
                    gegevensRow(icon: "calendar", text: "Afspraak: nieuw paspoort")
                    gegevensRow(icon: "doc.text", text: "Aanvraag uitbouw")
                } else {
                    gegevensRow(icon: "person", text: lang.t("onb_v1_gegevens_naam"))
                    gegevensRow(icon: "house", text: lang.t("onb_v1_gegevens_adres"))
                }
            }

            Spacer()
        }
    }

    private func gegevensRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppColors.groen3)
                .frame(width: 22)
            Text(text)
                .font(AppFont.theSans(size: 16, weight: .semiBold))
                .foregroundColor(AppColors.darkGrey)
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(AppColors.groen3)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppColors.grijs2, lineWidth: 1)
        )
    }

    private var digidLogo: some View {
        Image("digid")
            .resizable()
            .scaledToFit()
            .frame(width: 116, height: 116)
    }

    private var naamStep: some View {
        VStack(spacing: 0) {
            Spacer()
            Spacer()

            Text(lang.t("onb_naam_title"))
                .font(AppFont.theMix(size: 30, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)

            Spacer().frame(height: 8)

            Text(lang.t("onb_naam_sub"))
                .font(AppFont.theSans(size: 18, weight: .plain))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            Spacer().frame(height: 24)

            TextField(lang.t("onb_naam_placeholder"), text: $settings.userName)
                .font(AppFont.theSans(size: 18, weight: .plain))
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, 18)
                .padding(.vertical, 18)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: AppDesign.cornerRadius)
                        .stroke(AppColors.grijs2, lineWidth: 1)
                )
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.next)
                .onSubmit { advance() }

            Spacer()
        }
    }

    private var uitlegRegelenStep: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 32)
            introLine
            Spacer().frame(height: 16)
            illustrationPanel { paspoortIllustration }
                .clipShape(RoundedRectangle(cornerRadius: 12))
            Spacer().frame(height: 28)
            textBlock(
                title: regelenTekst.0,
                body: regelenTekst.1
            )
            Spacer()
        }
    }

    private var uitlegBuurtStep: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 32)
            introLine
            Spacer().frame(height: 16)
            buurtMapIllustration
                .clipShape(RoundedRectangle(cornerRadius: 12))
            Spacer().frame(height: 28)
            textBlock(
                title: buurtTekst.0,
                body: buurtTekst.1
            )
            Spacer()
        }
    }

    /// Vaste, groene, gecentreerde introregel "Met deze app kan je" boven de
    /// afbeelding — op beide uitleg-pagina's.
    private var introLine: some View {
        Text(lang.t("onb_app_intro"))
            .font(AppFont.theMix(size: 22, weight: .bold))
            .foregroundColor(AppColors.groen3)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    /// Stap 1: "Wat doe jij vaak bij de gemeente?" — bepaalt de home-tegels.
    private var gemeenteVoorkeurenStep: some View {
        chipStep(
            title: lang.t("onb_taken_title"),
            subtitle: lang.t("onb_taken_sub"),
            chips: takenInVersie,
            selection: $selectedTaken
        )
    }

    /// Stap 2: "Wat wil je volgen over je buurt?"
    private var buurtVoorkeurenStep: some View {
        chipStep(
            title: lang.t("onb_buurtvoork_title"),
            subtitle: lang.t("onb_buurtvoork_sub"),
            chips: onderwerpenInVersie,
            selection: $selectedOnderwerpen
        )
    }

    private func chipStep(title: String, subtitle: String,
                          chips: [OnboardChip], selection: Binding<Set<String>>) -> some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)
            VStack(spacing: 12) {
                Text(title)
                    .font(AppFont.theMix(size: 30, weight: .bold))
                    .foregroundColor(AppColors.darkGrey)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(AppFont.theSans(size: 18, weight: .plain))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            .frame(maxWidth: .infinity)

            Spacer().frame(height: 28)

            ScrollView(showsIndicators: false) {
                FlowLayout(spacing: 8, lineSpacing: 12) {
                    ForEach(chips) { chip in
                        ChoiceChip(
                            label: chip.label,
                            selected: selection.wrappedValue.contains(chip.id)
                        ) {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                if selection.wrappedValue.contains(chip.id) {
                                    selection.wrappedValue.remove(chip.id)
                                } else {
                                    selection.wrappedValue.insert(chip.id)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 2)
            }

            Spacer()
        }
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 16) {
            primaryButton(title: primaryLabel, loading: isLoggingIn, action: primaryAction)

            Button(action: { finishOnboarding(skipped: true) }) {
                Text(secondaryLabel)
                    .font(AppFont.theSans(size: 16, weight: .bold))
                    .foregroundColor(AppColors.groen3)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }

            // Paginadots
            HStack(spacing: 8) {
                ForEach(0..<totalSteps, id: \.self) { i in
                    Capsule()
                        .fill(i == step ? AppColors.groen3 : AppColors.grijs2)
                        .frame(width: i == step ? 24 : 8, height: 8)
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: step)
            .padding(.top, 4)
        }
        .padding(.bottom, 20)
    }

    private var primaryLabel: String {
        step == 0 ? lang.t("onb_digid_button") : lang.t("onb_next")
    }

    private var secondaryLabel: String {
        (step == gemeenteStep || step == buurtStep) ? lang.t("onb_later") : lang.t("onb_skip")
    }

    private func primaryAction() {
        switch step {
        case 0:
            if loggedIn {
                advance()
            } else {
                // Nagebootst inloggen, inline op dezelfde stap (geen los scherm).
                isLoggingIn = true
                loggedIn = true
                AnalyticsService.track("digid_login")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    isLoggingIn = false
                    advance()
                }
            }
        case totalSteps - 1:
            finishOnboarding(skipped: false)
        default:
            advance()
        }
    }

    private func advance() {
        withAnimation(.easeInOut(duration: 0.35)) {
            if step < totalSteps - 1 { step += 1 }
        }
    }

    /// Rondt de onboarding af: vertaalt de gekozen taken naar home-tegels, bewaart
    /// de buurt-onderwerpen en logt de sessie (incl. naam).
    private func finishOnboarding(skipped: Bool) {
        // Beide stappen worden home-tegels: stap 1 = acties/info, stap 2 = buurt-
        // snelkoppelingen (die de kaart met een filter openen).
        let takenTiles = Self.gemeenteTaken
            .filter { selectedTaken.contains($0.id) }
            .compactMap { $0.tileID }
        let buurtTiles = Self.buurtOnderwerpen
            .filter { selectedOnderwerpen.contains($0.id) }
            .compactMap { $0.tileID }
        let tileIDs = Set(takenTiles + buurtTiles)

        // Alleen overschrijven als er echt iets is gekozen — anders blijven de
        // fabrieks-default-tegels staan (geen leeg startscherm bij 'Later instellen').
        if !tileIDs.isEmpty {
            settings.setSelection(ids: tileIDs)
        }
        // Buurt-onderwerpen alleen nog loggen (de kaart toont altijd alle filters).
        if !selectedOnderwerpen.isEmpty {
            UserDefaults.standard.set(Array(selectedOnderwerpen), forKey: "buurtTopics")
        }

        OnboardingLogService.logSession(
            selectedTileIDs: Array(tileIDs),
            skipped: skipped,
            name: settings.userName,
            gemeenteTaken: Array(selectedTaken),
            buurtTopics: Array(selectedOnderwerpen)
        )

        // Sessie verrijken met de onboarding-keuzes.
        AnalyticsService.setSession([
            "name": settings.userName.trimmingCharacters(in: .whitespacesAndNewlines),
            "gemeenteTaken": Array(selectedTaken),
            "buurtTopics": Array(selectedOnderwerpen),
            "homeTiles": Array(tileIDs),
            "onboardingSkipped": skipped
        ])
        AnalyticsService.track("onboarding_finish", ["skipped": skipped])
        onFinish()
    }

    // MARK: - Bouwstenen

    private func textBlock(title: String, body: String, overline: String? = nil) -> some View {
        VStack(spacing: 12) {
            VStack(spacing: 6) {
                if let overline {
                    Text(overline)
                        .font(AppFont.theSans(size: 16, weight: .semiBold))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                Text(title)
                    .font(AppFont.theMix(size: 30, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
            }

            Text(body)
                .font(AppFont.theSans(size: 18, weight: .plain))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity)
    }

    private func illustrationPanel<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.warmGrijs)
            content()
        }
        .frame(height: 220)
    }

    private var paspoortIllustration: some View {
        // Versie 1 gaat over melden, niet over aanvragen: dan de meld-illustratie.
        Image(versie.current.heeft(.voorJou) ? "illu-paspoort" : "ill-melding")
            .resizable()
            .scaledToFit()
            .frame(height: 130)
    }

    /// Dezelfde kaart + pins als in de Buurt-tab (CARTO-tegels, gele teardrop-pins
    /// en de pulserende thuis-radar), zodat de stijl in de onboarding al klopt.
    private var buurtMapIllustration: some View {
        BuurtMapView(
            // Zonder buurtnieuws de stallingen; die liggen verder weg, dus ruimer.
            items: versie.current.heeft(.buurtLeven)
                ? Array(NeighbourhoodItem.sample.prefix(6))
                : NeighbourhoodItem.stallingen,
            homeCoordinate: BuurtView.thuisCoord,
            selectedItemID: .constant(nil),
            // Gecentreerd op de thuislocatie zónder de carrousel-offset, zodat de
            // markers netjes midden in het kaartje staan i.p.v. bovenin geklemd.
            region: MKCoordinateRegion(
                center: BuurtView.thuisCoord,
                span: versie.current.heeft(.buurtLeven)
                    ? MKCoordinateSpan(latitudeDelta: 0.010, longitudeDelta: 0.010)
                    : MKCoordinateSpan(latitudeDelta: 0.030, longitudeDelta: 0.030)
            ),
            regionVersion: 0
        )
        .frame(height: 240)
        .allowsHitTesting(false)
    }

    private func primaryButton(title: String, loading: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if loading { ProgressView().tint(.white) }
                Text(loading ? lang.t("digid_loading") : title)
                    .font(AppFont.theSans(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppColors.groen3)
            .clipShape(RoundedRectangle(cornerRadius: AppDesign.cornerRadius))
        }
        .disabled(loading)
    }
}

// MARK: - Voorkeuren-chip

/// Eén selecteerbare optie in een voorkeuren-stap.
struct OnboardChip: Identifiable {
    let id: String
    let label: String
    let tileID: String?       // koppeling met een home-tegel (nil = geen tegel)
    let illustration: String? // asset-naam boven de chip (nil = alleen tekst)
}

/// Chip volgens het Figma-ontwerp: wit met grijze rand; geselecteerd lichtgroen
/// (#D5E7D4) met groene rand, groene tekst en een vinkje.
private struct ChoiceChip: View {
    let label: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(label)
                    .font(AppFont.theSans(size: 16, weight: selected ? .bold : .plain))
                    .foregroundColor(selected ? AppColors.groen4 : AppColors.grijs4)
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AppColors.groen4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(selected ? AppColors.groen1 : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(selected ? AppColors.groen3 : AppColors.grijs2, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .fixedSize()
    }
}

// MARK: - Flow-layout (chips die naar de volgende regel doorlopen)

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 12

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        var widest: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += lineHeight + lineSpacing
                lineHeight = 0
            }
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            widest = max(widest, x - spacing)
        }
        return CGSize(width: maxWidth == .infinity ? widest : maxWidth, height: y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += lineHeight + lineSpacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
