import SwiftUI

/// Waarvoor je spaart met de fietspas. Leeg = nog geen spaardoel gekozen.
enum Spaardoel: String {
    case geen = ""
    case koffie
    case club
}

/// Fietspas met barcode. Zelfde geel vlak en inschuif-animatie als
/// `PasDetailView` (de Ooievaarspas), maar zonder pasje: het beeldmerk van
/// Den Haag Fietst staat groot en los op het geel, daaronder de barcode op een
/// witte kaart en daaronder je spaardoel (ook los op het geel).
///
/// Prototype: tikken op de barcode speelt een scan na. Je spaardoel regel je in
/// de app zelf, of in de app van Dappre — dat hangt af van de versie van de app.
struct FietspasView: View {
    @EnvironmentObject var lang: LanguageManager
    @EnvironmentObject var versie: VersieManager
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss
    /// Naar de spaarplekken op de buurt-kaart.
    var onRedeem: () -> Void

    private static let doel = 10
    private static let barcodeNumber = "6 038432 045126"

    /// Start elke keer op 7, zodat de demo steeds hetzelfde verloopt. Loopt op
    /// tot 9: de popup vertelt dat je er bijna bent, niet dat je er bent.
    @State private var punten = 7
    @State private var scanning = false
    @State private var scanProgress: CGFloat = 0
    @State private var showPopup = false
    @State private var appearAnimation = false
    @State private var showKeuze = false
    @State private var showDappreVerwijzing = false
    @AppStorage("spaardoel") private var spaardoelRaw = ""
    /// Gekozen clubs, als één tekst met "|" ertussen (AppStorage kent geen lijsten).
    @AppStorage("dappreClubs") private var clubsRaw = ""

    /// Zonder koppeling met Dappre is er geen spaardoel.
    private var spaardoel: Spaardoel {
        koppeling == .geen ? .geen : (Spaardoel(rawValue: spaardoelRaw) ?? .geen)
    }
    private var clubs: [String] { clubsRaw.split(separator: "|").map(String.init) }
    private var koppeling: DappreKoppeling { versie.current.dappre }
    private var dappreInApp: Bool { koppeling == .api }

    var body: some View {
        ZStack {
            AppColors.geel3
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.8))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, AppDesign.horizontalPadding)
                .padding(.top, 8)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Beeldmerk groot en los op het geel, zonder kaart eromheen.
                        FietstLogo()
                            .frame(width: 150, height: 150)
                            .padding(.top, 8)
                            .opacity(appearAnimation ? 1 : 0)
                            .scaleEffect(appearAnimation ? 1 : 0.92)

                        Spacer().frame(height: 14)

                        VStack(spacing: 2) {
                            Text(lang.t("fietspas_title"))
                                .font(AppFont.theMix(size: 28, weight: .bold))
                            Text(lang.t("surname"))
                                .font(AppFont.theSans(size: 16, weight: .plain))
                        }
                        .foregroundColor(AppColors.textPrimary)
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 20)

                        Spacer().frame(height: 20)

                        barcodeCard
                            .padding(.horizontal, 20)
                            .opacity(appearAnimation ? 1 : 0)
                            .scaleEffect(appearAnimation ? 1 : 0.9)

                        Spacer().frame(height: 12)

                        Text(lang.t(scanning ? "fietspas_scanning" : "fietspas_hint"))
                            .font(AppFont.theSans(size: 14, weight: .plain))
                            .foregroundColor(AppColors.textPrimary.opacity(0.6))
                            .opacity(appearAnimation ? 1 : 0)

                        if koppeling != .geen {
                            Spacer().frame(height: 28)

                            spaardoelSectie
                                .padding(.horizontal, 20)
                                .opacity(appearAnimation ? 1 : 0)
                        }

                        Spacer().frame(height: 32)
                    }
                }
            }

            if showPopup {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .onTapGesture { showPopup = false }
                    .transition(.opacity)

                popup
                    .padding(.horizontal, 28)
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showPopup)
        .sheet(isPresented: $showKeuze) {
            SpaardoelKeuzeView(spaardoelRaw: $spaardoelRaw, clubsRaw: $clubsRaw)
                .environmentObject(lang)
        }
        .alert(lang.t("spaardoel_choose"), isPresented: $showDappreVerwijzing) {
            Button(lang.t("cancel"), role: .cancel) { }
            Button(lang.t("dappre_open")) { naarDappre() }
        } message: {
            Text(lang.t("spaardoel_dappre_msg"))
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appearAnimation = true
            }
        }
    }

    // MARK: - Barcode

    private var barcodeCard: some View {
        Button(action: scan) {
            VStack(spacing: 20) {
                BreedBarcode(number: Self.barcodeNumber)
                    .frame(height: 120)
                    .overlay(alignment: .leading) {
                        GeometryReader { geo in
                            Rectangle()
                                .fill(AppColors.rood)
                                .frame(width: 3)
                                .shadow(color: AppColors.rood.opacity(0.6), radius: 6)
                                .offset(x: geo.size.width * scanProgress)
                                .opacity(scanning ? 1 : 0)
                        }
                    }
                    .padding(.horizontal, 16)

                Text(Self.barcodeNumber)
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .foregroundColor(AppColors.textPrimary)
                    .tracking(3)
            }
            .padding(.vertical, 28)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PressableScaleStyle(scale: 0.98))
        .disabled(scanning)
    }

    // MARK: - Spaardoel

    /// Los op het geel, zonder wit venster. Tikken opent de keuze: in de app
    /// zelf, of een verwijzing naar de app van Dappre (versie Basis).
    private var spaardoelSectie: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(lang.t("spaardoel_title"))
                .font(AppFont.theMix(size: 20, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            Button(action: kiesSpaardoel) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 14) {
                        Image(systemName: spaardoelIcon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                            .frame(width: 44, height: 44)
                            .overlay(Circle().stroke(AppColors.textPrimary, lineWidth: 1.5))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(spaardoelTitel)
                                .font(AppFont.theSans(size: 18, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)
                            Text(spaardoelSub)
                                .font(AppFont.theSans(size: 16, weight: .plain))
                                .foregroundColor(AppColors.textPrimary.opacity(0.75))
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 4)

                        Image(systemName: dappreInApp ? "chevron.right" : "arrow.up.right")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                    }

                    if spaardoel == .koffie {
                        puntenRij(size: 20)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.textPrimary.opacity(spaardoel == .geen ? 0.5 : 0.9),
                                style: StrokeStyle(lineWidth: 1.5, dash: spaardoel == .geen ? [6, 5] : []))
                )
                .contentShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(PressableScaleStyle(scale: 0.98))

            if !dappreInApp {
                Text(lang.t("spaardoel_via_dappre"))
                    .font(AppFont.theSans(size: 14, weight: .plain))
                    .foregroundColor(AppColors.textPrimary.opacity(0.7))
            }
        }
    }

    private var spaardoelIcon: String {
        switch spaardoel {
        case .geen: return "plus"
        case .koffie: return "cup.and.saucer.fill"
        case .club: return "person.3.fill"
        }
    }

    private var spaardoelTitel: String {
        switch spaardoel {
        case .geen: return lang.t("spaardoel_none_title")
        case .koffie: return lang.t("spaardoel_koffie")
        case .club: return clubs.isEmpty ? lang.t("spaardoel_club") : clubs.joined(separator: ", ")
        }
    }

    private var spaardoelSub: String {
        switch spaardoel {
        case .geen: return lang.t("spaardoel_none_sub")
        case .koffie: return String(format: lang.t("spaardoel_koffie_sub"), punten, Self.doel)
        case .club:
            return clubs.isEmpty ? lang.t("dappre_no_clubs")
                : String(format: lang.t("spaardoel_club_points"), punten)
        }
    }

    private func kiesSpaardoel() {
        if dappreInApp {
            showKeuze = true
        } else {
            showDappreVerwijzing = true
        }
    }

    private func naarDappre() {
        AnalyticsService.track("open_dappre_extern")
        openURL(DappreClubs.url)
    }

    /// Tien stippen; de laatste is het kopje koffie.
    private func puntenRij(size: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(1...Self.doel, id: \.self) { i in
                ZStack {
                    Circle()
                        .fill(i <= punten ? AppColors.textPrimary : Color.clear)
                    Circle()
                        .stroke(AppColors.textPrimary, lineWidth: 1.5)
                    if i == Self.doel {
                        Image(systemName: "cup.and.saucer.fill")
                            .font(.system(size: size * 0.45))
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
                .frame(width: size, height: size)
                if i < Self.doel { Spacer(minLength: 2) }
            }
        }
    }

    // MARK: - Popup na het scannen

    /// Titel, tekst en knop hangen af van je spaardoel.
    private var popup: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(lang.t(spaardoel == .geen ? "fietspas_scanned_plain" : "fietspas_scanned_title"))
                .font(AppFont.theMix(size: 24, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            if spaardoel == .koffie {
                puntenRij(size: 20)
            }

            Group {
                switch spaardoel {
                case .geen:
                    if koppeling != .geen {
                        Text(lang.t("fietspas_scanned_none_body"))
                            .font(AppFont.theSans(size: 18, weight: .plain))
                    }
                case .koffie:
                    VStack(alignment: .leading, spacing: 6) {
                        Text(String(format: lang.t("fietspas_scanned_body"), punten, Self.doel))
                            .font(AppFont.theSans(size: 18, weight: .plain))
                        Text(String(format: lang.t("fietspas_almost"), Self.doel - punten))
                            .font(AppFont.theSans(size: 18, weight: .bold))
                    }
                case .club:
                    Text(String(format: lang.t("fietspas_scanned_club_body"), punten))
                        .font(AppFont.theSans(size: 18, weight: .plain))
                }
            }
            .foregroundColor(AppColors.textPrimary)
            .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 4) {
                if koppeling != .geen {
                Button {
                    showPopup = false
                    // Bij een verwijzing loopt alles rond sparen via de app van Dappre.
                    if spaardoel == .geen || koppeling == .link {
                        kiesSpaardoel()
                    } else {
                        AnalyticsService.track("fietspas_redeem_map")
                        onRedeem()
                    }
                } label: {
                    HStack(spacing: 10) {
                        Text(lang.t(popupKnop))
                            .font(AppFont.theSans(size: 18, weight: .bold))
                        Image(systemName: koppeling == .link ? "arrow.up.right" : "arrow.right")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppColors.groen3)
                    .clipShape(RoundedRectangle(cornerRadius: AppDesign.cornerRadius))
                }
                .buttonStyle(PressableScaleStyle())
                }

                Button { showPopup = false } label: {
                    Text(lang.t("fietspas_close"))
                        .font(AppFont.theSans(size: 16, weight: .semiBold))
                        .foregroundColor(AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 8)
    }

    private var popupKnop: String {
        if koppeling == .link { return spaardoel == .geen ? "spaardoel_choose" : "dappre_open" }
        switch spaardoel {
        case .geen: return "spaardoel_choose"
        case .koffie: return "fietspas_redeem"
        case .club: return "dappre_spend_nearby"
        }
    }

    // MARK: - Scan naspelen

    private func scan() {
        scanning = true
        scanProgress = 0
        withAnimation(.easeInOut(duration: 0.9)) { scanProgress = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            scanning = false
            // Zonder spaardoel spaar je niets.
            if spaardoel != .geen { punten = min(punten + 1, Self.doel - 1) }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            showPopup = true
            AnalyticsService.track("fietspas_scan", ["punten": punten, "spaardoel": spaardoelRaw])
        }
    }
}

/// Rond "Den Haag Fietst!"-beeldmerk, nagetekend: wit rondje met zwarte ring.
/// Schaalt mee met de ruimte die het krijgt.
private struct FietstLogo: View {
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                Circle().fill(Color.white)
                Circle().stroke(Color.black, lineWidth: max(2, s * 0.03))
                VStack(spacing: -s * 0.015) {
                    Image(systemName: "bicycle")
                        .font(.system(size: s * 0.17, weight: .semibold))
                    Text("Den Haag")
                        .font(AppFont.theMix(size: s * 0.13, weight: .bold))
                    Text("Fietst!")
                        .font(AppFont.theMix(size: s * 0.2, weight: .plain))
                }
                .foregroundColor(.black)
            }
            .frame(width: s, height: s)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

/// Barcode over de volle breedte. `BarcodeView` (de andere passen) tekent vaste
/// smalle streepjes; hier schalen ze mee, zodat de pas goed te scannen oogt.
private struct BreedBarcode: View {
    let number: String

    /// Streepbreedtes in eenheden, om en om zwart en wit; vast patroon per nummer.
    private var units: [CGFloat] {
        var seed = number.unicodeScalars.reduce(7) { $0 &* 31 &+ Int($1.value) }
        return (0..<67).map { _ in
            seed = (seed &* 1103515245 &+ 12345) & 0x7fffffff
            return CGFloat(1 + (seed >> 8) % 3)
        }
    }

    var body: some View {
        GeometryReader { geo in
            let units = units
            let unit = geo.size.width / units.reduce(0, +)
            HStack(spacing: 0) {
                ForEach(units.indices, id: \.self) { i in
                    Rectangle()
                        .fill(i % 2 == 0 ? Color.black : Color.clear)
                        .frame(width: units[i] * unit)
                }
            }
        }
    }
}
