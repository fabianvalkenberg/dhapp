import Foundation

/// Opgezochte feiten per stalling (fietstypen en extra voorzieningen).
/// Bron en datum staan in `StallingFeiten.bron`. nil = niet bekend; zo'n
/// stalling valt dan buiten een filter op dat kenmerk.
struct StallingFeit {
    var geschikt: [FietspasType: Bool] = [:]
    /// Voorzieningen bovenop `KaartPlek.extras` (bijv. "Bewaakt", "Fietspomp").
    var extraVoorzieningen: [String] = []
}

/// Filters voor stallingen (Figma fietsen, flow 01 scherm 6/6b/7).
struct StallingFilter: Equatable {
    enum Open: String, CaseIterable { case alle, nuOpen, dagEnNacht }

    var fietstypen: Set<FietspasType> = []
    var open: Open = .alle
    var voorzieningen: Set<String> = []

    /// De fietstypen in het filter (geen scooter). Alleen types waarvan bij minstens
    /// één stalling bevestigd is dat ze passen; voordrager valt daardoor nu weg.
    static let typen: [FietspasType] = [.fiets, .fatbike, .bakfiets, .voordrager].filter { t in
        StallingFeiten.perStalling.values.contains { $0.geschikt[t] == true }
    }

    var aantalActief: Int {
        fietstypen.count + (open == .alle ? 0 : 1) + voorzieningen.count
    }

    var isLeeg: Bool { aantalActief == 0 }

    /// Alle voorzieningen van een plek: de extra's uit de data plus opgezochte.
    static func voorzieningen(_ plek: KaartPlek) -> [String] {
        let extra = StallingFeiten.perStalling[plek.title]?.extraVoorzieningen ?? []
        var gezien = Set<String>()
        return (plek.extras + extra).filter { gezien.insert($0).inserted }
    }

    /// true/false als bekend, nil als we het niet weten.
    static func geschikt(_ plek: KaartPlek, voor type: FietspasType) -> Bool? {
        StallingFeiten.perStalling[plek.title]?.geschikt[type]
    }

    static func isDagEnNacht(_ plek: KaartPlek) -> Bool {
        plek.hours.allSatisfy { $0 == "00:00 – 24:00" || $0 == "24 uur" }
    }

    func past(_ plek: KaartPlek, nu: Date = Date()) -> Bool {
        // Elk gekozen fietstype moet er zeker in passen.
        for t in fietstypen where Self.geschikt(plek, voor: t) != true { return false }
        switch open {
        case .alle: break
        case .nuOpen: if plek.openTot(nu) == nil && !Self.isDagEnNacht(plek) { return false }
        case .dagEnNacht: if !Self.isDagEnNacht(plek) { return false }
        }
        let heeft = Set(Self.voorzieningen(plek))
        return voorzieningen.isSubset(of: heeft)
    }
}
