import SwiftUI

/// Eigen afvalkalender-pagina (geopend via de home-tegel "Afval-kalender").
/// Toont de eerstvolgende ophaalmomenten per afvalsoort, met een herinnering-belletje.
/// Zelfde clean template als de andere detail-overlays: back-knop + titel ernaast.
struct AfvalkalenderView: View {
    @Binding var isPresented: Bool

    private struct Pickup: Identifiable {
        let id = UUID()
        let type: String
        let color: Color
        let date: String
        let highlight: Bool   // eerstvolgende ophaalmoment uitlichten
    }

    /// Uit de gedeelde afvalplanning, zodat "morgen" klopt met de kaart op home.
    private let pickups: [Pickup] = AfvalPlanning.ophalingen.enumerated().map { i, o in
        Pickup(type: o.soort, color: o.kleur, date: AfvalPlanning.label(o.datum), highlight: i == 0)
    }

    @State private var reminders: Set<UUID> = []

    var body: some View {
        ZStack(alignment: .topLeading) {
            AppColors.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Back-knop + titel
                    HStack(spacing: 12) {
                        BackCircleButton { isPresented = false }
                        Text("Afval-kalender")
                            .font(AppFont.theMix(size: 26, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                        Spacer()
                    }
                    .padding(.top, AppDesign.terugknopTop)

                    Text("De eerstvolgende ophaalmomenten bij jou in de buurt. Zet een herinnering aan, dan vergeet je het niet.")
                        .font(AppFont.theSans(size: 17, weight: .plain))
                        .foregroundColor(AppColors.textSecondary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    // Lijst met ophaalmomenten
                    VStack(spacing: 0) {
                        ForEach(Array(pickups.enumerated()), id: \.element.id) { index, p in
                            pickupRow(p)
                            if index < pickups.count - 1 {
                                Rectangle().fill(AppColors.grijs2).frame(height: 1)
                            }
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.grijs2, lineWidth: 1))

                    // Waar hoort welk afval
                    Button {} label: {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Waar hoort welk afval?")
                                .font(AppFont.theSans(size: 16, weight: .semiBold))
                            Spacer()
                            Image("arrow-right").renderingMode(.template).resizable().scaledToFit()
                                .frame(width: 16, height: 16)
                        }
                        .foregroundColor(AppColors.groen3)
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.groen3, lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, AppDesign.horizontalPadding)
            }
            .bovenVervaging()
        }
    }

    private func pickupRow(_ p: Pickup) -> some View {
        HStack(spacing: 14) {
            // Gekleurde kliko-indicator
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(p.color.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: "trash.fill")
                    .font(.system(size: 17))
                    .foregroundColor(p.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(p.type)
                    .font(AppFont.theSans(size: 16, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                Text(p.date)
                    .font(AppFont.theSans(size: 14, weight: p.highlight ? .bold : .plain))
                    .foregroundColor(p.highlight ? AppColors.groen3 : AppColors.textSecondary)
            }

            Spacer()

            // Herinnering aan/uit
            Button {
                if reminders.contains(p.id) { reminders.remove(p.id) } else { reminders.insert(p.id) }
            } label: {
                Image(systemName: reminders.contains(p.id) ? "bell.fill" : "bell")
                    .font(.system(size: 17))
                    .foregroundColor(reminders.contains(p.id) ? AppColors.groen3 : AppColors.grijs4)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 64)
    }
}
