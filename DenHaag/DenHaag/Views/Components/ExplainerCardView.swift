import SwiftUI
import AVFoundation

// MARK: - Uitleg-kaart

/// Instapkaart bij een onderwerp: "Snap je dit niet? Kijk het in 1 minuut."
/// Staat bewust ín het onderwerp en niet in een aparte videosectie — mensen
/// openen een gemeente-app niet om een filmpje te kijken, ze lopen vast op een
/// pagina en hebben dáár uitleg nodig.
struct ExplainerCardView: View {
    @EnvironmentObject var lang: LanguageManager

    let reeks: ExplainerReeks
    let onStart: (ExplainerVideo) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.groen3)
                Text(lang.t("video_uitleg_titel"))
                    .font(AppFont.theMix(size: 22, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
            }

            Text(lang.t("video_uitleg_subtitel"))
                .font(AppFont.theSans(size: 16, weight: .plain))
                .foregroundColor(AppColors.textSecondary)
                .lineSpacing(4)

            HStack(spacing: 10) {
                ForEach(reeks.videos) { video in
                    Button {
                        onStart(video)
                    } label: {
                        VideoThumbView(video: video, taal: lang.current)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 2)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.warmGrijs)
        .cornerRadius(8)
    }
}

// MARK: - Thumbnail

/// Portrait-voorbeeldje van één deel. Het beeld komt uit de video zelf
/// (eerste frame), zodat er geen losse thumbnail-assets nodig zijn.
private struct VideoThumbView: View {
    @EnvironmentObject var lang: LanguageManager

    let video: ExplainerVideo
    let taal: AppLanguage

    @State private var poster: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                if let poster {
                    Image(uiImage: poster)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    AppColors.grijs2
                }

                // Donker verloop onderin zodat het deelnummer leesbaar blijft
                LinearGradient(
                    colors: [.clear, .black.opacity(0.55)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                VStack {
                    Spacer()
                    HStack {
                        Text("\(video.deel)")
                            .font(AppFont.theSans(size: 13, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "play.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 7)
                }
            }
            .frame(height: 128)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            Text(lang.t(video.titleKey))
                .font(AppFont.theSans(size: 13, weight: .plain))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .task { await laadPoster() }
    }

    private func laadPoster() async {
        guard poster == nil, let url = video.url(voor: taal) else { return }

        let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 240, height: 426)

        // Iets ná het begin: het allereerste frame is vaak nog een lege fade-in.
        let tijd = CMTime(seconds: 0.6, preferredTimescale: 600)
        if let cg = try? await generator.image(at: tijd).image {
            poster = UIImage(cgImage: cg)
        }
    }
}
