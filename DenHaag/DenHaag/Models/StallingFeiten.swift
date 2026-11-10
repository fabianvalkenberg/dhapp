import Foundation

/// Opgezochte feiten per stalling. Vult `StallingFilter` en de stallingspagina.
///
/// Bronnen (opgezocht 2026-11-10): biesieklette.nl/fiets-stallen en de
/// locatiepagina's (/locaties/<naam>), denhaag.com/nl/biesieklette-<naam>,
/// denhaag.nl "Gratis en bewaakt uw fiets stallen".
/// - Fatbike: Biesieklette heeft één categorie "Fiets & Fatbike".
/// - Bakfiets: onbekend (weggelaten) waar alleen de standaardzin op denhaag.com het noemt.
/// - Voordrager: geen enkele bron noemt het; overal onbekend.
/// - Bewaakt: afgeleid uit de vaste Biesieklette-tekst (beheerder scant bij in- en uitgaan).
/// Ontbreekt een type, dan is het onbekend en valt de stalling buiten dat filter.
enum StallingFeiten {
    static let perStalling: [String: StallingFeit] = [
        "Hobbemaplein": StallingFeit(geschikt: [.fiets: true, .fatbike: true, .bakfiets: true],
                         extraVoorzieningen: ["Elektrisch opladen", "Bewaakt"]),
        "Groenteweg": StallingFeit(geschikt: [.fiets: true, .fatbike: true, .bakfiets: true],
                         extraVoorzieningen: ["Elektrisch opladen", "Bewaakt"]),
        "Grote Markt": StallingFeit(geschikt: [.fiets: true, .fatbike: true, .bakfiets: true],
                         extraVoorzieningen: ["Toilet", "Elektrisch opladen", "Fietspomp", "Bewaakt"]),
        "Driehoekjes": StallingFeit(geschikt: [.fiets: true, .fatbike: true],
                         extraVoorzieningen: ["Elektrisch opladen", "Bewaakt"]),
        "Nobelstraat": StallingFeit(geschikt: [.fiets: true, .fatbike: true, .bakfiets: true],
                         extraVoorzieningen: ["Toilet", "Elektrisch opladen", "Fietspomp", "Bewaakt"]),
        "Buitenhof": StallingFeit(geschikt: [.fiets: true, .fatbike: true, .bakfiets: true],
                         extraVoorzieningen: ["Toilet", "Elektrisch opladen", "Fietspomp", "Bewaakt"]),
        "Noordeinde": StallingFeit(geschikt: [.fiets: true, .fatbike: true],
                         extraVoorzieningen: ["Fietspomp", "Bewaakt"]),
        "Voldersgracht": StallingFeit(geschikt: [.fiets: true, .fatbike: true, .bakfiets: true],
                         extraVoorzieningen: ["Elektrisch opladen", "Fietspomp", "Bewaakt"]),
        "Stadhuis": StallingFeit(geschikt: [.fiets: true, .fatbike: true],
                         extraVoorzieningen: ["Elektrisch opladen", "Fietspomp", "Bewaakt"]),
        "Kranestraat": StallingFeit(geschikt: [.fiets: true, .fatbike: true, .bakfiets: true],
                         extraVoorzieningen: ["Elektrisch opladen", "Fietspomp", "Bewaakt"]),
        "Plein (Korte Poten)": StallingFeit(geschikt: [.fiets: true, .fatbike: true, .bakfiets: true],
                         extraVoorzieningen: ["Elektrisch opladen", "Fietspomp", "Bewaakt"]),
        "Amare": StallingFeit(geschikt: [.fiets: true, .fatbike: true, .bakfiets: true],
                         extraVoorzieningen: ["Fietspomp", "Bewaakt"]),
        "Rijnstraat (Fietsflat)": StallingFeit(geschikt: [.fiets: true, .fatbike: true],
                         extraVoorzieningen: ["Fietspomp", "Bewaakt"]),
        "Anna van Buerenstraat": StallingFeit(geschikt: [.fiets: true, .fatbike: true, .bakfiets: true],
                         extraVoorzieningen: ["Elektrisch opladen", "Fietspomp", "Bewaakt"]),
        "Leyweg": StallingFeit(geschikt: [.fiets: true, .fatbike: true, .bakfiets: true],
                         extraVoorzieningen: ["Elektrisch opladen", "Fietspomp", "Bewaakt"]),
        "Strandweg-Haven": StallingFeit(geschikt: [.fiets: true, .fatbike: true, .bakfiets: true],
                         extraVoorzieningen: ["Toilet", "Toegankelijk toilet", "Elektrisch opladen", "Fietspomp", "Bewaakt"]),
        "Palaceplein": StallingFeit(geschikt: [.fiets: true, .fatbike: true, .bakfiets: true],
                         extraVoorzieningen: ["Elektrisch opladen", "Fietspomp", "Bewaakt"]),
        "Noordboulevard": StallingFeit(geschikt: [.fiets: true, .fatbike: true, .bakfiets: true],
                         extraVoorzieningen: ["Toilet", "Toegankelijk toilet", "Fietspomp", "Bewaakt"]),
        "Kijkduin": StallingFeit(geschikt: [.fiets: true, .fatbike: true, .bakfiets: true],
                         extraVoorzieningen: ["Toilet", "Toegankelijk toilet", "Elektrisch opladen", "Fietspomp", "Bewaakt"]),
    ]
}
