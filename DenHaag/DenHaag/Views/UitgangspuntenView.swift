import SwiftUI

// MARK: - Uitgangspunt Card Model

private struct UitgangspuntCard: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let body: String
    let color: Color
}

// MARK: - Uitgangspunten View

struct UitgangspuntenView: View {
    @EnvironmentObject var lang: LanguageManager
    @Binding var isPresented: Bool
    @State private var currentPage: Int = 0

    private var safeTop: CGFloat { AppDesign.safeAreaTop }

    private var cards: [UitgangspuntCard] {
        [
            UitgangspuntCard(
                icon: "exclamationmark.triangle.fill",
                title: lang.t("ug_card0_title"),
                body: lang.t("ug_card0_body"),
                color: AppColors.rood
            ),
            UitgangspuntCard(
                icon: "lightbulb.fill",
                title: lang.t("ug_card0b_title"),
                body: lang.t("ug_card0b_body"),
                color: Color(hex: "E8890C")
            ),
            UitgangspuntCard(
                icon: "person.2.fill",
                title: lang.t("ug_card1_title"),
                body: lang.t("ug_card1_body"),
                color: AppColors.groen3
            ),
            UitgangspuntCard(
                icon: "hand.raised.fill",
                title: lang.t("ug_card2_title"),
                body: lang.t("ug_card2_body"),
                color: Color(hex: "2B6CB0")
            ),
            UitgangspuntCard(
                icon: "iphone",
                title: lang.t("ug_card3_title"),
                body: lang.t("ug_card3_body"),
                color: Color(hex: "E8890C")
            ),
            UitgangspuntCard(
                icon: "globe",
                title: lang.t("ug_card4_title"),
                body: lang.t("ug_card4_body"),
                color: Color(hex: "8B5CF6")
            ),
            UitgangspuntCard(
                icon: "sparkles",
                title: lang.t("ug_card5_title"),
                body: lang.t("ug_card5_body"),
                color: AppColors.geel3
            ),
        ]
    }

    var body: some View {
        ZStack(alignment: .top) {
            AppColors.background
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Compact top bar area
                    Color.clear.frame(height: AppDesign.terugknopTop + BackCircleButton.maat + 5)

                    // Card carousel
                    let cardWidth = UIScreen.main.bounds.width - 48
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                                uitgangspuntCardView(card: card)
                                    .frame(width: cardWidth)
                                    .id(index)
                            }
                        }
                        .scrollTargetLayout()
                        .padding(.horizontal, 24)
                    }
                    .scrollTargetBehavior(.viewAligned)
                    .scrollPosition(id: Binding(
                        get: { currentPage as Int? },
                        set: { if let v = $0 { currentPage = v } }
                    ))

                    Spacer().frame(height: 24)

                    // Page indicators
                    HStack(spacing: 8) {
                        ForEach(cards.indices, id: \.self) { index in
                            Capsule()
                                .fill(index == currentPage ? AppColors.groen3 : AppColors.grijs2)
                                .frame(
                                    width: index == currentPage ? 24 : 8,
                                    height: 8
                                )
                        }
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)

                    Spacer().frame(height: 60)
                }
            }
            .bovenVervaging()

            // Top bar with back button and title
            HStack(spacing: 12) {
                BackCircleButton(stijl: .wit) { isPresented = false }

                Text(lang.t("ug_title"))
                    .font(AppFont.theMix(size: 18, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)

                Spacer()
            }
            .padding(.horizontal, AppDesign.horizontalPadding)
            // Dit scherm staat al onder de statusbalk: alleen de 8 pt erbij.
            .padding(.top, AppDesign.terugknopTop)
            .background(
                AppColors.background
                    .ignoresSafeArea(edges: .top)
            )
        }
    }

    // MARK: - Card View

    @ViewBuilder
    private func uitgangspuntCardView(card: UitgangspuntCard) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Icon
            Image(systemName: card.icon)
                .font(.system(size: 28))
                .foregroundColor(card.color)
                .frame(width: 56, height: 56)
                .background(card.color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14))

            // Title
            Text(card.title)
                .font(AppFont.theMix(size: 22, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            // Body
            Text(card.body)
                .font(AppFont.theSans(size: 16, weight: .plain))
                .foregroundColor(AppColors.textSecondary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 320)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}
