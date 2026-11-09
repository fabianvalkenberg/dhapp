import SwiftUI

/// Zachte vervaging achter de statusbalk zodra je scrolt (design review
/// 2026-11, Figma "Top-fade (blur + wit verloop)"). Zonder dit loopt de inhoud
/// hard onder klok en batterij door en oogt het rommelig.
///
/// Figma: 106 pt hoog op een toestel met 62 pt statusbalk (= statusbalk + 44),
/// blur die van boven naar onder afloopt, plus een wit verloop
/// (92% → 70% op 55% → 0%) op 40% dekking.
struct TopFade: View {
    var body: some View {
        let hoogte = AppDesign.safeAreaTop + 44
        ZStack {
            // Afnemende blur: materiaal dat naar onder wegloopt.
            Rectangle()
                .fill(.ultraThinMaterial)
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .black, location: 0),
                            .init(color: .black, location: 0.45),
                            .init(color: .clear, location: 1),
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                )
            LinearGradient(
                stops: [
                    .init(color: .white.opacity(0.92), location: 0),
                    .init(color: .white.opacity(0.70), location: 0.55),
                    .init(color: .white.opacity(0), location: 1),
                ],
                startPoint: .top, endPoint: .bottom
            )
            .opacity(0.4)
        }
        .frame(height: hoogte)
        .frame(maxWidth: .infinity)
        .allowsHitTesting(false)
    }
}

private struct TopFadeModifier: ViewModifier {
    @State private var scroll: CGFloat = 0

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content
                .onScrollGeometryChange(for: CGFloat.self) { geo in
                    geo.contentOffset.y + geo.contentInsets.top
                } action: { _, nieuw in
                    scroll = nieuw
                }
                .overlay(alignment: .top) {
                    TopFade()
                        // In rust onzichtbaar; na ~24 pt scrollen volledig.
                        .opacity(min(max(scroll / 24, 0), 1))
                        .ignoresSafeArea(edges: .top)
                }
        } else {
            // iOS 17 kent geen scroll-geometrie: dan geen vervaging.
            content
        }
    }
}

extension View {
    /// Zet op een verticale ScrollView van een volledig scherm.
    func bovenVervaging() -> some View { modifier(TopFadeModifier()) }
}
