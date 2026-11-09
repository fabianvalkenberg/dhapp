import SwiftUI

/// Afspraak verplaatsen: kies een vrij moment en bevestig. Prototype: de
/// momenten zijn verzonnen, er wordt niets echt geboekt.
struct AfspraakVerplaatsenView: View {
    @EnvironmentObject var lang: LanguageManager
    @EnvironmentObject var afspraak: AfspraakStore
    @Environment(\.dismiss) private var dismiss
    /// Na bevestigen, met het nieuwe moment.
    var onBevestigd: (Date) -> Void

    @State private var gekozen: Date?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(lang.t(afspraak.afgezegd ? "afspraak_kies_title" : "afspraak_verplaats_title"))
                        .font(AppFont.theMix(size: 26, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.bottom, 6)
                    Text(lang.t("afspraak_verplaats_sub"))
                        .font(AppFont.theSans(size: 16, weight: .plain))
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.bottom, 20)

                    VStack(spacing: 10) {
                        ForEach(afspraak.vrijeMomenten, id: \.self) { moment in
                            let actief = gekozen == moment
                            Button { gekozen = moment } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(AfspraakStore.dag(moment).eersteHoofdletter)
                                            .font(AppFont.theSans(size: 17, weight: .bold))
                                        Text("\(AfspraakStore.tijd(moment)) · Spui")
                                            .font(AppFont.theSans(size: 15, weight: .plain))
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: actief ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 22))
                                        .foregroundColor(actief ? AppColors.groen3 : AppColors.grijs2)
                                }
                                .foregroundColor(AppColors.textPrimary)
                                .padding(16)
                                .background(actief ? AppColors.groen1.opacity(0.5) : Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: AppDesign.cornerRadius))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppDesign.cornerRadius)
                                        .stroke(actief ? AppColors.groen3 : AppColors.grijs2, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Button {
                        guard let gekozen else { return }
                        onBevestigd(gekozen)
                        dismiss()
                    } label: {
                        Text(lang.t("afspraak_bevestig"))
                            .font(AppFont.theSans(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(gekozen == nil ? AppColors.grijs2 : AppColors.groen3)
                            .clipShape(RoundedRectangle(cornerRadius: AppDesign.cornerRadius))
                    }
                    .buttonStyle(.plain)
                    .disabled(gekozen == nil)
                    .padding(.top, 24)
                }
                .padding(AppDesign.horizontalPadding)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(lang.t("cancel")) { dismiss() }
                }
            }
        }
    }
}
