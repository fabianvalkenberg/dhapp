import SwiftUI
import AVKit

// MARK: - Uitleg-speler

/// Speelt een reeks korte portrait-video's na elkaar af, schermvullend.
/// Aan het eind van elk deel verschijnt een keuze: verder naar het volgende
/// deel, of sluiten. De video stopt dus nooit in het niets.
struct ExplainerPlayerView: View {
    @EnvironmentObject var lang: LanguageManager

    let reeks: ExplainerReeks
    @State var huidige: ExplainerVideo
    @Binding var isPresented: Bool

    /// Eén speler voor de hele reeks; per deel wisselen we alleen het item.
    /// Bewust géén nieuwe AVPlayer per video: dan moet je zelf notificatie-
    /// tokens bijhouden, en die administratie liep uit de pas met de SwiftUI-
    /// state — het volgende deel bleef dan op het eindscherm hangen.
    @State private var player = AVPlayer()
    @State private var gekozenTaal: AppLanguage = .nl
    @State private var isAfgelopen = false

    private var volgende: ExplainerVideo? { reeks.volgende(na: huidige) }
    private var safeTop: CGFloat { AppDesign.safeAreaTop }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VideoPlayer(player: player)
                .ignoresSafeArea()
                .allowsHitTesting(!isAfgelopen)

            // Donkere laag met de keuze zodra de video is afgelopen
            if isAfgelopen {
                Color.black.opacity(0.75).ignoresSafeArea()
                eindKeuze
                    .transition(.opacity)
            }

            // Kop: sluitknop, deel-aanduiding en taalkeuze
            VStack {
                header
                Spacer()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)) { melding in
            // Alleen reageren op het item dat nu daadwerkelijk speelt.
            guard let item = melding.object as? AVPlayerItem,
                  item === player.currentItem else { return }
            withAnimation(.easeInOut(duration: 0.25)) { isAfgelopen = true }
        }
        .onAppear { start(huidige) }
        .onDisappear { player.pause() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            Text(String(format: lang.t("video_deel_van"), huidige.deel, reeks.videos.count))
                .font(AppFont.theSans(size: 14, weight: .semiBold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.black.opacity(0.45))
                .clipShape(Capsule())

            Spacer()

            // Taalknop staat in de speler zelf: wie uitleg in eigen taal nodig
            // heeft, heeft de app-taal vaak niet omgezet.
            if huidige.beschikbareTalen.count > 1 {
                HStack(spacing: 6) {
                    ForEach(huidige.beschikbareTalen) { taal in
                        Button {
                            wisselTaal(naar: taal)
                        } label: {
                            Text(taal.rawValue.uppercased())
                                .font(AppFont.theSans(size: 13, weight: .semiBold))
                                .foregroundColor(taal == gekozenTaal ? AppColors.textPrimary : .white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(taal == gekozenTaal ? Color.white : Color.black.opacity(0.45))
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            Button {
                isPresented = false
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.black.opacity(0.45))
                    .clipShape(Circle())
            }
            .padding(.leading, 6)
        }
        .padding(.horizontal, AppDesign.horizontalPadding)
        .padding(.top, safeTop + 8)
    }

    // MARK: - Keuze na afloop

    private var eindKeuze: some View {
        VStack(spacing: 14) {
            Spacer()

            Text(lang.t(huidige.titleKey))
                .font(AppFont.theMix(size: 24, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppDesign.horizontalPadding)
                .padding(.bottom, 6)

            if let volgende {
                knop(
                    titel: lang.t("video_volgende"),
                    ondertitel: lang.t(volgende.titleKey),
                    gevuld: true
                ) {
                    start(volgende)
                }
            } else {
                Text(lang.t("video_reeks_klaar"))
                    .font(AppFont.theSans(size: 16, weight: .plain))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppDesign.horizontalPadding)
                    .padding(.bottom, 6)
            }

            // ⚠️ "Opnieuw kijken" staat hier bewust NIET.
            // Die knop sloot het scherm in plaats van te herstarten, en de
            // oorzaak is nog niet gevonden — het lag niet aan start(), niet aan
            // de Binding van de cover en niet aan AVKit's VideoPlayer. Zolang
            // dat niet is uitgezocht, liever geen knop dan een knop die iets
            // anders doet dan hij belooft. Zie docs/DECISIONS.md.
            knop(titel: lang.t("video_sluiten"), ondertitel: nil, gevuld: false) {
                isPresented = false
            }

            Spacer().frame(height: 40)
        }
    }

    private func knop(titel: String, ondertitel: String?, gevuld: Bool, actie: @escaping () -> Void) -> some View {
        Button(action: actie) {
            VStack(spacing: 2) {
                Text(titel)
                    .font(AppFont.theSans(size: 16, weight: .semiBold))
                if let ondertitel {
                    Text(ondertitel)
                        .font(AppFont.theSans(size: 14, weight: .plain))
                        .opacity(0.85)
                }
            }
            .foregroundColor(gevuld ? .white : AppColors.textPrimary)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(gevuld ? AppColors.groen3 : Color.white)
            .cornerRadius(AppDesign.cornerRadius)
        }
        .padding(.horizontal, AppDesign.horizontalPadding)
    }

    // MARK: - Afspelen

    private func start(_ video: ExplainerVideo) {
        huidige = video

        // Val terug op Nederlands als de video niet in de app-taal bestaat.
        let taal = video.bestanden[lang.current] != nil ? lang.current : .nl
        gekozenTaal = taal

        speelAf(video.url(voor: taal))
        AnalyticsService.track("video_open", ["video": video.id, "taal": taal.rawValue])
    }

    private func wisselTaal(naar taal: AppLanguage) {
        guard taal != gekozenTaal else { return }
        gekozenTaal = taal

        speelAf(huidige.url(voor: taal))
        AnalyticsService.track("video_taal", ["video": huidige.id, "taal": taal.rawValue])
    }

    private func speelAf(_ url: URL?) {
        guard let url else { return }

        isAfgelopen = false
        player.replaceCurrentItem(with: AVPlayerItem(url: url))
        player.seek(to: .zero)
        player.play()
    }
}
