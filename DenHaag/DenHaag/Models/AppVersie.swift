import SwiftUI

/// Welke versie van de app je bekijkt. Bedoeld voor demo's en tests: dezelfde
/// app, in stappen van wat er als eerste live gaat naar wat erna komt. Wat een
/// versie wel en niet toont, staat alleen in dit bestand.
enum AppVersie: String, CaseIterable, Identifiable {
    case v1, v2, v3
    /// Voor het testen met inwoners: een eigen selectie, geen opvolger van v3.
    case test

    var id: String { rawValue }

    var titleKey: String { "versie_\(rawValue)_title" }

    /// Versienummer, voor "Alles uit versie 1, plus:".
    var nummer: Int { (AppVersie.allCases.firstIndex(of: self) ?? 0) + 1 }

    /// De versie waar deze op voortbouwt; nil voor versie 1 en de testversie.
    var vorige: AppVersie? {
        switch self {
        case .v1, .test: return nil
        case .v2: return .v1
        case .v3: return .v2
        }
    }

    /// Wat deze versie toevoegt aan de vorige, in vaste volgorde.
    var nieuweOnderdelen: [Onderdeel] {
        Onderdeel.allCases.filter { heeft($0) && !(vorige?.heeft($0) ?? false) }
    }

    /// Onderdelen in deze versie. Elke versie bouwt voort op de vorige.
    /// Berichten (het belletje) staat voorlopig in geen enkele versie.
    var onderdelen: Set<Onderdeel> {
        switch self {
        case .v1: return [.melden, .fietsen]
        case .v2: return AppVersie.v1.onderdelen.union([.voorJou, .afval, .parkeren, .zwemmen, .afspraken, .personalisatie])
        case .v3: return Set(Onderdeel.allCases).subtracting([.notificaties])
        // Testversie: ook de gevulde buurtkaart (werk aan de weg, meedenken, buurtleven).
        case .test: return [.melden, .fietsen, .parkeren, .zwemmen, .afspraken, .voorJou, .personalisatie, .regelen, .buurtLeven, .participatie]
        }
    }

    func heeft(_ onderdeel: Onderdeel) -> Bool { onderdelen.contains(onderdeel) }

    // MARK: - Wat zit erin

    /// Tabs in de onderbalk, in volgorde. Regelen komt pas in versie 3.
    var tabs: [MainTabView.Tab] {
        var t: [MainTabView.Tab] = [.home]
        if heeft(.regelen) { t.append(.regelen) }
        // Zonder iets op de kaart geen buurt-tab.
        if heeft(.fietsen) || heeft(.buurtLeven) { t.append(.buurt) }
        t.append(.hulp)
        return t
    }

    /// Vaste tegels op het startscherm, in deze volgorde. Een tegel die hier
    /// niet staat, komt in deze versie nooit op het startscherm.
    var tegels: [String] {
        switch self {
        case .v1:   return ["overlast", "fietsparkeren", "fietspas"]
        case .v2:   return AppVersie.v1.tegels + ["parkeerbezoek", "afspraak", "afvalkalender", "afval", "grofvuil", "zwemmen"]
        case .v3:   return AppVersie.v2.tegels + ["ooievaarspas", "rechten", "bieb"]
        case .test: return ["overlast", "fietsparkeren", "fietspas", "parkeerbezoek", "afspraak", "zwemmen"]
        }
    }

    /// Versie 2 en de testversie vragen bij élk openen eerst je naam, zodat
    /// elke nieuwe deelnemer bij het naamscherm begint.
    var vraagtNaam: Bool { self == .v2 || self == .test }

    /// Een home-tegel bestaat alleen als het scherm erachter in deze versie zit.
    func allowsTile(_ id: String) -> Bool {
        guard let onderdeel = Self.tegelOnderdeel[id] else { return heeft(.regelingen) }
        return heeft(onderdeel)
    }

    /// Onderwerpen op de buurt-kaart.
    func allowsBuurtTopic(_ topic: String) -> Bool {
        switch topic {
        case "fietsparkeren": return heeft(.fietsen)
        case "participatie":  return heeft(.participatie)
        // Ondernemersinfo staat in elke versie met een buurtkaart; de rol bepaalt of je hem ziet.
        case "ondernemen":    return true
        // Koffieplekken hoorden bij sparen met Dappre; dat zit in geen enkele versie.
        case "koffie":        return false
        default:              return heeft(.buurtLeven)
        }
    }

    /// Sparen met Dappre is uit het prototype gehaald. De code blijft staan,
    /// zodat het terug kan; elke versie heeft "geen koppeling".
    var dappre: DappreKoppeling { .geen }

    /// Uitlegvideo's in een onderwerpscherm (nu bij kwijtschelding).
    var showsVideos: Bool { heeft(.video) }

    /// Welk onderdeel een home-tegel nodig heeft. Een tegel die hier niet
    /// staat, hoort bij de regelingen en informatie (versie 3).
    private static let tegelOnderdeel: [String: Onderdeel] = [
        "overlast": .melden,
        "fietsparkeren": .fietsen, "fietspas": .fietsen,
        "parkeerbezoek": .parkeren,
        "afspraak": .afspraken,
        "afval": .afval, "afvalkalender": .afval, "grofvuil": .afval,
        "zwemmen": .zwemmen,
        "mijnbuurt": .buurtLeven,
        "buurt_evenementen": .buurtLeven, "buurt_sport": .buurtLeven,
        "buurt_wegwerk": .buurtLeven, "buurt_bouwplannen": .buurtLeven,
        "buurt_participatie": .participatie,
    ]
}

/// Een onderdeel van de app dat per versie aan of uit staat. De volgorde hier
/// is de volgorde in het overzicht bij de versiekeuze.
enum Onderdeel: String, CaseIterable, Identifiable {
    case melden, fietsen
    case voorJou, afval, parkeren, zwemmen, afspraken, personalisatie
    case notificaties, regelen, buurtLeven, participatie, regelingen, video

    var id: String { rawValue }

    /// Regels in de versiekeuze. Fietsen is één onderdeel, maar twee dingen
    /// die je ziet: de pas en de kaart.
    var labelKeys: [String] {
        self == .fietsen ? ["onderdeel_fietspas", "onderdeel_fietskaart"] : ["onderdeel_\(rawValue)"]
    }
}

/// Koppeling met Dappre, van niets naar alles in de app.
enum DappreKoppeling {
    /// Geen koppeling: alleen fietspas en stallingen, er wordt niet gespaard.
    case geen
    /// Verwijzing: sparen zet je aan in de app van Dappre, je verlaat de app.
    case link
    /// API: spaardoel, clubs en spaarplekken zitten in de Den Haag-app zelf.
    case api
}

/// Verzonnen clubs voor het prototype. Dappre heeft echte clubs; die noemen we
/// hier bewust niet, want er is nog geen koppeling.
enum DappreClubs {
    static let all = [
        "VV De Ooievaars", "Hockeyclub Zuiderpark", "Scouting Duinrand",
        "Zwemclub De Golfbreker", "Speeltuin De Regenboog", "Buurtmoestuin Transvaal",
        "Muziekvereniging Harmonie Zuid", "Dierenopvang 't Hofje",
    ]
    /// Clubs vlak bij het thuisadres; die staan bovenaan bij het kiezen.
    static let dichtbij = ["VV De Ooievaars", "Speeltuin De Regenboog", "Buurtmoestuin Transvaal"]
    static var overig: [String] { all.filter { !dichtbij.contains($0) } }
    static let url = URL(string: "https://dappre.com/download/")!
}

/// Houdt de gekozen versie bij en bewaart die tussen sessies. "Demo resetten"
/// laat de versie staan: die kiest de onderzoeker, niet de deelnemer.
final class VersieManager: ObservableObject {
    @Published var current: AppVersie {
        didSet {
            UserDefaults.standard.set(current.rawValue, forKey: "app_versie")
            AnalyticsService.setSession(["appVersie": current.rawValue])
            AnalyticsService.track("switch_versie", ["versie": current.rawValue])
        }
    }

    init() {
        // Sinds 2026-11-10 opent de app standaard in Versie 2. Eenmalig ook voor
        // wie al een versie had opgeslagen (vaak "Prototype testen"); daarna
        // blijft een eigen keuze op "Versie van de app" gewoon bewaard.
        let migratieKey = "versieStandaardV2"
        if !UserDefaults.standard.bool(forKey: migratieKey) {
            UserDefaults.standard.set(AppVersie.v2.rawValue, forKey: "app_versie")
            UserDefaults.standard.set(true, forKey: migratieKey)
        }
        #if DEBUG
        // Testharnas: `-versie v1` (of v2/v3) start direct in die versie.
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-versie"), i + 1 < args.count,
           let gekozen = AppVersie(rawValue: args[i + 1]) {
            UserDefaults.standard.set(gekozen.rawValue, forKey: "app_versie")
        }
        #endif
        // Onbekende opgeslagen waarden vallen terug op de standaard: versie 2.
        let saved = UserDefaults.standard.string(forKey: "app_versie") ?? ""
        current = AppVersie(rawValue: saved) ?? .v2
        AnalyticsService.setSession(["appVersie": current.rawValue])
    }
}
