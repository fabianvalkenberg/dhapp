import SwiftUI

/// Ronde terug-knop voor detailschermen. Wit op 90% opacity met een lichtgrijze
/// border, zodat 'ie ook over lichte achtergronden goed zichtbaar blijft.
struct BackCircleButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
                .frame(width: 40, height: 40)
                .background(Color.white.opacity(0.9))
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(AppColors.grijs2, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
