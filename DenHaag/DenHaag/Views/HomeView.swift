import SwiftUI

struct HomeView: View {
    @EnvironmentObject var lang: LanguageManager
    @ObservedObject var settings: HomeSettingsModel
    @Binding var showCustomizeSheet: Bool
    @Binding var showSettings: Bool
    @Binding var showAppointment: Bool
    @Binding var showKwijtschelding: Bool
    @Binding var showAanvraag: Bool
    @Binding var showPaspoort: Bool
    var onTile: (TileDestination) -> Void
    @State private var scrollOffset: CGFloat = 0

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    private var safeTop: CGFloat { AppDesign.safeAreaTop }

    var body: some View {
        ZStack(alignment: .top) {
            AppColors.background
                .ignoresSafeArea()

            // Gele facetten-band achter de notch. Vult bij rust de notch-zone, maar
            // krimpt mee zodra je omhoog scrollt (scrollOffset wordt negatief), zodat
            // de band samen met de header uit beeld verdwijnt i.p.v. te blijven staan.
            Image("facetten-geel")
                .resizable()
                .scaledToFill()
                .frame(height: max(0, safeTop + 30 + min(0, scrollOffset)))
                .frame(maxWidth: .infinity)
                .clipped()
                .ignoresSafeArea(edges: .top)
                .allowsHitTesting(false)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Geel header-vlak met facetten + kaarten-carrousel (behouden)
                    HeaderView(
                        settings: settings,
                        onSettingsTapped: { showSettings = true },
                        onAppointmentTapped: { showAppointment = true },
                        onKwijtscheldingTapped: { showKwijtschelding = true },
                        onAanvraagTapped: { showAanvraag = true },
                        onPaspoortTapped: { showPaspoort = true },
                        scrollOffset: scrollOffset
                    )

                    VStack(spacing: 28) {
                        // Springplank: alleen de gekozen tegels
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(settings.selectedTiles) { tile in
                                TegelView(
                                    illustration: tile.illustration,
                                    title: lang.t(tile.titleKey),
                                    action: tile.isInteractive ? { onTile(tile.destination) } : nil
                                )
                            }
                        }
                        .padding(.horizontal, AppDesign.horizontalPadding + 6)

                        // Startscherm aanpassen
                        Button {
                            showCustomizeSheet = true
                        } label: {
                            HStack(spacing: 8) {
                                Image("preferences")
                                    .renderingMode(.template)
                                    .resizable()
                                    .frame(width: 18, height: 18)
                                Text(lang.t("customize_home"))
                                    .font(AppFont.theSans(size: 16, weight: .semiBold))
                            }
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppDesign.cornerRadius)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        }

                        // Onderkant-ruimte voor de tab bar
                        Spacer().frame(height: 100)
                    }
                    .padding(.top, 8)
                }
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: ScrollOffsetKey.self,
                            value: geo.frame(in: .named("scroll")).minY
                        )
                    }
                )
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetKey.self) { value in
                scrollOffset = value
            }
            .ignoresSafeArea(edges: .top)
        }
    }
}

private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
