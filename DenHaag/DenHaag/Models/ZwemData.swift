import Foundation

// MARK: - Zwemmen: dummy-data
//
// Overgenomen uit het HTML-prototype (input/zwemmen). Rooster, adressen, prijzen
// en wachttijden komen van denhaag.nl (stand oktober 2026). Namen van activiteiten,
// zwembaden en nieuws zijn inhoud uit een (toekomstige) bron en blijven Nederlands;
// alles eromheen loopt via LanguageManager.

struct Zwembad: Identifiable, Hashable {
    let naam: String
    let foto: String
    let adres: String
    let telefoon: String
    let voorzieningen: [Voorziening]
    var id: String { naam }

    struct Voorziening: Hashable {
        let icoon: String
        let key: String
    }
}

/// Eén activiteit in het rooster, zoals "Banenzwemmen 07.00 - 08.15 in De Waterthor".
struct ZwActiviteit: Identifiable, Hashable, Codable {
    let naam: String
    let zwembad: String
    let start: String   // "13.00"
    let eind: String

    var id: String { "\(zwembad)|\(naam)|\(start)" }
    var tijd: String { "\(start) - \(eind)" }
    var startMin: Int { ZwData.minuten(start) }
    var eindMin: Int { ZwData.minuten(eind) }

    var categorie: ZwCategorie { ZwCategorie.van(naam) }
    var dagdeel: ZwDagdeel { startMin < 720 ? .ochtend : startMin < 1080 ? .middag : .avond }
}

/// Activiteitgroepen voor de filters. Vrij zwemmen en banenzwemmen zijn de inloopactiviteiten.
enum ZwCategorie: String, CaseIterable, Codable {
    case vrij, banen, aqua, baby, training, overig

    static func van(_ naam: String) -> ZwCategorie {
        if naam.hasPrefix("Vrijzwemmen") { return .vrij }
        if naam.hasPrefix("Banenzwemmen") { return .banen }
        if naam.lowercased().hasPrefix("aqua") { return .aqua }
        if naam.hasPrefix("Teddybeer") { return .baby }
        if naam.contains("zwemslag") { return .training }
        return .overig
    }

    var titelKey: String { "zw_cat_\(rawValue)" }
    var subKey: String? { self == .banen ? nil : "zw_cat_\(rawValue)_sub" }
}

enum ZwDagdeel: String, CaseIterable, Codable {
    case ochtend, middag, avond
    var titelKey: String { "zw_part_\(rawValue)" }
    var subKey: String { "zw_part_\(rawValue)_sub" }
}

struct ZwFilters: Equatable {
    var zwembaden: [String] = []
    var categorieen: [ZwCategorie] = []
    var dagdelen: [ZwDagdeel] = []

    var aantal: Int { zwembaden.count + categorieen.count + dagdelen.count }

    func past(_ a: ZwActiviteit) -> Bool {
        (zwembaden.isEmpty || zwembaden.contains(a.zwembad))
            && (categorieen.isEmpty || categorieen.contains(a.categorie))
            && (dagdelen.isEmpty || dagdelen.contains(a.dagdeel))
    }
}

/// Een gekocht kaartje (prototype: betalen zit er niet in).
struct ZwReservering: Codable, Equatable {
    let activiteit: ZwActiviteit
    let datum: Date

    /// Een reservering geldt tot de activiteit is afgelopen.
    var isGeldig: Bool {
        let eind = Calendar.current.date(byAdding: .minute, value: activiteit.eindMin, to: Calendar.current.startOfDay(for: datum)) ?? datum
        return eind > Date()
    }
}

struct ZwNieuws: Identifiable {
    let id = UUID()
    let datum: Date
    let tijd: String
    let zwembad: String
    let titel: String
    let tekst: String
}

// MARK: - Zwemles

struct ZwOefening: Codable, Hashable {
    let key: String
    let niveau: Int   // 1 brons · 2 zilver · 3 goud
}

struct ZwKind: Codable, Identifiable, Equatable {
    enum Status: String, Codable { case les, wacht }

    let id: String
    var naam: String
    var status: Status
    var zwembad: String

    // Op les
    var lesdag: Int = 4             // Calendar-weekdag (1 = zondag)
    var lestijd: String = ""
    var lesstart: String = ""
    var diploma: String = "A"
    var niveau: Int = 1
    var oefeningen: [ZwOefening] = []
    var bijgewerkt: Date? = nil
    var afgemeld: [String] = []
    var verlengd: Bool = false

    // Op de wachtlijst
    var plek: Int = 0
    var startPlek: Int = 0
    var sinds: Date? = nil
    var oproep: Date? = nil
    var ervaring: Bool = false
    var extra: [String] = []

    var gouden: Int { oefeningen.filter { $0.niveau == 3 }.count }
}

struct ZwAanmelding {
    var stap = 1
    var voornaam = ""
    var achternaam = ""
    var geboortedatum: Date? = nil
    var ervaring: Bool? = nil
    var zwembad: String? = nil
    var extra: [String] = []
    var fouten: [String: String] = [:]   // veld → vertaalsleutel
    var nieuwId: String? = nil
}

struct ZwLes: Hashable {
    let key: String
    let datum: Date
}

// MARK: - Data

enum ZwData {
    static let zwembaden: [Zwembad] = [
        Zwembad(naam: "De Blinkerd", foto: "foto-zwembad-blinkerd", adres: "Seinpoststraat 150", telefoon: "070 352 12 22",
                voorzieningen: [
                    .init(icoon: "zw-fac-25m", key: "zw_fac_25m"),
                    .init(icoon: "zw-fac-ondiep", key: "zw_fac_ondiep"),
                    .init(icoon: "zw-fac-whirlpool", key: "zw_fac_whirlpool"),
                    .init(icoon: "zw-fac-warmte", key: "zw_fac_warmte"),
                ]),
        Zwembad(naam: "Het Hofbad", foto: "foto-zwembad-hofbad", adres: "Ypenburgse Boslaan 30", telefoon: "015 310 83 96", voorzieningen: []),
        Zwembad(naam: "De Houtzagerij", foto: "foto-zwembad-houtzagerij", adres: "Hobbemastraat 93", telefoon: "070 389 04 04", voorzieningen: []),
        Zwembad(naam: "Overbosch", foto: "foto-zwembad-overbosch", adres: "Vlaskamp 3", telefoon: "070 347 46 84", voorzieningen: []),
        Zwembad(naam: "De Waterthor", foto: "foto-zwembad-waterthor", adres: "Thorbeckelaan 350", telefoon: "070 323 51 41", voorzieningen: []),
        Zwembad(naam: "Het Zuiderpark", foto: "foto-zwembad-zuiderpark", adres: "Mr. P. Droogleever Fortuynweg 59", telefoon: "070 367 94 63", voorzieningen: []),
    ]

    static var namen: [String] { zwembaden.map(\.naam) }

    static func zwembad(_ naam: String) -> Zwembad? { zwembaden.first { $0.naam == naam } }

    /// Wachttijden zwemles (indicatie uit de sportwebshop, jeugd, oktober 2026). Het Hofbad heeft geen zwemles van de gemeente.
    static let wachttijden: [(zwembad: String, maanden: Int)] = [
        ("Overbosch", 9), ("De Blinkerd", 12), ("De Waterthor", 15), ("De Houtzagerij", 19), ("Het Zuiderpark", 19),
    ]

    static let nieuws: [ZwNieuws] = [
        ZwNieuws(datum: datum(2026, 10, 17), tijd: "18.00 - 20.00", zwembad: "Het Hofbad",
                 titel: "Discozwemmen in het Hofbad", tekst: "Kom met vrienden of familie naar de zwemdisco."),
        ZwNieuws(datum: datum(2026, 10, 19), tijd: "09.00 - 21.00", zwembad: "De Waterthor",
                 titel: "Zwemmarathon bij de Waterthor", tekst: "Zwem 1 of 2 uur alleen. Of doe mee met een team voor 4 of 12 uur."),
        ZwNieuws(datum: datum(2026, 10, 20), tijd: "18.15 - 20.15", zwembad: "De Blinkerd",
                 titel: "Discozwemmen in de Blinkerd", tekst: "Kom met vrienden of familie naar de zwemdisco."),
    ]

    /// Voorbeeldoefeningen; niet de officiële Zwem-ABC-lijst.
    static let oefeningen: [ZwOefening] = [
        .init(key: "zw_oef_1", niveau: 3), .init(key: "zw_oef_2", niveau: 3), .init(key: "zw_oef_3", niveau: 3),
        .init(key: "zw_oef_4", niveau: 2), .init(key: "zw_oef_5", niveau: 2), .init(key: "zw_oef_6", niveau: 1),
    ]

    /// Voorbeeldkinderen: Noor op les, Sem op de wachtlijst.
    static var voorbeeldKinderen: [ZwKind] {
        [
            ZwKind(id: "noor", naam: "Noor", status: .les, zwembad: "De Blinkerd",
                   lesdag: 4, lestijd: "13.30 - 14.10", lesstart: "13.30", diploma: "A", niveau: 3,
                   oefeningen: oefeningen, bijgewerkt: datum(2026, 10, 9)),
            ZwKind(id: "sem", naam: "Sem", status: .wacht, zwembad: "Overbosch",
                   plek: 214, startPlek: 312, sinds: datum(2026, 6, 3), oproep: datum(2027, 3, 1)),
        ]
    }

    // MARK: Rooster

    static func minuten(_ t: String) -> Int {
        let p = t.split(separator: ".").compactMap { Int($0) }
        return p.count == 2 ? p[0] * 60 + p[1] : 0
    }

    private static let badCodes = ["B": "De Blinkerd", "H": "Het Hofbad", "Z": "De Houtzagerij",
                                   "O": "Overbosch", "W": "De Waterthor", "P": "Het Zuiderpark"]

    /// Weekrooster per Calendar-weekdag (index 0 = zondag).
    static let week: [[ZwActiviteit]] = {
        var w = Array(repeating: [ZwActiviteit](), count: 7)
        for regel in roosterBron.split(separator: "\n") {
            let d = regel.trimmingCharacters(in: .whitespaces).split(separator: "|").map(String.init)
            guard d.count == 5, let dag = Int(d[0]), let bad = badCodes[d[4]] else { continue }
            w[dag].append(ZwActiviteit(naam: d[3], zwembad: bad, start: d[1], eind: d[2]))
        }
        return w.map { $0.sorted(by: volgorde) }
    }()

    static func volgorde(_ a: ZwActiviteit, _ b: ZwActiviteit) -> Bool {
        if a.startMin != b.startMin { return a.startMin < b.startMin }
        if a.eindMin != b.eindMin { return a.eindMin < b.eindMin }
        return a.naam < b.naam
    }

    /// Datum van dag `offset` vanaf vandaag (0 = vandaag). Het overzicht toont 15 dagen.
    static func dag(_ offset: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: offset, to: Calendar.current.startOfDay(for: Date())) ?? Date()
    }
    static let aantalDagen = 15

    /// Alle activiteiten op dag `offset`. Morgen staat er een extra Aquajoggen in De Blinkerd (de reservering uit het prototype).
    static func rooster(_ offset: Int) -> [ZwActiviteit] {
        let wd = Calendar.current.component(.weekday, from: dag(offset)) - 1
        var lijst = week[wd]
        if offset == 1 {
            lijst.append(ZwActiviteit(naam: "Aquajoggen", zwembad: "De Blinkerd", start: "13.00", eind: "14.00"))
            lijst.sort(by: volgorde)
        }
        return lijst
    }

    static var nuMinuten: Int {
        let c = Calendar.current.dateComponents([.hour, .minute], from: Date())
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    /// Activiteiten van één zwembad op dag `offset`.
    static func rooster(_ offset: Int, zwembad: String) -> [ZwActiviteit] {
        rooster(offset).filter { $0.zwembad == zwembad }
    }

    /// Eerste dag ná vandaag waarop dit zwembad activiteiten heeft (nil = de komende twee weken niet).
    static func volgendeDag(zwembad: String) -> Int? {
        (1..<aantalDagen).first { !rooster($0, zwembad: zwembad).isEmpty }
    }

    // MARK: Hulpjes

    static func datum(_ j: Int, _ m: Int, _ d: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: j, month: m, day: d)) ?? Date()
    }

    /// Leeftijd in jaren op dit moment.
    static func leeftijd(_ geboren: Date) -> Int {
        Calendar.current.dateComponents([.year], from: geboren, to: Date()).year ?? 0
    }

    /// De eerstvolgende `n` lessen van een kind, vanaf nu.
    static func lessen(_ k: ZwKind, _ n: Int) -> [ZwLes] {
        let cal = Calendar.current
        let vandaag = cal.startOfDay(for: Date())
        var plus = (k.lesdag - cal.component(.weekday, from: vandaag) + 7) % 7
        if plus == 0 && nuMinuten >= minuten(k.lesstart) { plus = 7 }
        return (0..<n).compactMap { i in
            guard let d = cal.date(byAdding: .day, value: plus + 7 * i, to: vandaag) else { return nil }
            let c = cal.dateComponents([.year, .month, .day], from: d)
            return ZwLes(key: "\(c.year ?? 0)-\(c.month ?? 0)-\(c.day ?? 0)", datum: d)
        }
    }

    static func volgendeLes(_ k: ZwKind) -> ZwLes? {
        lessen(k, 6).first { !k.afgemeld.contains($0.key) }
    }

    /// Laatste dag van deze maand (+ `plus` maanden).
    static func maandEinde(_ plus: Int = 0) -> Date {
        let cal = Calendar.current
        let begin = cal.date(from: cal.dateComponents([.year, .month], from: Date())) ?? Date()
        return cal.date(byAdding: DateComponents(month: 1 + plus, day: -1), to: begin) ?? Date()
    }

    /// Eerste dag van volgende maand; zwemles is gratis in juli en augustus.
    static var volgendeMaand: (datum: Date, gratis: Bool) {
        let d = Calendar.current.date(byAdding: .day, value: 1, to: maandEinde()) ?? Date()
        let m = Calendar.current.component(.month, from: d)
        return (d, m == 7 || m == 8)
    }

    /// Lesperiode AquaVitaal bij de huidige datum.
    static var vitaalPeriodeKey: String {
        let c = Calendar.current.dateComponents([.month, .day], from: Date())
        let md = (c.month ?? 1) * 100 + (c.day ?? 1)
        if md >= 901 && md <= 1120 { return "zw_vitaal_p1" }
        if md >= 1121 || md <= 212 { return "zw_vitaal_p2" }
        if md <= 430 { return "zw_vitaal_p3" }
        if md <= 717 { return "zw_vitaal_p4" }
        return "zw_vitaal_p5"
    }

    // Weekdag (0 = zondag) | start | eind | activiteit | bad. Gewone schoolweek 26 okt t/m 1 nov 2026, denhaag.nl.
    static let roosterBron = """
    1|12.00|13.00|Banenzwemmen|P
    1|15.30|17.00|Banenzwemmen|P
    1|09.00|11.00|Banenzwemmen|P
    1|11.30|13.00|Banenzwemmen|H
    1|13.00|15.00|Vrijzwemmen alle leeftijden|H
    1|13.15|13.45|AquaVitaal|H
    1|14.00|14.30|AquaVitaal|H
    1|19.00|20.30|Vrijzwemmen alle leeftijden|W
    1|07.00|08.15|Banenzwemmen|W
    1|12.00|13.00|Banenzwemmen|W
    1|16.00|17.30|Banenzwemmen|W
    1|20.30|22.15|Banenzwemmen|W
    1|20.00|20.45|AquaRunning|W
    1|12.00|13.00|Banenzwemmen|Z
    1|07.00|08.30|Banenzwemmen|O
    1|12.00|13.00|Banenzwemmen|O
    1|19.30|21.30|Banenzwemmen|O
    1|18.45|19.30|Aquarobic|O
    1|19.45|20.30|AquaMix|O
    1|19.30|20.30|Vrijzwemmen alle leeftijden|O
    1|20.30|21.30|Vrijzwemmen alle leeftijden|O
    1|09.30|10.00|Teddybeerzwemmen van 3 t/m 4 jaar|B
    1|09.00|09.30|Teddybeerzwemmen van 3 maanden tot 1,5 jaar|B
    1|07.00|10.30|Banenzwemmen|B
    1|12.00|13.00|Banenzwemmen|B
    2|12.00|13.00|Banenzwemmen|Z
    2|07.00|08.30|Banenzwemmen|O
    2|12.00|13.00|Banenzwemmen|O
    2|11.15|11.45|AquaVitaal|O
    2|10.30|11.00|AquaVitaal in diep water|O
    2|18.00|20.30|Vrijzwemmen alle leeftijden|B
    2|13.00|13.45|AquaRunning|B
    2|13.45|14.30|AquaRunning|B
    2|14.30|15.00|AquaVitaal|B
    2|15.00|15.30|AquaVitaal|B
    2|09.00|12.00|Vrijzwemmen 50+|B
    2|09.00|12.00|Vrijzwemmen gezinnen en 20+|B
    2|12.00|13.00|Banenzwemmen|B
    2|16.00|18.00|Banenzwemmen|B
    2|20.45|22.00|Banenzwemmen|B
    2|10.45|11.15|Teddybeerzwemmen voor 3 t/m 4 jaar|H
    2|10.00|10.30|Teddybeerzwemmen voor 1,5 tot en met 3 jaar|H
    2|20.00|20.45|Verbeter je zwemslag|P
    2|19.00|19.45|Aquarobic|P
    2|18.30|21.45|Vrijzwemmen gezinnen en 20+|P
    2|15.30|17.00|Banenzwemmen|P
    2|19.30|21.45|Banenzwemmen|P
    2|10.00|13.00|Banenzwemmen|P
    2|07.00|08.30|Banenzwemmen|H
    2|12.00|13.00|Banenzwemmen|H
    2|13.00|17.00|Vrijzwemmen alle leeftijden|H
    2|18.30|21.30|Vrijzwemmen alle leeftijden|H
    2|09.00|12.00|Vrijzwemmen gezinnen en 20+|H
    2|09.15|09.45|Teddybeerzwemmen voor 3 maanden tot 1,5 jaar|H
    2|07.00|08.15|Banenzwemmen|W
    2|12.00|13.00|Banenzwemmen|W
    2|14.45|15.15|AquaVitaal|W
    2|15.20|15.50|AquaVitaal|W
    3|08.30|09.00|AquaVitaal|P
    3|09.15|09.45|AquaVitaal|P
    3|10.00|10.30|AquaVitaal|P
    3|10.45|11.15|AquaVitaal|P
    3|11.30|12.00|AquaVitaal|P
    3|12.00|16.00|Vrijzwemmen alle leeftijden|P
    3|12.00|13.00|Banenzwemmen|P
    3|07.00|09.00|Banenzwemmen|P
    3|20.45|21.30|Verbeter je zwemslag|W
    3|09.00|12.00|Banenzwemmen|H
    3|20.30|22.00|Banenzwemmen|H
    3|12.00|17.00|Vrijzwemmen alle leeftijden|H
    3|18.30|21.00|Vrijzwemmen alle leeftijden|H
    3|19.00|20.30|Vrijzwemmen alle leeftijden|H
    3|09.00|12.00|Vrijzwemmen gezinnen en 20+|H
    3|19.45|20.30|AquaRunning|H
    3|09.15|09.45|AquaVitaal|H
    3|10.00|10.30|AquaVitaal|H
    3|10.45|11.15|AquaVitaal|H
    3|11.30|12.00|AquaVitaal|H
    3|18.45|19.30|Aquarobic|H
    3|19.00|20.30|Vrijzwemmen alle leeftijden|W
    3|16.00|18.00|Banenzwemmen|W
    3|20.30|22.15|Banenzwemmen|W
    3|12.00|12.30|AquaVitaal|W
    3|15.30|16.45|Vrijzwemmen alle leeftijden|Z
    3|07.00|08.30|Banenzwemmen|Z
    3|07.00|08.30|Banenzwemmen|O
    3|12.00|13.00|Banenzwemmen|O
    3|13.00|16.00|Banenzwemmen|O
    3|13.00|17.00|Vrijzwemmen alle leeftijden|O
    3|09.45|10.15|Teddybeerzwemmen van 1,5 tot 3 jaar|B
    3|10.15|10.45|Teddybeerzwemmen van 3 t/m 4 jaar|B
    3|09.15|09.45|Teddybeerzwemmen van 3 maanden tot 1,5 jaar|B
    3|12.00|13.00|Banenzwemmen|B
    3|07.00|10.30|Banenzwemmen|B
    3|20.00|20.45|Aquarobic|W
    3|14.30|17.00|Vrijzwemmen alle leeftijden|O
    4|10.45|11.15|Teddybeerzwemmen voor 3 t/m 4 jaar|H
    4|10.00|10.30|Teddybeerzwemmen voor 1,5 tot en met 3 jaar|H
    4|08.45|09.15|Teddybeerzwemmen 1,5 tot 3 jaar|Z
    4|09.30|10.00|Teddybeerzwemmen 3 tot en met 4 jaar|Z
    4|08.30|09.00|AquaVitaal|P
    4|10.15|10.45|AquaVitaal|P
    4|10.00|15.00|Vrijzwemmen gezinnen en 20+|P
    4|15.30|17.00|Banenzwemmen|P
    4|10.00|13.00|Banenzwemmen|P
    4|09.30|10.00|Teddybeerzwemmen voor 3 maanden tot 1,5 jaar|P
    4|11.00|11.30|Teddybeerzwemmen voor 3 t/m 4 jaar|P
    4|10.15|10.45|Teddybeerzwemmen voor 1,5 tot 3 jaar|P
    4|11.30|13.00|Banenzwemmen|H
    4|07.00|08.30|Banenzwemmen|H
    4|13.00|16.00|Vrijzwemmen alle leeftijden|H
    4|09.00|12.00|Vrijzwemmen gezinnen en 20+|H
    4|09.15|09.45|Teddybeerzwemmen voor 3 maanden tot 1,5 jaar|H
    4|07.00|08.15|Banenzwemmen|W
    4|12.00|13.00|Banenzwemmen|W
    4|14.45|15.15|AquaVitaal|W
    4|15.20|15.50|AquaVitaal|W
    4|19.00|22.00|Vrijzwemmen 20+|Z
    4|12.00|13.00|Banenzwemmen|Z
    4|08.45|10.00|Banenzwemmen|Z
    4|10.45|11.15|Teddybeerzwemmen voor 3 t/m 4 jaar|O
    4|07.00|08.30|Banenzwemmen|O
    4|12.00|13.00|Banenzwemmen|O
    4|19.30|21.30|Banenzwemmen|O
    4|09.15|09.45|Teddybeerzwemmen voor 3 maanden tot 1,5 jaar|O
    4|10.00|10.30|Teddybeerzwemmen voor 1,5 tot 3 jaar|O
    4|14.15|15.00|Zwangerschapszwemmen|O
    4|20.00|20.45|Verbeter je zwemslag|O
    4|20.45|21.30|Verbeter je zwemslag|O
    4|19.00|19.45|Aquarobic|O
    4|10.15|10.45|AquaVitaal|O
    4|11.00|11.30|AquaVitaal|O
    4|13.30|14.00|AquaVitaal|O
    4|09.30|10.00|AquaVitaal in diep water|O
    4|09.00|12.00|Vrijzwemmen 50+|O
    4|13.00|15.30|Vrijzwemmen gezinnen en 20+|O
    4|19.30|21.30|Vrijzwemmen alle leeftijden|O
    4|07.00|08.30|Banenzwemmen|B
    4|11.30|13.00|Banenzwemmen|B
    5|12.00|13.00|Banenzwemmen|Z
    5|07.00|08.30|Banenzwemmen|Z
    5|10.45|11.15|Teddybeerzwemmen voor 3 t/m 4 jaar|O
    5|11.15|11.45|Teddybeerzwemmen voor 3 t/m 4 jaar|O
    5|07.00|08.30|Banenzwemmen|O
    5|09.15|09.45|Teddybeerzwemmen voor 3 maanden tot 1,5 jaar|O
    5|10.00|10.30|Teddybeerzwemmen voor 1,5 tot 3 jaar|O
    5|09.00|12.00|Vrijzwemmen gezinnen en 20+|O
    5|12.00|13.00|Banenzwemmen|B
    5|07.00|08.30|Banenzwemmen|B
    5|09.00|17.00|Vrijzwemmen gezinnen en 20+|P
    5|18.30|22.00|Vrijzwemmen gezinnen en 20+|P
    5|12.00|13.00|Banenzwemmen|P
    5|15.30|17.00|Banenzwemmen|P
    5|07.00|09.00|Banenzwemmen|P
    5|19.30|22.00|Banenzwemmen|P
    5|11.30|13.00|Banenzwemmen|H
    5|13.00|15.00|Vrijzwemmen alle leeftijden|H
    5|07.00|08.15|Banenzwemmen|W
    5|12.00|13.00|Banenzwemmen|W
    5|14.45|15.15|AquaVitaal|W
    5|15.20|15.50|AquaVitaal|W
    6|09.30|10.30|Banenzwemmen|B
    6|10.00|13.00|Vrijzwemmen gezinnen en 20+|P
    6|14.00|16.00|Vrijzwemmen alle leeftijden|P
    6|08.30|09.45|Banenzwemmen|P
    6|09.30|11.00|Banenzwemmen|H
    6|13.00|16.00|Vrijzwemmen alle leeftijden|H
    6|09.30|13.00|Vrijzwemmen gezinnen en 20+|H
    6|11.00|12.30|Vrijzwemmen gezinnen en 20+|H
    6|08.00|09.30|Banenzwemmen|W
    6|10.00|14.00|Vrijzwemmen alle leeftijden|O
    6|08.00|09.15|Naturistenzwemmen|O
    0|14.00|16.00|Vrijzwemmen alle leeftijden|Z
    0|08.00|09.30|Banenzwemmen|O
    0|08.00|09.30|Vrijzwemmen gezinnen en 20+|O
    0|09.30|14.00|Vrijzwemmen alle leeftijden|O
    0|12.30|15.00|Vrijzwemmen alle leeftijden|B
    0|09.30|10.30|Vrijzwemmen gezinnen en 20+|B
    0|10.30|12.30|Vrijzwemmen gezinnen en 20+|B
    0|09.30|10.30|Banenzwemmen|B
    0|08.30|16.00|Vrijzwemmen gezinnen en 20+|P
    0|08.30|11.45|Banenzwemmen|P
    0|09.30|11.30|Banenzwemmen|H
    0|13.00|16.00|Vrijzwemmen alle leeftijden|H
    0|09.30|13.00|Vrijzwemmen gezinnen en 20+|H
    0|11.30|12.30|Vrijzwemmen gezinnen en 20+|H
    0|09.30|13.00|Vrijzwemmen alle leeftijden|W
    0|08.00|09.30|Banenzwemmen|W
    """
}
