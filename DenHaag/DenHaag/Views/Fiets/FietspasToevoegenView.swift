import SwiftUI
import AVFoundation

/// Een fietspas toevoegen (Figma fietsen, flow 02, schermen 4 t/m 6).
/// Scannen is de hoofdroute, de code typen kan altijd. Prototype: de camera-
/// toestemming is echt (iOS), het scannen zelf is nagebootst.
///
/// Testcodes voor foutschermen (staan ook in DECISIONS.md):
/// - een code die al in de app staat → "Deze pas staat al in je app"
/// - XYZ9B9B → "Deze pas is geblokkeerd"
/// - XYZ9A9A → "Deze pas staat al in een andere app"
/// - een code met O, 0, I of 1, of niet 7 tekens → "We vinden geen pas met deze code"
/// - de zoeker lang ingedrukt houden → "Dit is geen fietspas"
struct FietspasToevoegenView: View {
    @EnvironmentObject var lang: LanguageManager
    @Environment(\.openURL) private var openURL
    @ObservedObject var store: FietspasStore
    /// Begin bij het intypen van de code in plaats van bij de camera.
    var beginMetCode = false
    var onSluit: () -> Void
    /// Na "Klaar": de pas staat in de app.
    var onToegevoegd: (Fietspas) -> Void
    /// "Deze pas staat al in je app" → naar die pas.
    var onNaarPas: (Fietspas) -> Void

    enum Stap: Equatable {
        case uitleg, scan, geenCamera, code, geenFietspas
        case bevestig(Fietspas), alInApp(Fietspas), geblokkeerd, anderAccount
        case toegevoegd(Fietspas)
    }

    @State private var stap: Stap = .scan
    @State private var code = ""
    @State private var codeFout = false
    @State private var bijnaam = ""
    @FocusState private var codeFocus: Bool

    private static let geblokkeerdCode = "XYZ9B9B"
    private static let anderAccountCode = "XYZ9A9A"

    private var donker: Bool { stap == .scan || stap == .geenCamera || stap == .geenFietspas }

    var body: some View {
        ZStack {
            (donker ? Color(hex: "1F1F1F") : Color.white).ignoresSafeArea()
            inhoud
                .id(stapID)
                .transition(.opacity)
        }
        .animation(.easeInOut(duration: 0.25), value: stap)
        .preferredColorScheme(donker ? .dark : .light)
        .onAppear(perform: begin)
    }

    private var stapID: String {
        switch stap {
        case .uitleg: return "uitleg"
        case .scan: return "scan"
        case .geenCamera: return "geenCamera"
        case .code: return "code"
        case .geenFietspas: return "geenFietspas"
        case .bevestig: return "bevestig"
        case .alInApp: return "alInApp"
        case .geblokkeerd: return "geblokkeerd"
        case .anderAccount: return "anderAccount"
        case .toegevoegd: return "toegevoegd"
        }
    }

    @ViewBuilder private var inhoud: some View {
        switch stap {
        case .uitleg:
            FpStatusScherm(titel: lang.t("fp2_scan_titel"), icoon: "camera",
                           kop: lang.t("fp2_uitleg_kop"), tekst: lang.t("fp2_uitleg_tekst"),
                           knop: lang.t("fp2_doorgaan"), link: lang.t("fp2_code_intypen"),
                           onSluit: onSluit, onKnop: vraagCamera, onLink: { naar(.code) })
        case .scan:
            scanner
        case .geenCamera:
            FpStatusScherm(titel: lang.t("fp2_scan_titel"), icoon: "video.slash",
                           kop: lang.t("fp2_geencamera_kop"), tekst: lang.t("fp2_geencamera_tekst"),
                           knop: lang.t("fp2_code_intypen"), link: lang.t("fp2_camera_instellingen"),
                           donker: true, onSluit: onSluit, onKnop: { naar(.code) },
                           onLink: {
                               if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                           })
        case .geenFietspas:
            FpStatusScherm(titel: lang.t("fp2_scan_titel"), icoon: "qrcode.viewfinder",
                           kop: lang.t("fp2_geenpas_kop"), tekst: lang.t("fp2_geenpas_tekst"),
                           knop: lang.t("fp2_opnieuw_scannen"), link: lang.t("fp2_code_intypen"),
                           donker: true, onSluit: onSluit, onKnop: { naar(.scan) }, onLink: { naar(.code) })
        case .code:
            codeScherm
        case .bevestig(let pas):
            bevestigScherm(pas)
        case .alInApp(let pas):
            FpStatusScherm(titel: lang.t("fp2_toevoegen_titel"), icoon: "checkmark",
                           kop: lang.t("fp2_alinapp_kop"),
                           tekst: String(format: lang.t("fp2_alinapp_tekst"), pas.code),
                           knop: lang.t("fp2_naar_pas"), link: lang.t("fp2_andere_pas"),
                           onSluit: onSluit, onKnop: { onNaarPas(pas) }, onLink: { naar(.scan) })
        case .geblokkeerd:
            FpStatusScherm(titel: lang.t("fp2_toevoegen_titel"), icoon: "lock",
                           kop: lang.t("fp2_geblokkeerd_kop"), tekst: lang.t("fp2_geblokkeerd_tekst"),
                           knop: lang.t("fp2_contact"), link: lang.t("fp2_andere_pas"),
                           onSluit: onSluit, onKnop: contact, onLink: { naar(.scan) })
        case .anderAccount:
            FpStatusScherm(titel: lang.t("fp2_toevoegen_titel"), icoon: "person.2",
                           kop: lang.t("fp2_ander_kop"), tekst: lang.t("fp2_ander_tekst"),
                           knop: lang.t("fp2_contact"), link: lang.t("fp2_andere_pas"),
                           onSluit: onSluit, onKnop: contact, onLink: { naar(.scan) })
        case .toegevoegd(let pas):
            toegevoegdScherm(pas)
        }
    }

    // MARK: Begin en camera

    private func begin() {
        AnalyticsService.screen("fietspas_toevoegen")
        if beginMetCode { stap = .code; return }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined: stap = .uitleg
        case .authorized: stap = .scan
        default: stap = .geenCamera
        }
    }

    /// 4a → de echte vraag van iOS.
    private func vraagCamera() {
        AVCaptureDevice.requestAccess(for: .video) { ok in
            DispatchQueue.main.async { naar(ok ? .scan : .geenCamera) }
        }
    }

    private func naar(_ s: Stap) {
        if s == .code { codeFout = false }
        // Nieuwe poging (opnieuw scannen, andere pas): het codeveld weer leeg.
        // Na een foutmelding blijft wat je typte wél staan (Figma 4d).
        if s == .scan || s == .uitleg { code = "" }
        stap = s
        AnalyticsService.track("fietspas_stap", ["stap": stapID])
    }

    private func contact() {
        // Biesieklette beheert de stallingen en de passen.
        if let url = URL(string: "https://www.biesieklette.nl/fiets-stallen") { openURL(url) }
    }

    // MARK: 4 · Scannen (nagebootst)

    @State private var lijn: CGFloat = 0
    @State private var gescand = false
    @State private var scanTaak: DispatchWorkItem?

    private var scanner: some View {
        let zoeker: CGFloat = 250
        return VStack(spacing: 0) {
            FpKop(titel: lang.t("fp2_scan_titel"), donker: true, onSluit: onSluit)
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 22).fill(Color.white.opacity(0.08))
                    .padding(14)
                FpZoekerHoeken()
                    .stroke(gescand ? AppColors.groen3 : .white, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                if gescand {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(AppColors.groen3)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Capsule().fill(Color.white.opacity(0.7))
                        .frame(width: zoeker - 60, height: 2)
                        .offset(y: lijn)
                }
            }
            .frame(width: zoeker, height: zoeker)
            .contentShape(Rectangle())
            .onTapGesture { vind() }
            // Voor wie een test begeleidt: lang indrukken = een andere QR-code.
            .onLongPressGesture(minimumDuration: 0.8) {
                scanTaak?.cancel()
                naar(.geenFietspas)
            }
            Text(lang.t("fp2_scan_hint"))
                .font(AppFont.theSans(size: 17, weight: .plain))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 28)
            Spacer()
            FpOnderknoppen(knop: lang.t("fp2_code_intypen"), knopWit: true, link: nil,
                           donker: true, onKnop: { scanTaak?.cancel(); naar(.code) }, onLink: {})
        }
        .onAppear {
            gescand = false
            lijn = -(zoeker / 2 - 34)
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) { lijn = zoeker / 2 - 34 }
            let werk = DispatchWorkItem { vind() }
            scanTaak = werk
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.6, execute: werk)
        }
        .onDisappear { scanTaak?.cancel() }
    }

    private func vind() {
        guard !gescand else { return }
        scanTaak?.cancel()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { gescand = true }
        let pas = store.volgendeScan()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { controleer(pas) }
    }

    private func controleer(_ pas: Fietspas) {
        if let al = store.passen.first(where: { $0.code == pas.code }) { naar(.alInApp(al)); return }
        if pas.code == Self.geblokkeerdCode { naar(.geblokkeerd); return }
        if pas.code == Self.anderAccountCode { naar(.anderAccount); return }
        naar(.bevestig(pas))
    }

    // MARK: 4c/4d · Code intypen

    private var voorbeeldPas: Fietspas { Fietspas(type: .fiets, code: "ABC8D6E", bijnaam: "") }

    private var codeScherm: some View {
        VStack(spacing: 0) {
            FpKop(titel: lang.t("fp2_code_titel"), onSluit: onSluit)
            ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Met het toetsenbord open krimpt de voorbeeldpas, zodat het veld in beeld blijft.
                    FietspasKaartView(pas: voorbeeldPas, schaal: codeFocus ? 0.36 : 0.62)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                        .animation(.easeInOut(duration: 0.25), value: codeFocus)
                    Text(lang.t("fp2_code_titel"))
                        .font(AppFont.theSans(size: 17, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.top, 24)
                    Text(lang.t("fp2_code_uitleg"))
                        .font(AppFont.theSans(size: 15, weight: .plain))
                        .foregroundColor(Color(hex: "666666"))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 4)
                    TextField("ABC8D6E", text: $code)
                        .font(AppFont.theSans(size: 17, weight: .plain))
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .focused($codeFocus)
                        .submitLabel(.search)
                        .onSubmit(zoek)
                        // Hoofdletters maakt de app er bij het zoeken zelf van; hier niet
                        // tijdens het typen omzetten (dat onderbreekt de invoer).
                        .onChange(of: code) { oud, nieuw in
                            // Alleen bij echt andere invoer de fout wissen, niet bij het
                            // omzetten naar hoofdletters door "Pas zoeken".
                            if oud.uppercased() != nieuw.uppercased() { codeFout = false }
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 52)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(codeFout ? AppColors.rood : (codeFocus ? AppColors.groen3 : AppColors.grijs2),
                                        lineWidth: codeFout || codeFocus ? 1.5 : 1)
                        )
                        .padding(.top, 14)
                    if codeFout {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(AppColors.rood)
                            Text(lang.t("fp2_code_onbekend"))
                                .font(AppFont.theSans(size: 15, weight: .bold))
                                .foregroundColor(AppColors.rood)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.top, 10)
                    }
                }
                .padding(.horizontal, AppDesign.horizontalPadding)
                // Ruimte onder het veld, zodat de rand en de foutmelding niet tegen de knoppen vallen.
                .padding(.bottom, 20)
                Color.clear.frame(height: 1).id("onder")
            }
            // Met het toetsenbord open: het veld (en een eventuele fout) in beeld schuiven.
            .onChange(of: codeFocus) { _, aan in
                guard aan else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    withAnimation { proxy.scrollTo("onder", anchor: .bottom) }
                }
            }
            .onChange(of: codeFout) { _, fout in
                guard fout else { return }
                withAnimation { proxy.scrollTo("onder", anchor: .bottom) }
            }
            }
            FpOnderknoppen(knop: lang.t("fp2_pas_zoeken"), link: lang.t("fp2_toch_scannen"),
                           onKnop: zoek, onLink: { codeFocus = false; begin2Scan() })
        }
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { codeFocus = true } }
    }

    private func begin2Scan() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined: naar(.uitleg)
        case .authorized: naar(.scan)
        default: naar(.geenCamera)
        }
    }

    /// Hoofdletters en spaties maken niet uit. Haagse passen gebruiken geen O, 0,
    /// I of 1 (die lijken op elkaar); zo'n code bestaat dus niet.
    private func zoek() {
        let schoon = code.uppercased().filter { !$0.isWhitespace }
        code = schoon
        let geldig = schoon.count == 7 && schoon.allSatisfy { $0.isLetter || $0.isNumber }
            && !schoon.contains(where: { "O0I1".contains($0) })
        if let al = store.passen.first(where: { $0.code == schoon }) { codeFocus = false; naar(.alInApp(al)); return }
        if schoon == Self.geblokkeerdCode { codeFocus = false; naar(.geblokkeerd); return }
        if schoon == Self.anderAccountCode { codeFocus = false; naar(.anderAccount); return }
        guard geldig else {
            withAnimation(.easeInOut(duration: 0.2)) { codeFout = true }
            AnalyticsService.track("fietspas_code_onbekend")
            return
        }
        codeFocus = false
        let type = store.volgendeScan().type
        naar(.bevestig(Fietspas(type: type, code: schoon, bijnaam: "")))
    }

    // MARK: 5 · Is dit je pas?

    private func bevestigScherm(_ pas: Fietspas) -> some View {
        VStack(spacing: 0) {
            FpKop(titel: lang.t("fp2_bevestig_titel"), onSluit: onSluit)
            Spacer(minLength: 8)
            FietspasKaartView(pas: pas, schaal: 0.82)
            Text(String(format: lang.t("fp2_bevestig_tekst"), lang.t(pas.type.kleurBijvoeglijkKey), pas.code))
                .font(AppFont.theSans(size: 17, weight: .plain))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 32)
                .padding(.top, 24)
            Spacer()
            FpOnderknoppen(knop: lang.t("fp2_ja_toevoegen"), link: lang.t("fp2_nee_opnieuw"),
                           onKnop: {
                               bijnaam = pas.type.standaardBijnaam(lang)
                               naar(.toegevoegd(pas))
                           },
                           onLink: { naar(.scan) })
        }
    }

    // MARK: 6 · Pas toegevoegd

    @FocusState private var naamFocus: Bool

    private func toegevoegdScherm(_ pas: Fietspas) -> some View {
        VStack(spacing: 0) {
            FpKop(titel: lang.t("fp2_toegevoegd_titel"), onSluit: { klaar(pas) })
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    FietspasKaartView(pas: pas, schaal: 0.62)
                        .overlay(alignment: .topTrailing) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(AppColors.groen3)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 3))
                                .offset(x: 16, y: -14)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                    Text(lang.t("fp2_naam_kop"))
                        .font(AppFont.theSans(size: 17, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.top, 24)
                    Text(lang.t("fp2_naam_uitleg"))
                        .font(AppFont.theSans(size: 15, weight: .plain))
                        .foregroundColor(Color(hex: "666666"))
                        .padding(.top, 4)
                    HStack {
                        TextField(pas.type.standaardBijnaam(lang), text: $bijnaam)
                            .font(AppFont.theSans(size: 17, weight: .plain))
                            .focused($naamFocus)
                            .submitLabel(.done)
                        Image(systemName: "pencil")
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 52)
                    .overlay(RoundedRectangle(cornerRadius: 4)
                        .stroke(naamFocus ? AppColors.groen3 : AppColors.grijs2, lineWidth: naamFocus ? 1.5 : 1))
                    .padding(.top, 14)
                }
                .padding(.horizontal, AppDesign.horizontalPadding)
            }
            VStack(spacing: 0) {
                Divider()
                VStack(spacing: 8) {
                    FpWalletKnop(inWallet: store.inWallet(pas.code)) {
                        store.zetInWallet(pas.code, true)
                        AnalyticsService.track("fietspas_wallet", ["bron": "toegevoegd"])
                    }
                    Button { klaar(pas) } label: {
                        Text(lang.t("fp2_klaar"))
                            .font(AppFont.theSans(size: 16, weight: .bold))
                            .foregroundColor(AppColors.blauw3)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, AppDesign.horizontalPadding)
                .padding(.top, 16)
                .padding(.bottom, 8)
            }
        }
    }

    private func klaar(_ pas: Fietspas) {
        var nieuw = pas
        let naam = bijnaam.trimmingCharacters(in: .whitespacesAndNewlines)
        nieuw.bijnaam = naam == pas.type.standaardBijnaam(lang) ? "" : naam
        onToegevoegd(nieuw)
    }
}

// MARK: - Bouwstenen (Figma flow 02)

/// Kop: titel links (28 vet), rond sluitknopje rechts.
struct FpKop: View {
    let titel: String
    var donker = false
    var terug = false
    let onSluit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if terug { knop(icoon: "arrow.left") }
            Text(titel)
                .font(AppFont.theMix(size: 28, weight: .bold))
                .foregroundColor(donker ? .white : AppColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer()
            if !terug { knop(icoon: "xmark") }
        }
        .padding(.horizontal, AppDesign.horizontalPadding)
        .padding(.top, AppDesign.terugknopTop)
        .padding(.bottom, 12)
    }

    private func knop(icoon: String) -> some View {
        Button(action: onSluit) {
            Image(systemName: icoon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(donker ? .white : (terug ? AppColors.blauw3 : AppColors.textPrimary))
                .frame(width: BackCircleButton.maat, height: BackCircleButton.maat)
                .background(donker ? Color.white.opacity(0.15) : Color(hex: "F2F2F1"))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

/// Onderin: grote knop (groen, of wit op donker) met eronder een blauwe link met pijl.
struct FpOnderknoppen: View {
    let knop: String
    var knopWit = false
    let link: String?
    var donker = false
    let onKnop: () -> Void
    let onLink: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            Button(action: onKnop) {
                Text(knop)
                    .font(AppFont.theSans(size: 17, weight: .bold))
                    .foregroundColor(knopWit ? AppColors.textPrimary : .white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(knopWit ? Color.white : AppColors.groen3)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .buttonStyle(.plain)
            if let link {
                Button(action: onLink) {
                    HStack(spacing: 8) {
                        Text(link).font(AppFont.theSans(size: 16, weight: .bold))
                        Image(systemName: "arrow.right").font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(donker ? .white : AppColors.blauw3)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppDesign.horizontalPadding)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
}

/// Statusscherm: icoon in een rondje, kop, uitleg, knop en link (Figma 4a, 4b, 4e, 5b–5d).
struct FpStatusScherm: View {
    let titel: String
    let icoon: String
    let kop: String
    let tekst: String
    let knop: String
    let link: String?
    var donker = false
    let onSluit: () -> Void
    let onKnop: () -> Void
    let onLink: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            FpKop(titel: titel, donker: donker, onSluit: onSluit)
            Spacer()
            Image(systemName: icoon)
                .font(.system(size: 30, weight: .regular))
                .foregroundColor(donker ? .white : AppColors.textPrimary)
                .frame(width: 112, height: 112)
                .background(donker ? Color.white.opacity(0.12) : Color(hex: "EDEBE6"))
                .clipShape(donker ? AnyShape(RoundedRectangle(cornerRadius: 22)) : AnyShape(Circle()))
            Text(kop)
                .font(AppFont.theMix(size: 22, weight: .bold))
                .foregroundColor(donker ? .white : AppColors.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.top, 24)
                .padding(.horizontal, 32)
            Text(tekst)
                .font(AppFont.theSans(size: 17, weight: .plain))
                .foregroundColor(donker ? .white.opacity(0.8) : AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)
                .padding(.horizontal, 32)
            Spacer()
            Spacer()
            FpOnderknoppen(knop: knop, knopWit: donker, link: link, donker: donker, onKnop: onKnop, onLink: onLink)
        }
    }
}

/// Zwarte "Voeg toe aan Apple Wallet"-knop. Prototype: nagebootst.
struct FpWalletKnop: View {
    @EnvironmentObject var lang: LanguageManager
    let inWallet: Bool
    let actie: () -> Void

    var body: some View {
        Button(action: actie) {
            HStack(spacing: 10) {
                Image(systemName: inWallet ? "checkmark" : "wallet.pass.fill")
                    .font(.system(size: 18, weight: .semibold))
                Text(lang.t(inWallet ? "fp2_in_wallet" : "fp2_naar_wallet"))
                    .font(.system(size: 18, weight: .medium))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        // Niet .disabled: dat maakt hem grijs; zwart met vinkje leest als "gelukt".
        .allowsHitTesting(!inWallet)
    }
}

/// Vier hoeken van een zoeker.
struct FpZoekerHoeken: Shape {
    func path(in rect: CGRect) -> Path {
        let l: CGFloat = 40, r: CGFloat = 18
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY + l))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        p.addQuadCurve(to: CGPoint(x: rect.minX + r, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX + l, y: rect.minY))
        p.move(to: CGPoint(x: rect.maxX - l, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + r), control: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + l))
        p.move(to: CGPoint(x: rect.maxX, y: rect.maxY - l))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        p.addQuadCurve(to: CGPoint(x: rect.maxX - r, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX - l, y: rect.maxY))
        p.move(to: CGPoint(x: rect.minX + l, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - r), control: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - l))
        return p
    }
}
