import SwiftUI

/// Soort fietspas. De kleur onderaan de pas laat zien voor welk voertuig hij is
/// (Figma: sectie "Verschillende fietskaarten", node 3451:48372).
enum FietspasType: String, CaseIterable, Codable, Identifiable {
    case fiets, bakfiets, scooter, fatbike, voordrager

    var id: String { rawValue }

    /// Naam van het voertuig, zoals onderaan de pas.
    var naamKey: String { "fp_type_\(rawValue)" }
    /// Kleur als woord: "groene pas", "Fiets (groen)".
    var kleurKey: String { "fp_kleur_\(rawValue)" }
    var kleurBijvoeglijkKey: String { "fp_kleur_\(rawValue)_bn" }

    var kleur: Color {
        switch self {
        case .fiets:      return Color(hex: "00913F")
        case .bakfiets:   return Color(hex: "0072BC")
        case .scooter:    return Color(hex: "D6007E")
        case .fatbike:    return Color(hex: "F2C400")
        case .voordrager: return Color(hex: "F08A00")
        }
    }

    var icoon: String { "fp-icon-\(rawValue)" }
    /// Breedte van het voertuig-icoon bij hoogte 36 (bakfiets is breder).
    var icoonBreedte: CGFloat { self == .bakfiets ? 64 : 56 }
}

/// Eén fietspas in de app. Prototype: de code is verzonnen.
struct Fietspas: Identifiable, Codable, Equatable {
    var id = UUID()
    var type: FietspasType
    var code: String
    var bijnaam: String
    var favoriet = false
}

/// Bewaart de fietspassen tussen sessies. Start leeg: eerst een pas scannen.
final class FietspasStore: ObservableObject {
    static let key = "fietspassen"

    @Published private(set) var passen: [Fietspas] {
        didSet { bewaar() }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let opgeslagen = try? JSONDecoder().decode([Fietspas].self, from: data) {
            passen = opgeslagen
        } else {
            passen = []
        }
    }

    /// De favoriet staat vooraan (Figma C5), daarna in volgorde van toevoegen.
    var gesorteerd: [Fietspas] {
        passen.filter(\.favoriet) + passen.filter { !$0.favoriet }
    }

    func voegToe(_ pas: Fietspas) { passen.append(pas) }

    func werkBij(_ pas: Fietspas) {
        guard let i = passen.firstIndex(where: { $0.id == pas.id }) else { return }
        passen[i] = pas
    }

    /// Er is hooguit één favoriet.
    func zetFavoriet(_ id: UUID, _ aan: Bool) {
        for i in passen.indices {
            passen[i].favoriet = aan && passen[i].id == id
        }
    }

    /// Wat de nagebootste scan "vindt": steeds een type dat je nog niet hebt,
    /// zodat je in een demo alle kleuren te zien krijgt.
    func volgendeScan() -> Fietspas {
        let bezit = Set(passen.map(\.type))
        let type = FietspasType.allCases.first { !bezit.contains($0) } ?? .fiets
        return Fietspas(type: type, code: Self.demoCode(type), bijnaam: "")
    }

    /// Vaste codes voor fiets en bakfiets (zoals in Figma), anders willekeurig.
    private static func demoCode(_ type: FietspasType) -> String {
        switch type {
        case .fiets:    return "ABC8D6E"
        case .bakfiets: return "KLM2P4R"
        default:
            let tekens = Array("ABCDEFGHJKLMNPRSTUVWXYZ23456789")
            return String((0..<7).map { _ in tekens.randomElement()! })
        }
    }

    private func bewaar() {
        if let data = try? JSONEncoder().encode(passen) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }
}
