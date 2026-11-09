import SwiftUI

// MARK: - Buurt Info Item

private struct BuurtInfoItem: Identifiable {
    let id = UUID()
    let titleKey: String
    let dateKey: String
    let descriptionKey: String
    let iconName: String
    let accentColor: Color
}

// MARK: - Buurt Info Section

struct BuurtInfoSection: View {
    @EnvironmentObject var lang: LanguageManager

    private let items: [BuurtInfoItem] = [
        BuurtInfoItem(
            titleKey: "buurt_werkzaamheden_title",
            dateKey: "buurt_werkzaamheden_date",
            descriptionKey: "buurt_werkzaamheden_desc",
            iconName: "wegwerkzaamheden",
            accentColor: Color(hex: "E8890C")
        ),
        BuurtInfoItem(
            titleKey: "buurt_evenement_title",
            dateKey: "buurt_evenement_date",
            descriptionKey: "buurt_evenement_desc",
            iconName: "megaphone",
            accentColor: AppColors.blauw3
        ),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(lang.t("buurt_title"))
                .font(AppFont.theMix(size: 20, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, AppDesign.horizontalPadding)

            VStack(spacing: 12) {
                ForEach(items) { item in
                    buurtCard(item: item)
                }
            }
            .padding(.horizontal, AppDesign.horizontalPadding)
        }
    }

    @ViewBuilder
    private func buurtCard(item: BuurtInfoItem) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            Image(item.iconName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundColor(item.accentColor)
                .frame(width: 44, height: 44)
                .background(item.accentColor.opacity(0.12))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                Text(lang.t(item.titleKey))
                    .font(AppFont.theSans(size: 16, weight: .semiBold))
                    .foregroundColor(AppColors.textPrimary)

                Text(lang.t(item.dateKey))
                    .font(AppFont.theSans(size: 13, weight: .plain))
                    .foregroundColor(AppColors.textSecondary)

                Text(lang.t(item.descriptionKey))
                    .font(AppFont.theSans(size: 14, weight: .plain))
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(3)
                    .padding(.top, 2)
            }

            Spacer()

            Image("arrow-right")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundColor(AppColors.textSecondary)
                .padding(.top, 4)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppColors.grijs2, lineWidth: 1)
        )
    }
}
