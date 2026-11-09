import SwiftUI
import CoreLocation

/// Onderwerp van een melding openbare ruimte (Figma "prototype MOR '26", Step 1).
/// De vervolgvragen komen uit het huidige MOR-prototype. Prototype: verzonnen
/// lijsten, alleen Nederlands.
enum MORCategorie: String, CaseIterable, Identifiable {
    case verlichting, auto, container, grofvuil, anders

    var id: String { rawValue }

    /// De vier tegels in stap 1 (Figma-volgorde).
    static let tegels: [MORCategorie] = [.verlichting, .auto, .container, .grofvuil]

    var emoji: String {
        switch self {
        case .verlichting: return "💡"
        case .auto:        return "🚗"
        case .container:   return "♻️"
        case .grofvuil:    return "🛋️"
        case .anders:      return "📍"
        }
    }

    var tegelKey: String { "mor_cat_\(rawValue)" }
    /// Zin die in het tekstveld komt als je de tegel kiest.
    var zinKey: String { "mor_cat_\(rawValue)_zin" }

    /// Titel van de kaartstap.
    var waarKey: String {
        switch self {
        case .container: return "mor_waar_container"
        case .auto:      return "mor_waar_voertuig"
        default:         return "mor_waar_title"
        }
    }

    /// Vervolgvragen; leeg = de stap valt weg.
    var vervolg: [MORVraag] {
        switch self {
        case .verlichting:
            return [
                MORVraag(id: "soort", vraag: "Waar gaat uw melding over?", opties: [
                    "Lamp brandt niet",
                    "Meer dan 5 lampen branden niet in de straat",
                    "Lamp geeft lichthinder (schijnt bijvoorbeeld in de slaapkamer)",
                    "Lamp of lantaarnpaal is beschadigd of niet compleet",
                    "Anders",
                ]),
                MORVraag(id: "gevaar", vraag: "Hangen er losse draden of ligt de paal op straat?", opties: [
                    "Ja",
                    "Nee",
                ], alleenBij: ["Lamp of lantaarnpaal is beschadigd of niet compleet"]),
            ]
        case .auto:
            return [
                MORVraag(id: "soort", vraag: "Waar gaat uw melding over?", opties: [
                    "Overlast van een foutgeparkeerd motorvoertuig",
                    "Overlast van een groot voertuig dat foutgeparkeerd staat",
                    "Overlast van een caravan, camper of aanhangwagen",
                    "Overlast van een verwaarloosd motorvoertuig",
                    "Anders",
                ]),
                MORVraag(id: "plek", vraag: "Waar staat het voertuig?", opties: [
                    "Op een invalide plek",
                    "Laad- en loshaven",
                    "Op een in- of uitrit",
                    "Overige plek",
                ], alleenBij: [
                    "Overlast van een foutgeparkeerd motorvoertuig",
                    "Overlast van een groot voertuig dat foutgeparkeerd staat",
                ]),
            ]
        case .container:
            return [
                MORVraag(id: "soort", vraag: "Waar gaat uw melding over?", opties: [
                    "Container is vol",
                    "Afval naast de container",
                    "Container is kapot",
                    "Container gaat niet open",
                    "Anders",
                ]),
                MORVraag(id: "soortContainer", vraag: "Wat voor container is het?", opties: [
                    "Restafval",
                    "Papier",
                    "Glas",
                    "Plastic, blik en pak",
                    "Weet ik niet",
                ]),
            ]
        case .grofvuil:
            return [MORVraag(id: "soort", vraag: "Waar gaat uw melding over?", opties: [
                "Bank, kast of matras op straat",
                "Bouw- en sloopafval",
                "Elektrische apparaten",
                "Anders",
            ])]
        case .anders:
            return []
        }
    }

    /// Onderwerp afleiden uit wat iemand zelf typt of inspreekt.
    static func herken(_ tekst: String) -> MORCategorie {
        let t = tekst.lowercased()
        func heeft(_ woorden: [String]) -> Bool { woorden.contains { t.contains($0) } }
        if heeft(["lamp", "licht", "lantaarn", "donker"]) { return .verlichting }
        if heeft(["auto", "geparkeerd", "parkeer", "voertuig", "camper", "aanhanger", "busje"]) { return .auto }
        if heeft(["container", "vuilnis", "afvalbak", "papierbak", "glasbak"]) { return .container }
        if heeft(["bank", "matras", "kast", "grofvuil", "dump", "koelkast"]) { return .grofvuil }
        return .anders
    }
}

struct MORVraag: Identifiable {
    let id: String
    let vraag: String
    let opties: [String]
    /// Alleen tonen als het antwoord op "soort" een van deze is; nil = altijd.
    var alleenBij: [String]? = nil
}

/// Containers rond het thuisadres (verzonnen), voor de kaart bij een containermelding.
struct MORContainer: Identifiable {
    let id: Int
    let coordinate: CLLocationCoordinate2D

    static let rondThuis: [MORContainer] = {
        let t = BuurtView.thuisCoord
        let offsets: [(Double, Double)] = [
            (0.0014, 0.0016), (0.0016, -0.0012), (0.0003, -0.0021),
            (-0.0009, 0.0011), (-0.0017, -0.0019), (-0.0004, 0.0024),
        ]
        return offsets.enumerated().map { i, o in
            MORContainer(id: i, coordinate: CLLocationCoordinate2D(latitude: t.latitude + o.0, longitude: t.longitude + o.1))
        }
    }()
}

/// Straten om uit te kiezen bij "Kies straat" (echte Haagse straten).
enum MORStraten {
    static let alle = [
        "Beeklaan", "Elandstraat", "Escamplaan", "Fahrenheitstraat", "Frederik Hendriklaan",
        "Goudenregenstraat", "Grote Marktstraat", "Herengracht", "Hobbemastraat", "Hoefkade",
        "Laan van Meerdervoort", "Lange Voorhout", "Leyweg", "Loosduinseweg", "Mient",
        "Paul Krugerlaan", "Prinsegracht", "Regentesselaan", "Spui", "Stationsweg",
        "Thomsonlaan", "Torenstraat", "Vaillantlaan", "Valkenboskade", "Van Bleiswijkstraat",
        "Waldorpstraat", "Weimarstraat", "Zoutmanstraat",
    ]
}
