import Foundation
import FirebaseFirestore
import UIKit

/// Schrijft per afgeronde onboarding één record naar Firestore, zodat we
/// over alle testdevices heen kunnen zien wie wanneer welke voorkeuren koos.
/// Collectie `onboarding_sessions` (rules: alleen create, geen read/update).
enum OnboardingLogService {

    static func logSession(selectedTileIDs: [String], skipped: Bool, name: String = "",
                           gemeenteTaken: [String] = [], buurtTopics: [String] = []) {
        let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        let data: [String: Any] = [
            // Server-tijd voor consistente volgorde over devices heen…
            "timestamp": FieldValue.serverTimestamp(),
            // …plus een leesbare lokale tijd als snelle referentie.
            "localTime": ISO8601DateFormatter().string(from: Date()),
            "deviceID": deviceID,
            "deviceModel": UIDevice.current.model,
            "systemVersion": UIDevice.current.systemVersion,
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?",
            "build": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?",
            // De in de onboarding opgegeven naam (leeg = niet ingevuld / overgeslagen).
            "name": trimmedName,
            "selectedTiles": selectedTileIDs,
            "selectedCount": selectedTileIDs.count,
            // Stap 1 (gemeente-taken) en stap 2 (buurt-onderwerpen) ruw mee.
            "gemeenteTaken": gemeenteTaken,
            "buurtTopics": buurtTopics,
            "skipped": skipped
        ]

        Firestore.firestore()
            .collection("onboarding_sessions")
            .addDocument(data: data) { error in
                if let error = error {
                    print("[OnboardingLog] Firestore-schrijf mislukt: \(error.localizedDescription)")
                } else {
                    print("[OnboardingLog] Sessie gelogd — \(selectedTileIDs.count) tegels, skipped=\(skipped)")
                }
            }
    }
}
