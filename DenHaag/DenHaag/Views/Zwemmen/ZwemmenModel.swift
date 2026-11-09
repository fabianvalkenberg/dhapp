import SwiftUI

// MARK: - Navigatie binnen de mini-app Zwemmen

enum ZwRoute: Hashable {
    case kopen
    case activiteit(ZwActiviteit, dag: Int)
    case zwembad(String)
    case zwembaden
    case kaartjes
    case les
    case wachttijden
    case aanmelden
    case kind(String)
    case voortgang(String)
    case abonnement(String)

    var analyticsNaam: String {
        switch self {
        case .kopen: return "kopen"
        case .activiteit: return "activiteit"
        case .zwembad: return "zwembad"
        case .zwembaden: return "zwembaden"
        case .kaartjes: return "kaartjes"
        case .les: return "les"
        case .wachttijden: return "wachttijden"
        case .aanmelden: return "aanmelden"
        case .kind: return "kind"
        case .voortgang: return "voortgang"
        case .abonnement: return "abonnement"
        }
    }
}

/// Wat er op het volledige QR-scherm staat.
struct ZwQR: Identifiable {
    let id = UUID()
    let status: String
    let toonVinkje: Bool
    let titel: String
    let regels: [String]
    let code: String
}

// MARK: - Model

/// Staat van de mini-app Zwemmen. Favoriet zwembad, reservering, melding en kinderen
/// blijven bewaard tussen sessies; de rest leeft zolang het scherm open is.
final class ZwemmenModel: ObservableObject {
    @Published var pad: [ZwRoute] = []
    @Published var qr: ZwQR?

    @Published var mijnZwembad: String? { didSet { bewaar() } }
    @Published var reservering: ZwReservering? { didSet { bewaar() } }
    @Published var meldingZichtbaar: Bool { didSet { bewaar() } }
    @Published var kinderen: [ZwKind] { didSet { bewaar() } }

    // Kaartje kopen
    @Published var dag = 0
    @Published var filters = ZwFilters()

    // Zwemles
    @Published var aanmelding: ZwAanmelding?
    /// Bevestiging die één keer bovenaan het volgende scherm staat.
    @Published var bevestiging: String?

    private static let sleutel = "zwemmen_staat_v1"

    private struct Opslag: Codable {
        var mijnZwembad: String?
        var reservering: ZwReservering?
        var meldingZichtbaar: Bool
        var kinderen: [ZwKind]
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.sleutel),
           let o = try? JSONDecoder().decode(Opslag.self, from: data) {
            mijnZwembad = o.mijnZwembad
            reservering = o.reservering
            meldingZichtbaar = o.meldingZichtbaar
            kinderen = o.kinderen
        } else {
            mijnZwembad = "De Blinkerd"
            reservering = nil
            meldingZichtbaar = true
            kinderen = ZwData.voorbeeldKinderen
        }
        if reservering?.isGeldig == false { reservering = nil }
        #if DEBUG
        startTestharnas()
        #endif
    }

    #if DEBUG
    /// Testharnas voor screenshots: `-zwReset` zet de beginstand terug, `-zwReservering` koopt
    /// het Aquajoggen van morgen, `-zwPad kopen,les,kind:noor` opent die schermen op volgorde.
    private func startTestharnas() {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-zwReset") { reset() }
        if args.contains("-zwReservering"), let a = ZwData.rooster(1).first(where: { $0.naam == "Aquajoggen" }) {
            reservering = ZwReservering(activiteit: a, datum: ZwData.dag(1))
        }
        if let i = args.firstIndex(of: "-zwPad"), i + 1 < args.count {
            pad = args[i + 1].split(separator: ",").compactMap { deel in
                let p = deel.split(separator: ":", maxSplits: 1).map(String.init)
                let arg = p.count > 1 ? p[1] : ""
                switch p[0] {
                case "kopen": return .kopen
                case "activiteit":
                    let lijst = ZwData.rooster(0)
                    return .activiteit(lijst.first { $0.naam.hasPrefix(arg) } ?? lijst[0], dag: 0)
                case "zwembad": return .zwembad(arg.isEmpty ? "De Blinkerd" : arg)
                case "zwembaden": return .zwembaden
                case "kaartjes": return .kaartjes
                case "les": return .les
                case "wachttijden": return .wachttijden
                case "aanmelden": return .aanmelden
                case "kind": return .kind(arg)
                case "voortgang": return .voortgang(arg)
                case "abonnement": return .abonnement(arg)
                default: return nil
                }
            }
        }
    }
    #endif

    private func bewaar() {
        let o = Opslag(mijnZwembad: mijnZwembad, reservering: reservering, meldingZichtbaar: meldingZichtbaar, kinderen: kinderen)
        if let data = try? JSONEncoder().encode(o) { UserDefaults.standard.set(data, forKey: Self.sleutel) }
    }

    // MARK: Navigatie

    func push(_ r: ZwRoute) {
        AnalyticsService.screen("zwemmen_\(r.analyticsNaam)")
        pad.append(r)
    }

    func terug() { if !pad.isEmpty { pad.removeLast() } }

    func naarHome() { pad.removeAll() }

    /// Terug naar het zwemles-overzicht (na het aanmelden).
    func naarLes() {
        if let i = pad.lastIndex(of: .les) { pad = Array(pad.prefix(i + 1)) } else { pad = [.les] }
    }

    /// Kaartje kopen openen, eventueel met een filter vooraf.
    func openKopen(filters f: ZwFilters = ZwFilters(), dag d: Int = 0) {
        filters = f
        dag = d
        push(.kopen)
    }

    /// "Alle activiteiten" van één zwembad: vandaag als er nog iets komt, anders de eerstvolgende dag.
    func openAlleActiviteiten(_ zwembad: String) {
        let nogVandaag = ZwData.rooster(0, zwembad: zwembad).contains { $0.eindMin > ZwData.nuMinuten }
        openKopen(filters: ZwFilters(zwembaden: [zwembad]), dag: nogVandaag ? 0 : (ZwData.volgendeDag(zwembad: zwembad) ?? 0))
    }

    func koop(_ a: ZwActiviteit, dag d: Int) {
        reservering = ZwReservering(activiteit: a, datum: ZwData.dag(d))
        AnalyticsService.track("zwemmen_kaartje_gekocht", ["activiteit": a.naam, "zwembad": a.zwembad])
        naarHome()
    }

    func kind(_ id: String) -> ZwKind? { kinderen.first { $0.id == id } }

    func wijzig(_ id: String, _ f: (inout ZwKind) -> Void) {
        guard let i = kinderen.firstIndex(where: { $0.id == id }) else { return }
        f(&kinderen[i])
    }

    /// Zet het prototype terug naar de beginstand.
    func reset() {
        mijnZwembad = "De Blinkerd"
        reservering = nil
        meldingZichtbaar = true
        kinderen = ZwData.voorbeeldKinderen
        pad = []
    }
}

// MARK: - Datumnotatie per taal

struct ZwFormat {
    let taal: AppLanguage

    private var locale: Locale {
        switch taal {
        case .nl: return Locale(identifier: "nl_NL")
        case .en: return Locale(identifier: "en_GB")
        case .tr: return Locale(identifier: "tr_TR")
        }
    }

    private func f(_ patroon: String, _ d: Date) -> String {
        let df = DateFormatter()
        df.locale = locale
        df.setLocalizedDateFormatFromTemplate(patroon)
        return df.string(from: d)
    }

    private func vast(_ formaat: String, _ d: Date) -> String {
        let df = DateFormatter()
        df.locale = locale
        df.dateFormat = formaat
        return df.string(from: d)
    }

    /// "do" · "Th" · "Per"
    func weekdagKort(_ d: Date) -> String {
        let s = vast("EEE", d).replacingOccurrences(of: ".", with: "")
        return taal == .en ? String(s.prefix(2)) : s
    }
    /// "okt" · "Oct" · "Eki"
    func maandKort(_ d: Date) -> String { vast("MMM", d).replacingOccurrences(of: ".", with: "") }
    /// "15"
    func dagNummer(_ d: Date) -> String { vast("d", d) }
    /// "15 oktober"
    func dagMaand(_ d: Date) -> String { f("dMMMM", d) }
    /// "15 oktober 2026"
    func volledig(_ d: Date) -> String { f("dMMMMyyyy", d) }
    /// "maart 2027"
    func maandJaar(_ d: Date) -> String { f("MMMMyyyy", d) }
    /// "oktober"
    func maand(_ d: Date) -> String { vast("LLLL", d) }
    /// "Zaterdag 17 oktober"
    func weekdagDagMaand(_ d: Date) -> String { f("EEEEdMMMM", d).capitalizedFirst }
    /// "do 15 okt"
    func kortDatum(_ d: Date) -> String { "\(weekdagKort(d)) \(dagNummer(d)) \(maandKort(d))" }
}

extension String {
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}

extension LanguageManager {
    var zw: ZwFormat { ZwFormat(taal: current) }

    /// Vertaling met invulwaarden: `lang.t("zw_x", naam)`.
    func t(_ key: String, _ args: CVarArg...) -> String {
        String(format: t(key), arguments: args)
    }

    /// "Vandaag", "Morgen" of "Zaterdag 17 oktober".
    func zwDagLabel(_ offset: Int) -> String {
        if offset == 0 { return t("zw_today") }
        if offset == 1 { return t("zw_tomorrow") }
        return zw.weekdagDagMaand(ZwData.dag(offset))
    }

    /// "vandaag", "morgen" of "za 17 okt", voor gebruik midden in een zin.
    func zwDagKort(_ datum: Date) -> String {
        let d = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: datum)).day ?? 0
        if d == 0 { return t("zw_today").lowercased() }
        if d == 1 { return t("zw_tomorrow").lowercased() }
        return zw.kortDatum(datum)
    }
}
