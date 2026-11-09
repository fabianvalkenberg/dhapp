import SwiftUI

// MARK: - Afspraak

/// De ene afspraak in het prototype (paspoort, Spui). Kaart op home en het
/// afspraakscherm lezen allebei hieruit, zodat verplaatsen en afzeggen overal
/// doorwerken. Bewust niet bewaard: elke start begint met dezelfde afspraak.
final class AfspraakStore: ObservableObject {
    @Published var datum: Date
    @Published var afgezegd = false

    init() {
        datum = AfspraakStore.opTijd(dagenVanaf: 7, uur: 9, minuut: 0)
    }

    /// Een moment over een aantal dagen, op een vaste tijd; weekend schuift door naar maandag.
    static func opTijd(dagenVanaf dagen: Int, uur: Int, minuut: Int) -> Date {
        let cal = Calendar.current
        var dag = cal.date(byAdding: .day, value: dagen, to: Date()) ?? Date()
        while cal.isDateInWeekend(dag) { dag = cal.date(byAdding: .day, value: 1, to: dag) ?? dag }
        return cal.date(bySettingHour: uur, minute: minuut, second: 0, of: dag) ?? dag
    }

    /// Vrije momenten om naar te verplaatsen (verzonnen).
    var vrijeMomenten: [Date] {
        [(2, 9, 15), (2, 13, 30), (3, 10, 45), (5, 8, 30), (5, 15, 0), (8, 11, 15)]
            .map { AfspraakStore.opTijd(dagenVanaf: $0.0, uur: $0.1, minuut: $0.2) }
            .filter { abs($0.timeIntervalSince(datum)) > 60 }
    }

    private static let nl = Locale(identifier: "nl_NL")

    /// "dinsdag 10 november"
    static func dag(_ d: Date) -> String {
        let f = DateFormatter(); f.locale = nl; f.dateFormat = "EEEE d MMMM"
        return f.string(from: d)
    }
    /// "09:00"
    static func tijd(_ d: Date) -> String {
        let f = DateFormatter(); f.locale = nl; f.dateFormat = "HH:mm"
        return f.string(from: d)
    }
    /// "10 nov om 09:00"
    static func kort(_ d: Date) -> String {
        let f = DateFormatter(); f.locale = nl; f.dateFormat = "d MMM"
        return "\(f.string(from: d).replacingOccurrences(of: ".", with: "")) om \(tijd(d))"
    }
}

// MARK: - Berichten (notificaties)

/// Waar een bericht over gaat. Hangt aan een onderdeel van de app, zodat een
/// versie alleen berichten toont over wat er in zit.
enum BerichtOnderwerp: String, CaseIterable, Identifiable {
    case afspraken, meldingen, parkeren, zwemmen, afval

    var id: String { rawValue }
    var labelKey: String { "bericht_onderwerp_\(rawValue)" }
    var icoon: String {
        switch self {
        case .afspraken: return "calendar"
        case .meldingen: return "exclamationmark.bubble"
        case .parkeren:  return "car"
        case .zwemmen:   return "figure.pool.swim"
        case .afval:     return "trash"
        }
    }
    var onderdeel: Onderdeel {
        switch self {
        case .afspraken: return .afspraken
        case .meldingen: return .melden
        case .parkeren:  return .parkeren
        case .zwemmen:   return .zwemmen
        case .afval:     return .afval
        }
    }
}

struct Bericht: Identifiable, Equatable {
    let id = UUID()
    let onderwerp: BerichtOnderwerp
    let titel: String
    let tekst: String
    let wanneer: String
    var gelezen = false
}

/// Berichten in de app plus de voorkeuren per onderwerp. Een nieuw bericht kan
/// ook als nagebootste pushmelding bovenin verschijnen.
final class BerichtenStore: ObservableObject {
    @Published var berichten: [Bericht]
    @Published var push: Bericht?
    @Published var aan: [BerichtOnderwerp: Bool] {
        didSet {
            UserDefaults.standard.set(Dictionary(uniqueKeysWithValues: aan.map { ($0.key.rawValue, $0.value) }),
                                      forKey: "berichtVoorkeuren")
        }
    }

    init() {
        let opgeslagen = UserDefaults.standard.dictionary(forKey: "berichtVoorkeuren") as? [String: Bool] ?? [:]
        aan = Dictionary(uniqueKeysWithValues: BerichtOnderwerp.allCases.map { ($0, opgeslagen[$0.rawValue] ?? true) })
        berichten = [
            Bericht(onderwerp: .parkeren, titel: "Bezoek parkeert nog 15 minuten",
                    tekst: "Het parkeren voor 23-BTV-6 stopt om 21:00.", wanneer: "Vandaag"),
            Bericht(onderwerp: .afspraken, titel: "Herinnering: je afspraak",
                    tekst: "Neem je oude paspoort en een pasfoto mee naar het Spui.", wanneer: "Gisteren"),
            Bericht(onderwerp: .meldingen, titel: "Je melding is opgelost",
                    tekst: "De losse stoeptegel bij jou in de straat is gerepareerd. Dank je wel!", wanneer: "2 dagen geleden", gelezen: true),
            Bericht(onderwerp: .zwemmen, titel: "Nieuw zwemrooster",
                    tekst: "Het rooster van het Zuiderparkbad voor de komende maand staat in de app.", wanneer: "4 dagen geleden", gelezen: true),
            Bericht(onderwerp: .afval, titel: "Morgen wordt je papier opgehaald",
                    tekst: "Zet de container vóór 07:30 aan de straat.", wanneer: "5 dagen geleden", gelezen: true),
        ]
    }

    func zichtbaar(in versie: AppVersie) -> [Bericht] {
        berichten.filter { versie.heeft($0.onderwerp.onderdeel) }
    }

    func ongelezen(in versie: AppVersie) -> Int {
        zichtbaar(in: versie).filter { !$0.gelezen }.count
    }

    func markeerGelezen(_ id: UUID) {
        guard let i = berichten.firstIndex(where: { $0.id == id }) else { return }
        berichten[i].gelezen = true
    }

    /// Nieuw bericht bovenaan; als het onderwerp aan staat ook als pushmelding.
    func stuur(_ onderwerp: BerichtOnderwerp, titel: String, tekst: String, na vertraging: TimeInterval = 0) {
        DispatchQueue.main.asyncAfter(deadline: .now() + vertraging) {
            let bericht = Bericht(onderwerp: onderwerp, titel: titel, tekst: tekst, wanneer: "Zojuist")
            self.berichten.insert(bericht, at: 0)
            if self.aan[onderwerp] ?? true {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { self.push = bericht }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                    if self.push?.id == bericht.id {
                        withAnimation(.easeInOut(duration: 0.3)) { self.push = nil }
                    }
                }
            }
        }
    }
}

// MARK: - Rol: inwoner of ondernemer

/// Gebruik je de app als inwoner of als ondernemer? Een demo-schakelaar in het
/// profielmenu. Als ondernemer krijgen dezelfde onderdelen een zakelijke kant.
final class RolManager: ObservableObject {
    enum Rol: String { case inwoner, ondernemer }

    @Published var rol: Rol {
        didSet {
            UserDefaults.standard.set(rol.rawValue, forKey: "rol")
            AnalyticsService.track("switch_rol", ["rol": rol.rawValue])
        }
    }

    var isOndernemer: Bool { rol == .ondernemer }

    init() {
        rol = Rol(rawValue: UserDefaults.standard.string(forKey: "rol") ?? "") ?? .inwoner
    }

    func wissel() { rol = isOndernemer ? .inwoner : .ondernemer }
}

extension String {
    /// Alleen de eerste letter groot: "dinsdag 10 november" → "Dinsdag 10 november".
    var eersteHoofdletter: String { prefix(1).uppercased() + dropFirst() }
}

// MARK: - Laatste melding

/// Je laatste melding openbare ruimte en hoe ver die is. Start met een
/// voorbeeldmelding; een nieuwe melding uit de meldflow vervangt hem.
final class MeldingStore: ObservableObject {
    struct Melding: Equatable {
        var wat: String
        var waar: String
        var nummer: String
        var datum: Date
        /// 0 = ontvangen, 1 = in behandeling, 2 = opgelost
        var stap: Int
    }

    @Published var laatste: Melding

    init() {
        laatste = Melding(wat: "Losse of kapotte stoeptegel", waar: "Honselersdijkstraat 8",
                          nummer: "SIG-481207",
                          datum: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
                          stap: 1)
    }

    func nieuw(wat: String, waar: String, nummer: String) {
        laatste = Melding(wat: wat, waar: waar, nummer: nummer, datum: Date(), stap: 0)
    }

    static let stapKeys = ["melding_stap_ontvangen", "melding_stap_behandeling", "melding_stap_opgelost"]
}

// MARK: - Afvalplanning

/// Wanneer welk afval wordt opgehaald, gerekend vanaf vandaag (verzonnen,
/// maar altijd actueel). De afvalkalender en de kaart op home lezen hieruit.
enum AfvalPlanning {
    struct Ophaling: Identifiable {
        let id = UUID()
        let soort: String
        let kortKey: String
        let kleur: Color
        let datum: Date
    }

    static var ophalingen: [Ophaling] {
        let cal = Calendar.current
        func dag(_ n: Int) -> Date { cal.date(byAdding: .day, value: n, to: cal.startOfDay(for: Date())) ?? Date() }
        return [
            Ophaling(soort: "Papier & karton", kortKey: "afval_kort_papier", kleur: AppColors.blauw3, datum: dag(1)),
            Ophaling(soort: "GFT & etensresten", kortKey: "afval_kort_gft", kleur: Color(hex: "5B8C3E"), datum: dag(5)),
            Ophaling(soort: "Plastic, blik & drinkpakken", kortKey: "afval_kort_plastic", kleur: Color(hex: "E59500"), datum: dag(12)),
            Ophaling(soort: "Restafval", kortKey: "afval_kort_rest", kleur: Color(hex: "4B4B4B"), datum: dag(20)),
        ]
    }

    static var eerstvolgende: Ophaling { ophalingen[0] }

    /// "Morgen · vr 6 nov" of "Di 10 nov"
    static func label(_ d: Date) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "nl_NL"); f.dateFormat = "EEE d MMM"
        let tekst = f.string(from: d).replacingOccurrences(of: ".", with: "")
        return Calendar.current.isDateInTomorrow(d) ? "Morgen · \(tekst)" : tekst.eersteHoofdletter
    }
}
