import SwiftUI

// MARK: - Vergunning Model

private enum VergunningStatus {
    case actief
    case actieNodig
    case verlopen

    var labelKey: String {
        switch self {
        case .actief: return "verg_status_actief"
        case .actieNodig: return "verg_status_actie"
        case .verlopen: return "verg_status_verlopen"
        }
    }

    var color: Color {
        switch self {
        case .actief: return AppColors.groen3
        case .actieNodig: return Color(hex: "E8890C")
        case .verlopen: return AppColors.rood
        }
    }
}

private struct Vergunning: Identifiable {
    let id = UUID()
    let nameKey: String
    let dateKey: String
    let status: VergunningStatus
}

// MARK: - Vergunningen Section

struct VergunningenSection: View {
    @EnvironmentObject var lang: LanguageManager

    private let vergunningen: [Vergunning] = [
        Vergunning(nameKey: "verg_terras", dateKey: "verg_terras_date", status: .actieNodig),
        Vergunning(nameKey: "verg_exploitatie", dateKey: "verg_exploitatie_date", status: .actief),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(lang.t("verg_title"))
                .font(AppFont.theMix(size: 20, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, AppDesign.horizontalPadding)

            VStack(spacing: 0) {
                ForEach(Array(vergunningen.enumerated()), id: \.element.id) { index, item in
                    vergunningRow(item: item)

                    if index < vergunningen.count - 1 {
                        Divider()
                            .background(AppColors.grijs2)
                            .padding(.horizontal, 16)
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppColors.grijs2, lineWidth: 1)
            )
            .padding(.horizontal, AppDesign.horizontalPadding)
        }
    }

    @ViewBuilder
    private func vergunningRow(item: Vergunning) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(lang.t(item.nameKey))
                    .font(AppFont.theSans(size: 16, weight: .semiBold))
                    .foregroundColor(AppColors.textPrimary)

                Text(lang.t(item.dateKey))
                    .font(AppFont.theSans(size: 14, weight: .plain))
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            // Status badge
            Text(lang.t(item.status.labelKey))
                .font(AppFont.theSans(size: 12, weight: .semiBold))
                .foregroundColor(item.status.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(item.status.color.opacity(0.12))
                .cornerRadius(12)

            Image("arrow-right")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(16)
    }
}
