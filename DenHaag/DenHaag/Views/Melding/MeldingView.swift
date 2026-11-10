import SwiftUI
import MapKit
import PhotosUI

/// Melding openbare ruimte, naar Figma "prototype MOR '26" (node 1104:5637) en
/// het huidige MOR-prototype. Stappen: intro → wat → (laden) → waar → foto's →
/// onveilig? → vervolgvragen → op de hoogte → klopt dit allemaal? → verstuurd.
/// Foto's is een eigen stap (in Figma zit hij nog bij "wat").
/// Prototype: er wordt niets echt verstuurd.
struct MeldingView: View {
    @EnvironmentObject var lang: LanguageManager
    @Binding var isPresented: Bool
    /// Na versturen: wat, waar en het meldnummer.
    var onVerstuurd: (_ wat: String, _ waar: String, _ nummer: String) -> Void = { _, _, _ in }

    enum Stap: Int, CaseIterable { case intro, wat, waar, foto, onveilig, vervolg, contact, controle, klaar }

    @State private var stap: Stap = .intro
    @State private var laden = false
    /// Na "bewerk" in de controle-stap: Volgende gaat terug naar de controle.
    @State private var terugNaarControle = false
    @State private var toonHulp = false

    // Wat
    @State private var tekst = ""
    @State private var gekozenTegel: MORCategorie?
    @StateObject private var spraak = SpeechService()
    @FocusState private var tekstFocus: Bool

    // Waar
    @State private var camera: MapCameraPosition = .region(MeldingView.regio(BuurtView.thuisCoord, span: 0.007))
    @State private var plek: CLLocationCoordinate2D?
    @State private var gekozenContainer: Int?
    @State private var adres: String?
    @State private var toonStraten = false
    /// Telt op bij elke kaartbeweging, zodat het wolkje opnieuw wordt geplaatst.
    @State private var kaartTik = 0

    // Foto's
    @State private var fotoItems: [PhotosPickerItem] = []
    @State private var fotos: [UIImage] = []

    // Vragen
    @State private var onveilig: Bool?
    @State private var antwoorden: [String: String] = [:]
    /// Welke vervolgvraag in beeld is: één vraag per scherm.
    @State private var vraagIndex = 0

    // Contact
    @State private var opDeHoogte: Bool?
    @State private var email = ""
    @State private var telefoon = ""
    @State private var contactBijVragen: Bool?

    @State private var meldnummer = ""
    @State private var keyboardHeight: CGFloat = 0

    private var categorie: MORCategorie { gekozenTegel ?? MORCategorie.herken(tekst) }
    private var heeftVervolg: Bool { !zichtbareVragen.isEmpty }

    /// Vervolgvragen die nu gelden: sommige vragen horen alleen bij een bepaald antwoord.
    private var zichtbareVragen: [MORVraag] {
        categorie.vervolg.filter { v in
            guard let bij = v.alleenBij else { return true }
            return bij.contains(antwoorden["soort"] ?? "")
        }
    }

    private var huidigeVraag: MORVraag? {
        zichtbareVragen.indices.contains(vraagIndex) ? zichtbareVragen[vraagIndex] : zichtbareVragen.first
    }

    private var bottomInset: CGFloat {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.keyWindow?.safeAreaInsets.bottom ?? 0
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                if stap != .klaar {
                    MORHeader(voortgang: voortgang, onTerug: terug, onHulp: { toonHulp = true }, onSluit: sluit)
                }

                ScrollView(showsIndicators: false) {
                    inhoud
                        .id("\(stap)-\(vraagIndex)")
                        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                                removal: .opacity))
                        .padding(.horizontal, stap == .waar ? 0 : 20)
                        .padding(.top, stap == .klaar ? 20 : 0)
                        .padding(.bottom, 20)
                }
                .scrollDisabled(stap == .waar)
                .scrollDismissesKeyboard(.interactively)

                knoppen
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    .background(Color.white)
            }
            .padding(.bottom, max(0, keyboardHeight - bottomInset))
            .blur(radius: laden ? 6 : 0)

            if laden {
                Color.white.opacity(0.6).ignoresSafeArea()
                MORLaden().transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: stap)
        .animation(.easeInOut(duration: 0.3), value: vraagIndex)
        .animation(.easeInOut(duration: 0.25), value: laden)
        .sheet(isPresented: $toonStraten) {
            MORStraatZoeker { straat in kiesStraat(straat) }
                .environmentObject(lang)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .alert(lang.t("mor_hulp_title"), isPresented: $toonHulp) {
            Button(lang.t("fp_ok"), role: .cancel) { }
        } message: {
            Text(lang.t("mor_hulp_tekst"))
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { note in
            if let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeOut(duration: 0.25)) { keyboardHeight = frame.height }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.25)) { keyboardHeight = 0 }
        }
        .onChange(of: spraak.transcript) { _, t in if spraak.isListening, !t.isEmpty { tekst = t } }
        .onChange(of: fotoItems) { _, items in laadFotos(items) }
        .onAppear {
            AnalyticsService.screen("melding")
            #if DEBUG
            testStart()
            #endif
        }
    }

    #if DEBUG
    /// Testharnas: `-meldstap <naam>` opent direct die stap met voorbeeldgegevens,
    /// om schermen naast Figma te leggen. `-meldcat container` kiest het onderwerp.
    private func testStart() {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-meldstap"), i + 1 < args.count,
              let doel = Stap.allCases.first(where: { "\($0)" == args[i + 1] }) else { return }
        var cat = MORCategorie.verlichting
        if let j = args.firstIndex(of: "-meldcat"), j + 1 < args.count, let c = MORCategorie(rawValue: args[j + 1]) { cat = c }
        if doel.rawValue > Stap.wat.rawValue || args.contains("-meldgevuld") {
            gekozenTegel = cat
            tekst = lang.t(cat.zinKey)
        }
        if doel.rawValue > Stap.waar.rawValue || args.contains("-meldplek") {
            zetPlek(BuurtView.thuisCoord, centreer: false)
        }
        if args.contains("-meldcontainer"), let c = MORContainer.rondThuis.dropFirst(3).first {
            gekozenContainer = c.id
            zetPlek(c.coordinate, centreer: false)
        }
        if doel.rawValue > Stap.onveilig.rawValue { onveilig = false }
        if doel.rawValue > Stap.vervolg.rawValue {
            for v in cat.vervolg { antwoorden[v.id] = v.opties[min(1, v.opties.count - 1)] }
        }
        if doel.rawValue > Stap.contact.rawValue || args.contains("-meldcontact") {
            opDeHoogte = true; email = "sanne@voorbeeld.nl"; contactBijVragen = false
        }
        if doel == .klaar { meldnummer = "SIG-123456" }
        stap = doel
    }
    #endif

    // MARK: - Voortgang

    /// Stappen met een balk; vervolg valt weg zonder vervolgvragen.
    private var balkStappen: [Stap] {
        [.wat, .waar, .foto, .onveilig] + (heeftVervolg ? [.vervolg] : []) + [.contact, .controle]
    }

    private var voortgang: CGFloat {
        let huidig = stap == .intro ? .wat : stap
        guard let i = balkStappen.firstIndex(of: huidig) else { return 0.23 }
        // Binnen de vervolgvragen loopt de balk per vraag een stukje op.
        let deel = stap == .vervolg && zichtbareVragen.count > 1
            ? CGFloat(vraagIndex) / CGFloat(zichtbareVragen.count) : 0
        return (CGFloat(i + 1) + deel) / CGFloat(balkStappen.count)
    }

    // MARK: - Inhoud per stap

    @ViewBuilder
    private var inhoud: some View {
        switch stap {
        case .intro:    introStap
        case .wat:      watStap
        case .waar:     waarStap
        case .foto:     fotoStap
        case .onveilig: onveiligStap
        case .vervolg:  vervolgStap
        case .contact:  contactStap
        case .controle: controleStap
        case .klaar:    klaarStap
        }
    }

    private var introStap: some View {
        VStack(spacing: 0) {
            Image("mor-hand")
                .resizable()
                .scaledToFit()
                .frame(width: 124, height: 95)
                .frame(width: 200, height: 200)
            (Text(lang.t("mor_intro_a"))
             + Text(lang.t("mor_intro_b")).font(AppFont.theMix(size: 25.2, weight: .bold)).foregroundColor(AppColors.groen3)
             + Text(lang.t("mor_intro_c")))
                .font(AppFont.theMix(size: 25.2, weight: .plain))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .frame(width: 238)
        }
        .padding(.vertical, 60)
        .padding(.top, 20)
        .frame(maxWidth: .infinity)
    }

    private var watStap: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                MORTitel(tekst: lang.t("mor_wat_title"))
                HStack(alignment: .top, spacing: 8) {
                    TextField("", text: $tekst,
                              prompt: Text(lang.t("mor_wat_placeholder")).foregroundColor(AppColors.textSecondary),
                              axis: .vertical)
                        .font(MORStijl.body)
                        .foregroundColor(AppColors.darkGrey)
                        .lineLimit(1...6)
                        .focused($tekstFocus)
                        .onChange(of: tekst) { _, nieuw in
                            // Zelf typen dat niet bij de tegel past: tegel los.
                            if let t = gekozenTegel, nieuw != lang.t(t.zinKey) { gekozenTegel = nil }
                        }
                    Button(action: wisselSpraak) {
                        Image("mor-mic")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(spraak.isListening ? AppColors.rood : AppColors.darkGrey)
                            .scaleEffect(spraak.isListening ? 1 + spraak.audioLevel * 0.3 : 1)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 16)
                .frame(minHeight: 59)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 3))
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(AppColors.grijs2, lineWidth: 1))
            }

            VStack(spacing: 16) {
                Text(lang.t("mor_kies_onderwerp"))
                    .font(MORStijl.bodyBold)
                    .foregroundColor(AppColors.darkGrey)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(MORCategorie.tegels) { cat in
                        MORTegel(emoji: cat.emoji, tekst: lang.t(cat.tegelKey), gekozen: gekozenTegel == cat) {
                            tekstFocus = false
                            gekozenTegel = cat
                            tekst = lang.t(cat.zinKey)
                        }
                    }
                }
            }
        }
    }

    private var waarStap: some View {
        VStack(spacing: 32) {
            MORTitel(tekst: lang.t(categorie.waarKey))
                .padding(.horizontal, 20)
            MapReader { proxy in
                Map(position: $camera) {
                    if categorie == .container {
                        ForEach(MORContainer.rondThuis) { c in
                            Annotation("", coordinate: c.coordinate, anchor: .center) {
                                containerPin(c)
                            }
                        }

                    } else if let plek {
                        Annotation("", coordinate: plek, anchor: .bottom) {
                            Image("mor-pin-gekozen")
                                .resizable()
                                .frame(width: 41, height: 67)
                                .offset(y: 8)
                        }
                    }
                }
                .mapStyle(.standard(emphasis: .muted, pointsOfInterest: .excludingAll))
                .onMapCameraChange(frequency: .continuous) { _ in kaartTik += 1 }
                .onTapGesture { punt in
                    guard categorie != .container, let coord = proxy.convert(punt, from: .local) else { return }
                    zetPlek(coord, centreer: false)
                }
                // Wolkje bij de gekozen container (Figma Step 7), boven alle pins.
                .overlay(alignment: .topLeading) {
                    if let id = gekozenContainer,
                       let c = MORContainer.rondThuis.first(where: { $0.id == id }),
                       let p = proxy.convert(c.coordinate, to: .local) {
                        MORWolkje(tekst: String(format: lang.t("mor_bedoel_container"),
                                                adres ?? lang.t("melding_waar_zoeken")))
                            .fixedSize()
                            .position(x: min(max(p.x, 140), 262), y: p.y + 26 + 40)
                            .allowsHitTesting(false)
                            .id(kaartTik)
                    }
                }
            }
            .frame(height: 477)
        }
    }

    private func containerPin(_ c: MORContainer) -> some View {
        let gekozen = gekozenContainer == c.id
        return Button {
            gekozenContainer = c.id
            zetPlek(c.coordinate, centreer: false)
        } label: {
            Image("mor-pin-container")
                .resizable()
                .frame(width: gekozen ? 36 : 28, height: gekozen ? 36 : 28)
                .overlay(Circle().stroke(AppColors.groen3, lineWidth: gekozen ? 3 : 0).padding(-2))
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: gekozen)
    }

    private var fotoStap: some View {
        VStack(spacing: 16) {
            MORTitel(tekst: lang.t("mor_foto_title"))
            Text(lang.t("mor_foto_sub"))
                .font(MORStijl.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 8)

            if !fotos.isEmpty {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(Array(fotos.enumerated()), id: \.offset) { i, foto in
                        Color.clear
                            .frame(height: 140)
                            .overlay(Image(uiImage: foto).resizable().scaledToFill())
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                            .overlay(alignment: .topTrailing) {
                                Button {
                                    fotos.remove(at: i)
                                    if i < fotoItems.count { fotoItems.remove(at: i) }
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(AppColors.darkGrey)
                                        .frame(width: 28, height: 28)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                }
                                .padding(8)
                            }
                    }
                }
            }

            if fotos.count < 3 {
                PhotosPicker(selection: $fotoItems, maxSelectionCount: 3, matching: .images) {
                    VStack(spacing: 10) {
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .regular))
                            .foregroundColor(AppColors.groen3)
                        Text(lang.t("mor_foto_knop"))
                            .font(AppFont.theSans(size: 18, weight: .semiBold))
                            .foregroundColor(AppColors.darkGrey)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .overlay(RoundedRectangle(cornerRadius: 3)
                        .stroke(AppColors.grijs2, style: StrokeStyle(lineWidth: 2, dash: [6, 4])))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var onveiligStap: some View {
        VStack(spacing: 16) {
            MORTitel(tekst: lang.t("mor_onveilig_title"))
            VStack(spacing: 8) {
                MORAntwoord(tekst: lang.t("mor_ja"), gekozen: onveilig == true) { onveilig = true }
                MORAntwoord(tekst: lang.t("mor_nee"), gekozen: onveilig == false) { onveilig = false }
            }
        }
    }

    /// Eén vraag per scherm. Je kiest één antwoord (dat wordt groen) en gaat met
    /// Volgende naar de vervolgvraag, als die er is.
    @ViewBuilder
    private var vervolgStap: some View {
        if let vraag = huidigeVraag {
            VStack(spacing: 16) {
                MORTitel(tekst: vraag.vraag)
                VStack(spacing: 8) {
                    ForEach(vraag.opties, id: \.self) { optie in
                        MORAntwoord(tekst: optie, gekozen: antwoorden[vraag.id] == optie) {
                            antwoorden[vraag.id] = optie
                        }
                    }
                }
            }
        }
    }

    private var contactStap: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                MORTitel(tekst: lang.t("mor_hoogte_title"))
                MORJaNee(keuze: $opDeHoogte)
            }
            if opDeHoogte == true {
                VStack(spacing: 32) {
                    VStack(spacing: 16) {
                        MORInvoer(label: lang.t("mor_email"), placeholder: lang.t("mor_email_placeholder"),
                                  tekst: $email, toetsenbord: .emailAddress)
                        MORInvoer(label: lang.t("mor_telefoon"), placeholder: lang.t("mor_telefoon_placeholder"),
                                  tekst: $telefoon, toetsenbord: .phonePad)
                    }
                    VStack(spacing: 16) {
                        MORTitel(tekst: lang.t("mor_contact_title"))
                        MORJaNee(keuze: $contactBijVragen)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: opDeHoogte)
    }

    private var controleStap: some View {
        VStack(spacing: 24) {
            MORTitel(tekst: lang.t("mor_controle_title"))
            MORSamenvatting(regels: [(lang.t("mor_sv_wat"), tekst), (lang.t("mor_sv_fotos"), fotoTekst)]) { bewerk(.wat) }
            MORSamenvatting(regels: [(lang.t("mor_sv_locatie"), adres ?? lang.t("melding_waar_onbekend"))]) { bewerk(.waar) }
            MORSamenvatting(regels: vragenRegels) { bewerk(heeftVervolg ? .vervolg : .onveilig) }
        }
    }

    private var fotoTekst: String {
        fotos.isEmpty ? lang.t("mor_sv_geen_fotos") : String(format: lang.t("mor_sv_n_fotos"), fotos.count)
    }

    private var vragenRegels: [(String, String)] {
        zichtbareVragen.compactMap { v in antwoorden[v.id].map { (v.vraag, $0) } }
            + [(lang.t("mor_onveilig_title"), lang.t(onveilig == true ? "mor_ja" : "mor_nee"))]
    }

    private var contactRegels: [(String, String)] {
        guard opDeHoogte == true else { return [(lang.t("mor_hoogte_title"), lang.t("mor_nee"))] }
        var r = [(lang.t("mor_hoogte_title"), lang.t("mor_graag"))]
        if !email.isEmpty { r.append((lang.t("mor_email"), email)) }
        if !telefoon.isEmpty { r.append((lang.t("mor_telefoon"), telefoon)) }
        return r
    }

    private var klaarStap: some View {
        VStack(spacing: 32) {
            MORTitel(tekst: lang.t("mor_klaar_title"))
            Image("mor-team")
                .resizable()
                .scaledToFill()
                .frame(width: 327, height: 189)
                .clipShape(RoundedRectangle(cornerRadius: 3))
            tijdlijn
        }
    }

    /// Wat er nu gebeurt (Figma Step 10): rondjes van 15, tekst ernaast verticaal
    /// gecentreerd, en een lijn die van het eerste tot het laatste rondje loopt.
    private var tijdlijn: some View {
        let regels = ["mor_tijd_1", "mor_tijd_2", "mor_tijd_3", "mor_tijd_4"]
        let hoogtes: [CGFloat] = [23, 23, 55, 59]
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(regels.enumerated()), id: \.offset) { i, key in
                HStack(alignment: .center, spacing: 12) {
                    Circle()
                        .stroke(AppColors.darkGrey, lineWidth: 2)
                        .background(Circle().fill(Color.white))
                        .frame(width: 15, height: 15)
                    Text(lang.t(key))
                        .font(MORStijl.body)
                        .foregroundColor(AppColors.darkGrey)
                        .lineSpacing(1.5)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(width: 306, alignment: .leading)
                    Spacer(minLength: 0)
                }
                .frame(minHeight: hoogtes[i])
                // Lijnstuk van dit rondje naar het volgende (over de tussenruimte heen).
                .background(alignment: .topLeading) {
                    GeometryReader { g in
                        if i < regels.count - 1 {
                            Rectangle()
                                .fill(AppColors.darkGrey)
                                .frame(width: 2, height: g.size.height / 2 + 20 + hoogtes[i + 1] / 2)
                                .offset(x: 6.5, y: g.size.height / 2)
                        }
                    }
                }
                .zIndex(Double(regels.count - i))
                .padding(.bottom, i < regels.count - 1 ? 20 : 0)
            }
        }
        .padding(.horizontal, 10)
    }

    // MARK: - Knoppen onderaan

    @ViewBuilder
    private var knoppen: some View {
        switch stap {
        case .intro:
            MORKnop(titel: lang.t("mor_intro_knop"), soort: .groen, eigenIcoon: "mor-megafoon") { volgende() }
        case .waar:
            VStack(spacing: 16) {
                if let adres {
                    HStack {
                        Text(adres)
                            .font(MORStijl.body)
                            .foregroundColor(AppColors.darkGrey)
                            .lineLimit(2)
                        Spacer()
                        Button { wisPlek() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .regular))
                                .foregroundColor(AppColors.darkGrey)
                                .frame(width: 24, height: 24)
                        }
                        .buttonStyle(.plain)
                    }
                    .transition(.opacity)
                } else {
                    HStack(spacing: 16) {
                        MORLocatieKnop(titel: lang.t("mor_mijn_locatie"), icoon: "mor-pin") { mijnLocatie() }
                        MORLocatieKnop(titel: lang.t("mor_kies_straat"), icoon: "mor-kaart") { toonStraten = true }
                    }
                    .transition(.opacity)
                }
                MORKnop(titel: lang.t("onb_next"), actief: plek != nil) { volgende() }
            }
            .animation(.easeInOut(duration: 0.2), value: adres)
        case .controle:
            MORKnop(titel: lang.t("onb_next")) { verstuur() }
        case .klaar:
            MORKnop(titel: lang.t("mor_sluiten")) { sluit() }
        default:
            MORKnop(titel: lang.t("onb_next"), actief: kanVerder) { volgende() }
        }
    }

    private func omlijnd(_ titel: String, icoon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(titel).font(MORStijl.bodyBold)
                Image(systemName: icoon).font(.system(size: 16, weight: .regular))
            }
            .foregroundColor(AppColors.darkGrey)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(AppColors.darkGrey, lineWidth: 1.5))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var kanVerder: Bool {
        switch stap {
        case .wat:      return !tekst.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .onveilig: return onveilig != nil
        case .vervolg:  return huidigeVraag.map { antwoorden[$0.id] != nil } ?? true
        case .contact:  return opDeHoogte == false || (opDeHoogte == true && contactBijVragen != nil)
        default:        return true
        }
    }

    // MARK: - Navigatie

    private func volgende() {
        tekstFocus = false
        if spraak.isListening { spraak.stopListening() }
        // Nog een vervolgvraag te gaan: die eerst, ook als je vanuit de controle komt.
        if stap == .vervolg && vraagIndex < zichtbareVragen.count - 1 {
            vraagIndex += 1
            return
        }
        if terugNaarControle && stap != .wat {
            terugNaarControle = false
            stap = .controle
            return
        }
        switch stap {
        case .intro: stap = .wat
        case .wat:
            AnalyticsService.track("melding_wat", ["categorie": categorie.rawValue, "tegel": gekozenTegel != nil])
            // Nadenk-gordijn: de app "begrijpt" je tekst.
            laden = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                laden = false
                if terugNaarControle {
                    terugNaarControle = false
                    stap = .controle
                } else {
                    stap = .waar
                }
            }
        case .waar:     stap = .foto
        case .foto:     stap = .onveilig
        case .onveilig:
            vraagIndex = 0
            stap = heeftVervolg ? .vervolg : .contact
        case .vervolg:  stap = .contact
        case .contact:  stap = .controle
        default: break
        }
    }

    private func terug() {
        tekstFocus = false
        if terugNaarControle {
            terugNaarControle = false
            stap = .controle
            return
        }
        switch stap {
        case .intro:    sluit()
        case .wat:      stap = .intro
        case .waar:     stap = .wat
        case .foto:     stap = .waar
        case .onveilig: stap = .foto
        case .vervolg:
            if vraagIndex > 0 { vraagIndex -= 1 } else { stap = .onveilig }
        case .contact:
            vraagIndex = max(0, zichtbareVragen.count - 1)
            stap = heeftVervolg ? .vervolg : .onveilig
        case .controle: stap = .contact
        case .klaar:    sluit()
        }
    }

    private func bewerk(_ naar: Stap) {
        terugNaarControle = true
        vraagIndex = 0
        stap = naar
    }

    private func sluit() {
        if spraak.isListening { spraak.stopListening() }
        isPresented = false
    }

    private func verstuur() {
        meldnummer = "SIG-\(Int.random(in: 100_000...999_999))"
        let wat = antwoorden["soort"] ?? tekst
        AnalyticsService.track("melding_verstuurd", [
            "categorie": categorie.rawValue,
            "metFoto": !fotos.isEmpty,
            "onveilig": onveilig == true,
            "opDeHoogte": opDeHoogte == true,
        ])
        onVerstuurd(wat, adres ?? "", meldnummer)
        stap = .klaar
    }

    // MARK: - Spraak

    private func wisselSpraak() {
        if spraak.isListening {
            spraak.stopListening()
        } else {
            tekstFocus = false
            spraak.requestPermission { ok in if ok { spraak.startListening() } }
        }
    }

    // MARK: - Plek

    static func regio(_ c: CLLocationCoordinate2D, span: Double) -> MKCoordinateRegion {
        MKCoordinateRegion(center: c, span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span))
    }

    private func zetPlek(_ coord: CLLocationCoordinate2D, centreer: Bool) {
        plek = coord
        adres = nil
        if centreer {
            withAnimation(.easeInOut(duration: 0.6)) { camera = .region(Self.regio(coord, span: 0.003)) }
        }
        CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: coord.latitude, longitude: coord.longitude)) { marks, _ in
            DispatchQueue.main.async {
                guard plek?.latitude == coord.latitude else { return }
                if let p = marks?.first, let straat = p.thoroughfare {
                    adres = [straat, p.subThoroughfare].compactMap { $0 }.joined(separator: " ")
                } else {
                    adres = lang.t("melding_waar_onbekend")
                }
            }
        }
    }

    private func wisPlek() {
        plek = nil
        adres = nil
        gekozenContainer = nil
    }

    /// Prototype: "mijn locatie" is het thuisadres.
    private func mijnLocatie() {
        if categorie == .container, let dichtst = MORContainer.rondThuis.first {
            gekozenContainer = dichtst.id
            zetPlek(dichtst.coordinate, centreer: true)
        } else {
            zetPlek(BuurtView.thuisCoord, centreer: true)
        }
    }

    private func kiesStraat(_ straat: String) {
        toonStraten = false
        CLGeocoder().geocodeAddressString("\(straat), Den Haag") { marks, _ in
            DispatchQueue.main.async {
                let coord = marks?.first?.location?.coordinate ?? BuurtView.thuisCoord
                gekozenContainer = nil
                zetPlek(coord, centreer: true)
            }
        }
    }

    private func laadFotos(_ items: [PhotosPickerItem]) {
        Task {
            var nieuw: [UIImage] = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self), let img = UIImage(data: data) {
                    nieuw.append(img)
                }
            }
            await MainActor.run { fotos = nieuw }
        }
    }
}

/// "Kies straat": zoekveld met straten die met je invoer beginnen (Figma Step 11–13).
struct MORStraatZoeker: View {
    @EnvironmentObject var lang: LanguageManager
    var onKies: (String) -> Void
    @State private var zoek = ""
    @FocusState private var focus: Bool

    private var resultaten: [String] {
        let z = zoek.trimmingCharacters(in: .whitespaces).lowercased()
        return z.isEmpty ? MORStraten.alle : MORStraten.alle.filter { $0.lowercased().hasPrefix(z) || $0.lowercased().contains(" " + z) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                TextField(lang.t("mor_straat_placeholder"), text: $zoek)
                    .font(MORStijl.body)
                    .focused($focus)
                    .autocorrectionDisabled()
                Image("mor-mic").resizable().frame(width: 24, height: 23)
            }
            .padding(.horizontal, 15)
            .frame(height: 62)
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(AppColors.grijs2, lineWidth: 1))

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(resultaten, id: \.self) { straat in
                        Button { onKies(straat) } label: {
                            markeer(straat)
                                .font(MORStijl.body)
                                .foregroundColor(AppColors.darkGrey)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 12)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
            }
        }
        .padding(.horizontal, 25)
        .padding(.top, 40)
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { focus = true } }
    }

    /// Het getypte deel vet, zoals in Figma ("**Aa**d Mansveldstraat").
    private func markeer(_ straat: String) -> Text {
        let z = zoek.trimmingCharacters(in: .whitespaces)
        guard !z.isEmpty, straat.lowercased().hasPrefix(z.lowercased()) else { return Text(straat) }
        return Text(String(straat.prefix(z.count))).font(MORStijl.bodyBold) + Text(String(straat.dropFirst(z.count)))
    }
}
