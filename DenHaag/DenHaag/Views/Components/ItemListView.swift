import SwiftUI

// MARK: - Item Model

struct ListItem: Identifiable {
    let id = UUID()
    let icon: String           // Asset name or SF Symbol
    let isSystemIcon: Bool
    let title: String
    let action: (() -> Void)?

    init(icon: String, title: String, isSystemIcon: Bool = false, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.isSystemIcon = isSystemIcon
        self.action = action
    }
}

// MARK: - Item List Component

struct ItemListView: View {
    let items: [ListItem]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                Button {
                    item.action?()
                } label: {
                    HStack(spacing: 12) {
                        // Icon
                        if item.isSystemIcon {
                            Image(systemName: item.icon)
                                .font(.system(size: 18))
                                .frame(width: 24, height: 24)
                                .foregroundColor(AppColors.textSecondary)
                        } else {
                            Image(item.icon)
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundColor(AppColors.textSecondary)
                        }

                        // Label
                        Text(item.title)
                            .font(AppFont.bodyRegular())
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(1)

                        Spacer()

                        // Arrow
                        Image("arrow-right")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.horizontal, 16)
                    .frame(minHeight: 56)          // gelijke hoogte voor elk item
                }
                .buttonStyle(.plain)

                // Scheidingslijn over de volledige breedte (niet na het laatste item;
                // de onderrand van het blok vormt daar de sluitlijn).
                if index < items.count - 1 {
                    Rectangle()
                        .fill(AppColors.grijs2)
                        .frame(height: 1)
                }
            }
        }
        .background(Color.white)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppColors.grijs2, lineWidth: 1)
        )
    }
}
