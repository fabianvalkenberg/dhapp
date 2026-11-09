import SwiftUI
import Combine

// MARK: - Tile destination

/// Waar een tegel naartoe leidt wanneer erop getikt wordt.
enum TileDestination {
    case parkeren
    case afval
    case grofvuil
    case zwemmen
    case ooievaarspas
    case afvalkalender
    case overlast
    case buurt
    case afspraak   // Afspraak maken / ID aanvragen → afspraakscherm
    case rechten    // "Waar heb ik recht op" → info-pagina
    case bieb       // "Naar de bieb" → info-pagina
    case buurtFilter(String)  // Snelkoppeling naar Buurt met een onderwerp-filter aan
    case fietsParkeren  // Kaart met fietsenstallingen
    case fietspas       // Fietspas met barcode
    case berichten      // Berichten (notificaties)
    case vergunningen   // Mijn vergunningen (ondernemer)
    case meldingStatus  // Status van je laatste melding
}

// MARK: - Preference Tile

/// Een tegel die de gebruiker in de onboarding kan kiezen en die op het
/// homescherm als springplank verschijnt.
struct PreferenceTile: Identifiable {
    let id: String
    let titleKey: String       // LanguageManager-key
    let illustration: String   // asset-naam
    let destination: TileDestination
    var isSelected: Bool
    /// false = de tegel is alleen tonend en niet aantikbaar (geen navigatie/feedback).
    var isInteractive: Bool = true

    /// Volledige catalogus. `isSelected` hier is de fabrieks-default.
    static let catalog: [PreferenceTile] = [
        // Fiets — staan bovenaan het startscherm
        PreferenceTile(id: "fietsparkeren", titleKey: "tile_fietsparkeren", illustration: "ill-fietsparkeren", destination: .fietsParkeren, isSelected: true),
        PreferenceTile(id: "fietspas",      titleKey: "tile_fietspas",      illustration: "ill-fietspas", destination: .fietspas,   isSelected: true),

        // Stap 1 — "Wat doe jij vaak bij de gemeente?" (acties + persoonlijke info)
        PreferenceTile(id: "parkeerbezoek", titleKey: "tile_parkeerbezoek", illustration: "ill-parkeerbezoek",  destination: .parkeren,      isSelected: true),
        PreferenceTile(id: "overlast",      titleKey: "tile_overlast",      illustration: "ill-melding",        destination: .overlast,      isSelected: true),
        PreferenceTile(id: "afspraak",      titleKey: "tile_afspraak",      illustration: "ill-afspraak",       destination: .afspraak,      isSelected: true),
        PreferenceTile(id: "afvalkalender", titleKey: "tile_afvalkalender", illustration: "ill-afvalkalender",  destination: .afvalkalender, isSelected: false),
        PreferenceTile(id: "afval",         titleKey: "tile_afval",         illustration: "ill-afvalzak",       destination: .afval,         isSelected: true),
        PreferenceTile(id: "ooievaarspas",  titleKey: "tile_ooievaarspas",  illustration: "ill-ooievaarspas",   destination: .ooievaarspas,  isSelected: true),
        PreferenceTile(id: "rechten",       titleKey: "tile_rechten",       illustration: "ill-id",             destination: .rechten,       isSelected: false),
        PreferenceTile(id: "bieb",          titleKey: "tile_bieb",          illustration: "sf:books.vertical.fill", destination: .bieb,      isSelected: false),

        // Stap 2 — buurt-snelkoppelingen: openen de kaart met dit onderwerp aan
        PreferenceTile(id: "buurt_evenementen", titleKey: "tile_buurt_evenementen", illustration: "ill-buurt",       destination: .buurtFilter("evenementen"), isSelected: false),
        PreferenceTile(id: "buurt_sport",       titleKey: "tile_buurt_sport",       illustration: "ill-sport",       destination: .buurtFilter("sport"),       isSelected: false),
        PreferenceTile(id: "buurt_wegwerk",     titleKey: "tile_buurt_wegwerk",     illustration: "ill-wegwerk",     destination: .buurtFilter("wegwerk"),     isSelected: false),
        PreferenceTile(id: "buurt_bouwplannen", titleKey: "tile_buurt_bouwplannen", illustration: "ill-bouwplannen", destination: .buurtFilter("bouwplannen"), isSelected: false),
        PreferenceTile(id: "buurt_participatie", titleKey: "tile_buurt_participatie", illustration: "ill-buurt",     destination: .buurtFilter("participatie"), isSelected: false),

        // Niet in onboarding, wel via "Startscherm aanpassen" beschikbaar
        PreferenceTile(id: "mijnbuurt",     titleKey: "tile_mijnbuurt",     illustration: "ill-buurt",          destination: .buurt,         isSelected: false),
        PreferenceTile(id: "zwemmen",       titleKey: "tile_zwemmen",       illustration: "ill-zwemmen",        destination: .zwemmen,       isSelected: true),
        PreferenceTile(id: "grofvuil",      titleKey: "tile_grofvuil",      illustration: "ill-grofvuil",       destination: .grofvuil,      isSelected: false),
    ]
}

// MARK: - Per versie

extension PreferenceTile {
    /// Alle tegels die bij de onderdelen van een versie horen. Buurt-
    /// snelkoppelingen niet: die staan al als filters op de kaart.
    static func standaard(voor versie: AppVersie) -> Set<String> {
        Set(versie.tegels)
    }
}

// MARK: - Ondernemer

extension PreferenceTile {
    /// Als ondernemer dezelfde tegels met een zakelijke kant: andere naam,
    /// persoonlijke tegels (zwemmen, Ooievaarspas, fietspas) vallen weg, en
    /// vergunningen komt vooraan.
    static func alsOndernemer(_ tegels: [PreferenceTile], metVergunningen: Bool = true) -> [PreferenceTile] {
        let naam: [String: String] = [
            "overlast": "tile_ond_melden",
            "parkeerbezoek": "tile_ond_parkeren",
            "afval": "tile_ond_afval", "afvalkalender": "tile_ond_afval", "grofvuil": "tile_ond_afval",
            "afspraak": "tile_ond_afspraak",
            "fietsparkeren": "tile_ond_fietsparkeren",
            "buurt_wegwerk": "tile_ond_wegwerk",
        ]
        let weg: Set<String> = ["fietspas", "zwemmen", "ooievaarspas", "rechten", "bieb", "mijnbuurt", "buurt_sport"]
        var gezien = Set<String>()
        var uit: [PreferenceTile] = !metVergunningen ? [] : [
            PreferenceTile(id: "ond_vergunningen", titleKey: "tile_ond_vergunningen",
                           illustration: "sf:doc.text.fill", destination: .vergunningen, isSelected: true),
            PreferenceTile(id: "ond_terras", titleKey: "tile_ond_terras",
                           illustration: "sf:umbrella.fill", destination: .vergunningen, isSelected: true),
        ]
        for t in tegels where !weg.contains(t.id) {
            let key = naam[t.id] ?? t.titleKey
            guard !gezien.contains(key) else { continue }   // drie afvaltegels worden één
            gezien.insert(key)
            uit.append(PreferenceTile(id: t.id, titleKey: key, illustration: t.illustration,
                                      destination: t.destination, isSelected: t.isSelected,
                                      isInteractive: t.isInteractive))
        }
        return uit
    }
}

// MARK: - Home Settings Model

class HomeSettingsModel: ObservableObject {
    @Published var tiles: [PreferenceTile]
    @Published var cardShadows: Bool
    /// Naam die in de onboarding wordt opgegeven; terug te zien in de home-greeting.
    @Published var userName: String

    private let selectionKey = "selectedTileIDs"
    /// Welke tegels bestonden toen de selectie werd opgeslagen. Een tegel die
    /// daarna aan de catalogus is toegevoegd, krijgt zo zijn fabrieks-default
    /// in plaats van stil uit te staan.
    private let knownKey = "knownTileIDs"
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Card shadows: default aan
        if UserDefaults.standard.object(forKey: "cardShadows") == nil {
            self.cardShadows = true
        } else {
            self.cardShadows = UserDefaults.standard.bool(forKey: "cardShadows")
        }

        // Opgegeven naam (leeg = nog niet ingevuld → home valt terug op "Anne")
        self.userName = UserDefaults.standard.string(forKey: "userName") ?? ""

        // Tegels: laad opgeslagen selectie, anders de fabrieks-default
        var catalog = PreferenceTile.catalog
        if let savedIDs = UserDefaults.standard.array(forKey: selectionKey) as? [String] {
            let saved = Set(savedIDs)
            let known = Set(UserDefaults.standard.array(forKey: knownKey) as? [String] ?? savedIDs)
            for index in catalog.indices where known.contains(catalog[index].id) || saved.contains(catalog[index].id) {
                catalog[index].isSelected = saved.contains(catalog[index].id)
            }
        }
        self.tiles = catalog

        // Persisteer card shadows
        $cardShadows
            .dropFirst()
            .sink { UserDefaults.standard.set($0, forKey: "cardShadows") }
            .store(in: &cancellables)

        // Persisteer de naam
        $userName
            .dropFirst()
            .sink { UserDefaults.standard.set($0, forKey: "userName") }
            .store(in: &cancellables)

        // Persisteer tegel-selectie
        $tiles
            .dropFirst()
            .sink { [weak self] tiles in
                guard let self else { return }
                let ids = tiles.filter { $0.isSelected }.map { $0.id }
                UserDefaults.standard.set(ids, forKey: self.selectionKey)
                UserDefaults.standard.set(tiles.map { $0.id }, forKey: self.knownKey)
            }
            .store(in: &cancellables)
    }

    /// De tegels die op het homescherm getoond worden.
    var selectedTiles: [PreferenceTile] {
        tiles.filter { $0.isSelected }
    }

    /// Naam voor de begroeting; valt terug op "Anne" als er niets is opgegeven.
    var greetingName: String {
        let trimmed = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Anne" : trimmed
    }

    func toggleTile(id: String) {
        if let index = tiles.firstIndex(where: { $0.id == id }) {
            tiles[index].isSelected.toggle()
        }
    }

    /// Zet de selectie op basis van een verzameling id's (gebruikt door onboarding).
    func setSelection(ids: Set<String>) {
        for index in tiles.indices {
            tiles[index].isSelected = ids.contains(tiles[index].id)
        }
    }
}
