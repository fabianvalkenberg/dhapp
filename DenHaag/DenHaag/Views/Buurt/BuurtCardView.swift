import SwiftUI

/// Buurt-kaartje volgens Figma-component "A - geen foto" (node 2830:14592).
struct BuurtCardView: View {
    let item: NeighbourhoodItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Foto-header met datum-badge
            ZStack(alignment: .topLeading) {
                Image(item.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 105)
                    .clipped()

                dateBadge
                    .padding(20)
            }
            .frame(height: 105)
            .clipped()

            // Witte body
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(AppFont.theMix(size: 20, weight: .bold))
                        .foregroundColor(.black)
                        .lineLimit(1)

                    Text(item.subtitle)
                        .font(AppFont.theSans(size: 18, weight: .plain))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        detailRow(icon: "calendar", text: item.dateRange)
                        detailRow(icon: "location-pin", text: item.location)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppColors.blauw3)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(AppColors.grijs2, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.10), radius: 1.5, x: 0, y: 2)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 10)
    }

    private var dateBadge: some View {
        VStack(spacing: -2) {
            Text(item.day)
                .font(AppFont.theMix(size: 24, weight: .bold))
                .foregroundColor(AppColors.darkGrey)
            Text(item.month)
                .font(AppFont.theSans(size: 18, weight: .bold))
                .foregroundColor(AppColors.groen4)
        }
        .frame(width: 64, height: 64)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(AppColors.darkGrey.opacity(0.22), lineWidth: 1)
        )
    }

    private func detailRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundColor(AppColors.textSecondary)
            Text(text)
                .font(AppFont.theSans(size: 14, weight: .plain))
                .foregroundColor(AppColors.textSecondary)
        }
    }
}

