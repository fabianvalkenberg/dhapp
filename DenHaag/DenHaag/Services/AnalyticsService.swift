import Foundation
import FirebaseFirestore
import UIKit

/// Verzamelt per testsessie zoveel mogelijk gebruiksdata in Firestore, zodat we
/// achteraf een uitgebreid testverslag per deelnemer kunnen maken.
///
/// Datamodel (Firestore, project `denhaag-app-fappie`):
///   sessions/{sessionID}                ← metadata + samenvatting (naam, voorkeuren,
///                                          feedback, einde/duur, tellingen)
///   sessions/{sessionID}/events/{auto}  ← één append-only document per gebeurtenis
///
/// Eén sessie = van koude start tot afsluiten — sluit aan op de demo-/reset-flow
/// (elke koude start of "Demo afsluiten" begint een nieuwe sessie).
final class AnalyticsService {
    static let shared = AnalyticsService()

    let sessionID: String
    private let startDate: Date
    private let db = Firestore.firestore()
    private let iso = ISO8601DateFormatter()

    // In-memory tellingen voor de samenvatting bij sessie-einde.
    private var counts: [String: Int] = [:]
    private var lastScreen: String?
    private var lastScreenStart: Date?

    private init() {
        sessionID = UUID().uuidString
        startDate = Date()
    }

    // MARK: - Sessie-levenscyclus

    /// Maakt het sessie-document aan. Eén keer bij app-start aanroepen.
    func start() {
        let data: [String: Any] = [
            "sessionID": sessionID,
            "startTime": FieldValue.serverTimestamp(),
            "startLocal": iso.string(from: startDate),
            "deviceID": UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
            "deviceModel": UIDevice.current.model,
            "systemVersion": UIDevice.current.systemVersion,
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?",
            "build": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        ]
        db.collection("sessions").document(sessionID).setData(data, merge: true)
        track("session_start")
    }

    /// Schrijft de eindsamenvatting (duur + tellingen). Mag vaker aangeroepen
    /// worden (bv. bij achtergrond én bij "Demo afsluiten") — laatste telt.
    func endSession() {
        if let last = lastScreen, let start = lastScreenStart {
            track("screen_exit", ["name": last, "seconds": Int(Date().timeIntervalSince(start))])
            lastScreenStart = Date()
        }
        let duration = Int(Date().timeIntervalSince(startDate))
        track("session_end", ["seconds": duration])
        setSession([
            "endTime": FieldValue.serverTimestamp(),
            "durationSeconds": duration,
            "counts": counts
        ])
    }

    // MARK: - Loggen

    /// Logt één gebeurtenis in de events-subcollectie.
    func track(_ type: String, _ props: [String: Any] = [:]) {
        counts[type, default: 0] += 1
        var data: [String: Any] = [
            "type": type,
            "timestamp": FieldValue.serverTimestamp(),
            "tLocal": iso.string(from: Date()),
            "sinceStart": Int(Date().timeIntervalSince(startDate))
        ]
        if let screen = lastScreen { data["screen"] = screen }
        if !props.isEmpty { data["props"] = props }

        db.collection("sessions").document(sessionID)
            .collection("events").addDocument(data: data)
    }

    /// Schermweergave: sluit de tijd op het vorige scherm af en opent het nieuwe.
    func screen(_ name: String) {
        if name == lastScreen { return }
        if let last = lastScreen, let start = lastScreenStart {
            track("screen_exit", ["name": last, "seconds": Int(Date().timeIntervalSince(start))])
        }
        lastScreen = name
        lastScreenStart = Date()
        track("screen_view", ["name": name])
    }

    /// Werkt velden bij op het sessie-document (naam, voorkeuren, feedback, …).
    func setSession(_ fields: [String: Any]) {
        db.collection("sessions").document(sessionID).setData(fields, merge: true)
    }

    // MARK: - Statische gemak-helpers (kortere call-sites)

    static func track(_ type: String, _ props: [String: Any] = [:]) { shared.track(type, props) }
    static func screen(_ name: String) { shared.screen(name) }
    static func setSession(_ fields: [String: Any]) { shared.setSession(fields) }
}
