import Foundation
import CoreLocation

/// Een vaste plek op de kaart: een fietsenstalling of een koffieplek waar je
/// fietspas-punten kunt inwisselen.
struct KaartPlek: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let address: String
    /// Openingstijden van maandag t/m zondag; nil = die dag gesloten.
    let hours: [String?]
    /// Voorzieningen die op het kaartje getoond worden.
    var extras: [String] = []
    /// Alleen true als de bron dit tarief zelf vermeldt.
    var firstDayFree: Bool = false
    /// Wat een spaarplek bijdraagt als je er betaalt, bv. "4%". Verzonnen.
    var bijdrage: String? = nil
    let latitude: Double
    let longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Asset-naam van de foto bij deze plek, bv. "foto-plek-grotemarkt". Ontbreekt
    /// de foto, dan valt het kaartje terug op het gele vlak. Bronnen en licenties
    /// staan in docs/FOTOBRONNEN.md.
    var imageName: String {
        "foto-plek-" + title.folding(options: .diacriticInsensitive, locale: nil)
            .lowercased().filter { $0.isLetter }
    }

    /// Geschatte fietstijd vanaf je locatie (prototype: het thuisadres). Hemelsbreed
    /// maal 1,3 voor de omweg door de straten, bij 15 km per uur.
    var bikeMinutes: Int {
        let home = CLLocation(latitude: BuurtView.thuisCoord.latitude, longitude: BuurtView.thuisCoord.longitude)
        let meters = CLLocation(latitude: latitude, longitude: longitude).distance(from: home) * 1.3
        return max(1, Int((meters / 250).rounded()))
    }

    /// Openingstijd van vandaag; nil = vandaag gesloten.
    var hoursToday: String? {
        // Calendar: 1 = zondag … 7 = zaterdag → index 0 = maandag.
        let weekday = Calendar.current.component(.weekday, from: Date())
        return hours[(weekday + 5) % 7]
    }

    static func == (lhs: KaartPlek, rhs: KaartPlek) -> Bool { lhs.id == rhs.id }

    /// Zelfde tijden op alle zeven dagen.
    private static func daily(_ t: String) -> [String?] { Array(repeating: t, count: 7) }

    // MARK: - Fietsenstallingen

    /// Bewaakte stallingen van Biesieklette in Den Haag. Adressen, coördinaten,
    /// openingstijden en voorzieningen komen van biesieklette.nl/fiets-stallen
    /// (overgenomen op 8 oktober 2026). Het hoofdkantoor en de permanent gesloten
    /// stalling Zwarte Pad zijn weggelaten.
    static let stallingen: [KaartPlek] = [
        KaartPlek(title: "Hobbemaplein", address: "Herman Costerstraat 260",
                  hours: ["08:30 – 17:30", nil, "08:30 – 17:30", nil, "08:30 – 17:30", "08:30 – 17:30", nil],
                  extras: ["Elektrisch opladen"],
                  latitude: 52.0659729, longitude: 4.297023),
        KaartPlek(title: "Groenteweg", address: "Groenteweg 1",
                  hours: ["08:30 – 17:30", nil, "08:30 – 17:30", nil, "08:30 – 17:30", "08:30 – 17:30", nil],
                  extras: ["Elektrisch opladen"],
                  latitude: 52.0625828, longitude: 4.3015518),
        KaartPlek(title: "Grote Markt", address: "Laan 9",
                  hours: ["07:30 – 01:30", "07:30 – 01:30", "07:30 – 01:30", "07:30 – 03:00", "07:30 – 03:00", "07:30 – 03:00", "09:00 – 01:30"],
                  extras: ["Toilet", "Elektrisch opladen", "Fietslampjes"],
                  latitude: 52.0759813, longitude: 4.3078813),
        KaartPlek(title: "Driehoekjes", address: "Grote Halstraat 9",
                  hours: ["07:30 – 18:30", "07:30 – 18:30", "07:30 – 18:30", "07:30 – 21:30", "07:30 – 18:30", "07:30 – 18:30", "11:30 – 18:30"],
                  extras: ["Elektrisch opladen"],
                  latitude: 52.0779165, longitude: 4.3083501),
        KaartPlek(title: "Nobelstraat", address: "Nobelstraat 2D",
                  hours: ["07:30 – 01:30", "07:30 – 01:30", "07:30 – 01:30", "07:30 – 03:30", "07:30 – 03:30", "07:30 – 03:30", "09:00 – 01:30"],
                  extras: ["Toilet", "Kluisjes", "Elektrisch opladen"],
                  firstDayFree: true,
                  latitude: 52.0785915, longitude: 4.3071162),
        KaartPlek(title: "Buitenhof", address: "Buitenhof t/o 21",
                  hours: ["07:30 – 01:30", "07:30 – 01:30", "07:30 – 01:30", "07:30 – 03:00", "07:30 – 03:00", "07:30 – 03:00", "09:30 – 01:30"],
                  extras: ["Toilet", "Elektrisch opladen"],
                  firstDayFree: true,
                  latitude: 52.079027, longitude: 4.310881),
        KaartPlek(title: "Noordeinde", address: "Noordeinde 89C",
                  hours: daily("07:30 – 01:30"),
                  latitude: 52.0825571, longitude: 4.3057126),
        KaartPlek(title: "Voldersgracht", address: "Voldersgracht 42",
                  hours: ["07:30 – 18:30", "07:30 – 18:30", "07:30 – 18:30", "07:30 – 21:30", "07:30 – 18:30", "07:30 – 18:30", "11:30 – 18:30"],
                  extras: ["Elektrisch opladen"],
                  latitude: 52.0766945, longitude: 4.3143765),
        KaartPlek(title: "Stadhuis", address: "Spuiplein 70",
                  hours: ["06:00 – 01:00", "06:00 – 01:00", "06:00 – 01:00", "06:00 – 01:00", "06:00 – 01:00", "08:00 – 01:00", "11:30 – 01:00"],
                  extras: ["Elektrisch opladen", "Fietslampjes"],
                  latitude: 52.0772433, longitude: 4.3159195),
        KaartPlek(title: "Kranestraat", address: "Amsterdamse Veerkade 30",
                  hours: ["07:30 – 18:30", "07:30 – 18:30", "07:30 – 18:30", "07:30 – 21:30", "07:30 – 18:30", "07:30 – 18:30", "11:30 – 18:30"],
                  extras: ["PostNL pakketpunt", "Elektrisch opladen", "Fietslampjes"],
                  latitude: 52.0756323, longitude: 4.3160456),
        KaartPlek(title: "Plein (Korte Poten)", address: "Korte Poten 27",
                  hours: ["07:30 – 01:30", "07:30 – 01:30", "07:30 – 01:30", "07:30 – 03:30", "07:30 – 03:30", "07:30 – 03:30", "09:30 – 01:30"],
                  extras: ["Elektrisch opladen"],
                  latitude: 52.080052, longitude: 4.3178678),
        KaartPlek(title: "Amare", address: "Turfhaven 7",
                  hours: ["07:30 – 23:00", "07:30 – 23:00", "07:30 – 23:00", "07:30 – 23:00", "07:30 – 23:00", "11:00 – 23:00", "11:00 – 23:00"],
                  firstDayFree: true,
                  latitude: 52.0777904, longitude: 4.3190016),
        KaartPlek(title: "Rijnstraat (Fietsflat)", address: "Rijnstraat",
                  hours: ["04:55 – 01:30", "04:55 – 01:30", "04:55 – 01:30", "04:55 – 01:30", "04:55 – 02:15", "04:40 – 02:15", "04:40 – 01:55"],
                  latitude: 52.07987, longitude: 4.32477),
        KaartPlek(title: "Anna van Buerenstraat", address: "Anna van Buerenstraat 120",
                  hours: ["04:45 – 01:30", "04:45 – 01:30", "04:45 – 01:30", "04:45 – 01:30", "04:45 – 02:15", "05:00 – 02:15", "06:00 – 01:45"],
                  extras: ["Elektrisch opladen"],
                  latitude: 52.080042, longitude: 4.326865),
        KaartPlek(title: "Leyweg", address: "Leyweg 914",
                  hours: ["10:30 – 18:30", "08:30 – 18:30", "08:30 – 18:30", "08:30 – 21:30", "08:30 – 18:30", "08:30 – 17:30", "11:30 – 17:30"],
                  extras: ["Elektrisch opladen"],
                  latitude: 52.0504337, longitude: 4.2741039),
        KaartPlek(title: "Strandweg-Haven", address: "Strandweg 10",
                  hours: [nil, nil, nil, nil, nil, "10:00 – 18:00", "10:00 – 18:00"],
                  extras: ["Toilet", "Strandrolstoel", "Elektrisch opladen"],
                  latitude: 52.1012823, longitude: 4.2626667),
        KaartPlek(title: "Palaceplein", address: "Gevers Deynootweg 1134",
                  hours: ["09:00 – 23:00", "09:00 – 23:00", "09:00 – 23:00", "09:00 – 02:00", "09:00 – 02:00", "09:00 – 02:00", "09:00 – 23:00"],
                  extras: ["Elektrisch opladen"],
                  latitude: 52.1145932, longitude: 4.2845906),
        KaartPlek(title: "Noordboulevard", address: "Strandweg 171",
                  hours: daily("08:30 – 23:00"),
                  extras: ["Toilet", "Kluisjes", "Strandrolstoel"],
                  latitude: 52.1169928, longitude: 4.2859234),
        KaartPlek(title: "Kijkduin", address: "Deltaplein 202",
                  hours: daily("09:00 – 23:00"),
                  extras: ["Toilet", "Strandrolstoel", "Elektrisch opladen"],
                  latitude: 52.0696626, longitude: 4.2216115),
    ]

    // MARK: - Koffieplekken

    /// Verzonnen spaarplekken (prototype): zaken waar je bij betalen meespaart voor
    /// je club, zoals "spaar hier" in Dappre. Namen en bijdragen zijn bedacht.
    static let koffieplekken: [KaartPlek] = [
        KaartPlek(title: "Koffiehuis Hobbema", address: "Hobbemaplein 10",
                  hours: daily("08:00 – 17:00"),
                  bijdrage: "3%",
                  latitude: 52.0663, longitude: 4.2975),
        KaartPlek(title: "Kopje Zeeheld", address: "Prins Hendrikstraat 80",
                  hours: daily("08:00 – 18:00"),
                  bijdrage: "5%",
                  latitude: 52.0790, longitude: 4.2930),
        KaartPlek(title: "De Fietsbel", address: "Weimarstraat 45",
                  hours: ["08:30 – 17:30", "08:30 – 17:30", "08:30 – 17:30", "08:30 – 17:30", "08:30 – 17:30", "09:00 – 17:30", nil],
                  bijdrage: "4%",
                  latitude: 52.0760, longitude: 4.2870),
        KaartPlek(title: "Zadel & Zo", address: "Grote Markt 22",
                  hours: daily("09:00 – 22:00"),
                  bijdrage: "2%",
                  latitude: 52.0760, longitude: 4.3075),
        KaartPlek(title: "Koffiebar De Trapper", address: "Prinsestraat 52",
                  hours: daily("08:00 – 18:00"),
                  bijdrage: "5%",
                  latitude: 52.0795, longitude: 4.3055),
        KaartPlek(title: "Bakkie aan het Plein", address: "Plein 12",
                  hours: daily("07:30 – 19:00"),
                  bijdrage: "3%",
                  latitude: 52.0796, longitude: 4.3160),
        KaartPlek(title: "Café Het Voorwiel", address: "Denneweg 30",
                  hours: ["09:00 – 18:00", "09:00 – 18:00", "09:00 – 18:00", "09:00 – 18:00", "09:00 – 18:00", "09:00 – 18:00", "10:00 – 17:00"],
                  bijdrage: "4%",
                  latitude: 52.0838, longitude: 4.3140),
        KaartPlek(title: "Strandbakkie", address: "Strandweg 55",
                  hours: daily("09:00 – 20:00"),
                  bijdrage: "6%",
                  latitude: 52.1090, longitude: 4.2730),
    ]
}
