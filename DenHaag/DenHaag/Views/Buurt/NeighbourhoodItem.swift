import SwiftUI
import CoreLocation

/// Een gebeurtenis in de buurt: evenement, werkzaamheden of een
/// participatieproject waar je kunt meedenken.
struct NeighbourhoodItem: Identifiable, Equatable, Hashable {
    let id = UUID()
    let type: ItemType
    let title: String
    let subtitle: String
    /// Langere omschrijving voor de detailpagina.
    let detailText: String
    let dateRange: String
    let location: String
    let day: String
    let month: String
    let imageName: String
    let latitude: Double
    let longitude: Double
    /// Onderwerp waarop in de onboarding ("Wat wil je volgen over je buurt?")
    /// gefilterd wordt — id's komen overeen met de buurt-voorkeuren-chips.
    let topic: String
    /// Alternatief tijdens werkzaamheden (omleiding/alternatieve route e.d.).
    var alternatief: String? = nil
    /// Gezet bij een vaste plek (fietsenstalling of koffieplek). Zo'n item krijgt
    /// een eigen kaartje (`PlekCardView`) en heeft geen detailpagina.
    var plek: KaartPlek? = nil

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    enum ItemType {
        case evenement
        case werkzaamheden
        case denkMee
        case stalling
        case koffie

        var systemIcon: String {
            switch self {
            case .evenement: return "calendar"
            case .werkzaamheden: return "exclamationmark.triangle.fill"
            case .denkMee: return "bubble.left.and.bubble.right.fill"
            case .stalling: return "bicycle"
            case .koffie: return "cup.and.saucer.fill"
            }
        }

        /// Eigen lijn-icoon (asset uit assets/icons) voor de kaart-pins. Een naam
        /// met "sf:"-prefix is een SF Symbol (er is nog geen eigen icoon voor).
        var markerIcon: String {
            switch self {
            case .evenement: return "calendar"
            case .werkzaamheden: return "alert"
            case .denkMee: return "chat"
            case .stalling: return "sf:bicycle"
            case .koffie: return "sf:cup.and.saucer.fill"
            }
        }

        /// Vertaalsleutel voor het type-label op de detailpagina.
        var labelKey: String {
            switch self {
            case .evenement: return "buurt_type_event"
            case .werkzaamheden: return "buurt_type_works"
            case .denkMee: return "buurt_type_denkmee"
            case .stalling: return "fiets_parkeren_title"
            case .koffie: return "fiets_koffie_title"
            }
        }
    }

    static func == (lhs: NeighbourhoodItem, rhs: NeighbourhoodItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    /// Vaste plekken als buurt-items, dichtstbijzijnde (vanaf thuis) eerst.
    private static func plekItems(_ plekken: [KaartPlek], type: ItemType, topic: String) -> [NeighbourhoodItem] {
        let home = CLLocation(latitude: BuurtView.thuisCoord.latitude, longitude: BuurtView.thuisCoord.longitude)
        return plekken
            .sorted {
                CLLocation(latitude: $0.latitude, longitude: $0.longitude).distance(from: home)
                    < CLLocation(latitude: $1.latitude, longitude: $1.longitude).distance(from: home)
            }
            .map {
                NeighbourhoodItem(type: type, title: $0.title, subtitle: "", detailText: "",
                                  dateRange: "", location: $0.address, day: "", month: "",
                                  imageName: $0.imageName, latitude: $0.latitude, longitude: $0.longitude,
                                  topic: topic, plek: $0)
            }
    }

    static let stallingen = plekItems(KaartPlek.stallingen, type: .stalling, topic: "fietsparkeren")
    static let koffieplekken = plekItems(KaartPlek.koffieplekken, type: .koffie, topic: "koffie")

    /// Wat er rond Kapsalon Anne (Hoefkade 12) speelt en relevant is voor een
    /// ondernemer: bereikbaarheid, leveringen, meedenken over de winkelstraat.
    /// Alleen zichtbaar in de rol ondernemer (prototype, verzonnen).
    static let voorOndernemer: [NeighbourhoodItem] = [
        NeighbourhoodItem(
            type: .werkzaamheden,
            title: "Hoefkade: je zaak blijft bereikbaar",
            subtitle: "Riool vervangen in fases. Laden en lossen via de Marktweg.",
            detailText: "Op de Hoefkade vervangen we het riool. We werken in fases van ongeveer twee weken, zodat steeds maar een deel van de straat dicht is. Je zaak blijft voor klanten te voet bereikbaar. Leveranciers kunnen laden en lossen in de Marktweg. Een week voor elke fase krijg je een bericht met de planning, zodat je leveringen en afspraken kunt aanpassen.",
            dateRange: "16 nov - 18 dec",
            location: "Hoefkade",
            day: "16", month: "nov",
            imageName: "foto-riool",
            latitude: 52.0623, longitude: 4.3005,
            topic: "ondernemen",
            alternatief: "Leveranciers laden en lossen in de Marktweg. Klanten kunnen je zaak te voet blijven bereiken."
        ),
        NeighbourhoodItem(
            type: .evenement,
            title: "Ondernemersavond Hoefkade",
            subtitle: "Praat mee met andere ondernemers en de wijkmanager.",
            detailText: "Twee keer per jaar praten ondernemers uit de straat met de wijkmanager van de gemeente. Deze keer over de werkzaamheden, veiligheid in de avond en de feestverlichting in december. Je hoeft je niet aan te melden. Er is koffie en wat te eten.",
            dateRange: "26 nov · 19.30 uur",
            location: "Buurthuis om de hoek",
            day: "26", month: "nov",
            imageName: "foto-buurtborrel",
            latitude: 52.0610, longitude: 4.3016,
            topic: "ondernemen"
        ),
        NeighbourhoodItem(
            type: .denkMee,
            title: "Laad- en losplekken in je straat",
            subtitle: "Waar heb jij een losplek nodig voor leveringen?",
            detailText: "De gemeente kijkt opnieuw naar de laad- en losplekken in de winkelstraten rond de Hoefkade. Ondernemers weten het best waar leveranciers stoppen en waar dat nu misgaat. Geef op de kaart aan waar jij een losplek nodig hebt en op welke tijden.",
            dateRange: "Reageren t/m 12 dec",
            location: "Winkelstraten Hoefkade",
            day: "12", month: "dec",
            imageName: "foto-herbestrating",
            latitude: 52.0629, longitude: 4.2978,
            topic: "ondernemen"
        ),
        NeighbourhoodItem(
            type: .evenement,
            title: "Marktdagen: meer mensen in de straat",
            subtitle: "Op marktdagen lopen er meer mensen langs je zaak.",
            detailText: "Op marktdagen is het druk rond de Haagse Markt en lopen er meer mensen door de straten eromheen. Parkeerplekken zijn dan snel vol. Wijs klanten met een afspraak op de fietsenstalling en het openbaar vervoer.",
            dateRange: "Ma, wo, vr en za",
            location: "Haagse Markt",
            day: "4", month: "nov",
            imageName: "foto-markt",
            latitude: 52.0644, longitude: 4.2993,
            topic: "ondernemen"
        ),
        NeighbourhoodItem(
            type: .werkzaamheden,
            title: "Nieuwe fietsenrekken voor de deur",
            subtitle: "Plaatsing in week 48. De stoep is dan een dag smaller.",
            detailText: "Voor de winkels op de Hoefkade komen extra fietsenrekken, zodat fietsen niet meer voor de etalages staan. De rekken worden in week 48 geplaatst. Op de dag van plaatsing is de stoep voor je zaak een paar uur smaller.",
            dateRange: "Week 48",
            location: "Hoefkade 2-20",
            day: "23", month: "nov",
            imageName: "foto-spui",
            latitude: 52.0614, longitude: 4.2985,
            topic: "ondernemen"
        ),
    ]

    /// Dummy-data rondom Den Haag (prototype). De eerste vijf staan vlak rondom
    /// het thuisadres (±150 m), één per onderwerp — zo zie je het concept meteen.
    static let sample: [NeighbourhoodItem] = [
        NeighbourhoodItem(
            type: .evenement,
            title: "Buurtborrel op het plein",
            subtitle: "Maak kennis met je buren onder het genot van een hapje.",
            detailText: "Kom langs op het pleintje om de hoek voor een gezellige buurtborrel. Er zijn hapjes, drankjes en muziek. Een mooie kans om je directe buren beter te leren kennen. Aanmelden hoeft niet, loop gewoon binnen.",
            dateRange: "14 jun",
            location: "Pleintje om de hoek",
            day: "14", month: "jun",
            imageName: "foto-buurtborrel",
            latitude: 52.0712, longitude: 4.3001,
            topic: "evenementen"
        ),
        NeighbourhoodItem(
            type: .evenement,
            title: "Bootcamp in het buurtpark",
            subtitle: "Gratis buitentraining voor alle niveaus.",
            detailText: "Elke zaterdagochtend kun je gratis meedoen met een bootcamp in het buurtpark. Een ervaren trainer past de oefeningen aan op jouw niveau. Neem sportkleding en wat te drinken mee.",
            dateRange: "Elke zaterdag",
            location: "Buurtpark",
            day: "15", month: "jun",
            imageName: "foto-bootcamp",
            latitude: 52.0700, longitude: 4.3019,
            topic: "sport"
        ),
        NeighbourhoodItem(
            type: .werkzaamheden,
            title: "Asfalt vervangen in je straat",
            subtitle: "Korte werkzaamheden, hou rekening met geluid.",
            detailText: "In jouw straat wordt het asfalt vervangen. De straat is overdag deels afgesloten voor doorgaand verkeer. Woningen blijven te voet bereikbaar. De werkzaamheden duren een paar dagen.",
            dateRange: "10 jun - 14 jun",
            location: "Jouw straat",
            day: "10", month: "jun",
            imageName: "foto-asfalt",
            latitude: 52.0699, longitude: 4.2998,
            topic: "wegwerk",
            alternatief: "Parkeren kan deze dagen in de aangrenzende straat."
        ),
        NeighbourhoodItem(
            type: .denkMee,
            title: "Nieuw buurthuis om de hoek",
            subtitle: "Denk mee over de plannen voor het nieuwe buurthuis.",
            detailText: "Op de hoek van je straat komt mogelijk een nieuw buurthuis. De gemeente wil graag weten wat bewoners belangrijk vinden: ruimte voor activiteiten, een buurtcafé of juist plek voor de jeugd? Deel je ideeën.",
            dateRange: "Reageren t/m 20 jun",
            location: "Hoek van je straat",
            day: "20", month: "jun",
            imageName: "foto-buurthuis",
            latitude: 52.0714, longitude: 4.3014,
            topic: "bouwplannen"
        ),
        NeighbourhoodItem(
            type: .denkMee,
            title: "Meer groen in je straat?",
            subtitle: "Waar zou jij een geveltuintje of boom willen?",
            detailText: "De gemeente wil je straat vergroenen met geveltuintjes, plantenbakken en bomen. Op een digitale kaart kun je aangeven waar jij meer groen zou willen. De meest gekozen plekken nemen we mee in het plan.",
            dateRange: "Reageren t/m 18 jun",
            location: "Jouw straat",
            day: "18", month: "jun",
            imageName: "foto-groen",
            latitude: 52.0701, longitude: 4.3022,
            topic: "participatie"
        ),
        NeighbourhoodItem(
            type: .evenement,
            title: "Beach Cleanup",
            subtitle: "Samen werken aan een schoner strand.",
            detailText: "Help mee om het strand van Scheveningen schoon te maken. We starten bij de Pier en lopen samen richting het Zwarte Pad. Handschoenen, grijpers en vuilniszakken worden door de gemeente verzorgd. Na afloop is er warme chocolademelk. Iedereen is welkom, je hoeft je niet vooraf aan te melden.",
            dateRange: "12 jan - 8 feb",
            location: "Scheveningen Bad",
            day: "12", month: "jan",
            imageName: "foto-beachcleanup",
            latitude: 52.0735, longitude: 4.2975,
            topic: "evenementen"
        ),
        NeighbourhoodItem(
            type: .werkzaamheden,
            title: "Werkzaamheden Hoefkade",
            subtitle: "Vervangen van het riool, hou rekening met omleidingen.",
            detailText: "Op de Hoefkade vervangen we het oude riool. Tijdens de werkzaamheden is de straat deels afgesloten voor doorgaand verkeer en gelden er omleidingen. Woningen en winkels blijven te voet bereikbaar. De werkzaamheden worden in fases uitgevoerd om de overlast te beperken.",
            dateRange: "15 jan - 28 feb",
            location: "Hoefkade",
            day: "15", month: "jan",
            imageName: "foto-riool",
            latitude: 52.0685, longitude: 4.3050,
            topic: "wegwerk",
            alternatief: "Doorgaand verkeer wordt omgeleid via de Vaillantlaan. Fietsers en voetgangers kunnen er langs."
        ),
        NeighbourhoodItem(
            type: .denkMee,
            title: "Herinrichting Grote Markt",
            subtitle: "Denk mee over het nieuwe ontwerp van het plein.",
            detailText: "De Grote Markt krijgt een nieuwe inrichting met meer groen, ruimte voor terrassen en betere fietsenstallingen. De gemeente wil graag weten wat bewoners en ondernemers belangrijk vinden. Tijdens een online inspraakronde kun je reageren op drie ontwerpvarianten en je eigen ideeën aandragen.",
            dateRange: "Reageren t/m 1 mrt",
            location: "Grote Markt",
            day: "1", month: "mrt",
            imageName: "foto-plein",
            latitude: 52.0728, longitude: 4.3038,
            topic: "bouwplannen"
        ),
        NeighbourhoodItem(
            type: .evenement,
            title: "Rondleiding Binnenhof",
            subtitle: "Ontdek de geschiedenis van het Binnenhof.",
            detailText: "Een gids neemt je mee langs de mooiste plekken van het Binnenhof en vertelt over de rijke geschiedenis van deze plek. De rondleiding duurt ongeveer anderhalf uur en eindigt bij de Hofvijver. Plaatsen zijn beperkt, dus wees er op tijd bij.",
            dateRange: "20 jan",
            location: "Binnenhof",
            day: "20", month: "jan",
            imageName: "binnenhof",
            latitude: 52.0745, longitude: 4.3018,
            topic: "evenementen"
        ),
        NeighbourhoodItem(
            type: .denkMee,
            title: "Groenplan Zeeheldenkwartier",
            subtitle: "Waar moeten nieuwe bomen en perken komen?",
            detailText: "Het Zeeheldenkwartier wordt groener. De gemeente plant samen met bewoners nieuwe bomen, geveltuintjes en plantenbakken. Op een digitale kaart kun je aangeven waar jij meer groen zou willen zien. De meest gekozen plekken nemen we mee in het definitieve plan.",
            dateRange: "Reageren t/m 15 feb",
            location: "Zeeheldenkwartier",
            day: "15", month: "feb",
            imageName: "foto-vergroening",
            latitude: 52.0752, longitude: 4.2968,
            topic: "participatie"
        ),
        NeighbourhoodItem(
            type: .werkzaamheden,
            title: "Renovatie speeltuin",
            subtitle: "De speeltuin krijgt nieuwe toestellen.",
            detailText: "De speeltuin in het Transvaalkwartier wordt opgeknapt met nieuwe, veilige speeltoestellen en een zachtere ondergrond. Tijdens de werkzaamheden is de speeltuin afgesloten. We verwachten dat kinderen er begin maart weer terecht kunnen.",
            dateRange: "1 feb - 1 mrt",
            location: "Transvaalkwartier",
            day: "1", month: "feb",
            imageName: "foto-speeltuin",
            latitude: 52.0680, longitude: 4.2980,
            topic: "bouwplannen",
            alternatief: "De speeltuin aan de Schalk Burgerstraat blijft tijdens de renovatie gewoon open."
        ),
        NeighbourhoodItem(
            type: .evenement,
            title: "Haagse Markt Feestweek",
            subtitle: "Een week vol muziek, eten en gezelligheid.",
            detailText: "De Haagse Markt viert feest met een week vol live muziek, internationale gerechten en activiteiten voor jong en oud. Ontdek de smaken van de stad en geniet van optredens op het centrale podium. De toegang is gratis.",
            dateRange: "5 feb - 12 feb",
            location: "Haagse Markt",
            day: "5", month: "feb",
            imageName: "foto-markt",
            latitude: 52.0668, longitude: 4.3052,
            topic: "evenementen"
        ),
        NeighbourhoodItem(
            type: .werkzaamheden,
            title: "Herbestrating Denneweg",
            subtitle: "Nieuwe klinkers en bredere stoepen.",
            detailText: "De Denneweg krijgt nieuwe klinkers en bredere, beter toegankelijke stoepen. Tijdens de werkzaamheden blijven de winkels open en bereikbaar. Parkeren is tijdelijk niet mogelijk in het werkvak; gebruik de parkeergarage in de buurt.",
            dateRange: "10 feb - 20 mrt",
            location: "Denneweg",
            day: "10", month: "feb",
            imageName: "foto-herbestrating",
            latitude: 52.0738, longitude: 4.3058,
            topic: "wegwerk",
            alternatief: "Parkeren kan tijdelijk in de parkeergarage Museumkwartier, op 5 min. loopafstand."
        ),
        NeighbourhoodItem(
            type: .evenement,
            title: "Winterfair Lange Voorhout",
            subtitle: "Sfeervolle kraampjes onder de bomen.",
            detailText: "Op het Lange Voorhout vind je een sfeervolle winterfair met kraampjes vol ambachtelijke producten, warme hapjes en cadeautjes. Een perfecte plek om rond te struinen en de winter te vieren in het hart van de stad.",
            dateRange: "8 feb - 9 feb",
            location: "Lange Voorhout",
            day: "8", month: "feb",
            imageName: "foto-markt",
            latitude: 52.0752, longitude: 4.3032,
            topic: "evenementen"
        ),
        NeighbourhoodItem(
            type: .denkMee,
            title: "Toekomst van de Bibliotheek",
            subtitle: "Praat mee over de nieuwe stadsbibliotheek.",
            detailText: "De centrale bibliotheek aan het Spui wordt vernieuwd. We willen een plek maken die past bij de wensen van de stad: meer studieplekken, ruimte voor ontmoeting of juist een groot kinderdeel? Deel je ideeën tijdens de inspraakavond of via het online formulier.",
            dateRange: "Reageren t/m 28 feb",
            location: "Spui",
            day: "28", month: "feb",
            imageName: "foto-spui",
            latitude: 52.0715, longitude: 4.3062,
            topic: "participatie"
        ),
        NeighbourhoodItem(
            type: .evenement,
            title: "Zuiderpark Wandeling",
            subtitle: "Een rustige natuurwandeling met een gids.",
            detailText: "Ontdek de verborgen plekjes van het Zuiderpark tijdens een begeleide wandeling. De gids vertelt over de planten, dieren en de geschiedenis van dit groene hart van de stad. Geschikt voor alle leeftijden.",
            dateRange: "22 feb",
            location: "Zuiderpark",
            day: "22", month: "feb",
            imageName: "foto-park",
            latitude: 52.0665, longitude: 4.2992,
            topic: "sport"
        ),
    ]
}
