import Foundation

// MARK: - Uitlegvideo

/// Eén korte uitlegvideo (portrait, ~30 sec) die bij een onderwerp hoort.
/// De video's zijn per taal apart opgenomen — een Turkse video is dus géén
/// vertaling van de Nederlandse, maar een eigen opname met eigen verteller.
struct ExplainerVideo: Identifiable {
    let id: String
    /// Volgnummer binnen de reeks (1, 2, 3 …) — wordt getoond als "Deel 1".
    let deel: Int
    let titleKey: String
    /// Bestandsnaam (zonder .mp4) per taal. Niet elke taal hoeft te bestaan.
    let bestanden: [AppLanguage: String]

    /// De beste beschikbare taal: de gevraagde taal, anders Nederlands.
    func bestand(voor taal: AppLanguage) -> String? {
        bestanden[taal] ?? bestanden[.nl]
    }

    /// Talen waarin deze video daadwerkelijk is opgenomen, in vaste volgorde.
    var beschikbareTalen: [AppLanguage] {
        AppLanguage.allCases.filter { bestanden[$0] != nil }
    }

    func url(voor taal: AppLanguage) -> URL? {
        guard let naam = bestand(voor: taal) else { return nil }
        return Bundle.main.url(forResource: naam, withExtension: "mp4")
    }
}

// MARK: - Reeks

/// Een reeks video's die samen één onderwerp uitleggen. Ze worden na elkaar
/// gekeken: aan het eind van een deel kun je door naar het volgende.
struct ExplainerReeks: Identifiable {
    let id: String
    let titleKey: String
    let videos: [ExplainerVideo]

    func volgende(na video: ExplainerVideo) -> ExplainerVideo? {
        guard let index = videos.firstIndex(where: { $0.id == video.id }),
              index + 1 < videos.count else { return nil }
        return videos[index + 1]
    }
}

// MARK: - Catalogus

enum VideoLibrary {
    /// Kwijtschelding: complex onderwerp, opgeknipt in drie korte delen.
    /// Deel 1 is ook in het Turks opgenomen (andere verteller, eigen script).
    static let kwijtschelding = ExplainerReeks(
        id: "kwijtschelding",
        titleKey: "video_reeks_kwijtschelding",
        videos: [
            ExplainerVideo(
                id: "kwijtschelding-1",
                deel: 1,
                titleKey: "video_kw_1_titel",
                bestanden: [.nl: "NL-01", .tr: "turks-01"]
            ),
            ExplainerVideo(
                id: "kwijtschelding-2",
                deel: 2,
                titleKey: "video_kw_2_titel",
                bestanden: [.nl: "NL-02"]
            ),
            ExplainerVideo(
                id: "kwijtschelding-3",
                deel: 3,
                titleKey: "video_kw_3_titel",
                bestanden: [.nl: "NL-03"]
            ),
        ]
    )
}
