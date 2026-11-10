import SwiftUI

/// Hoe ver je laatste melding is: wat, waar, meldnummer en een tijdlijn
/// (ontvangen, in behandeling, opgelost). Zelfde opbouw als AanvraagDetailView.
struct MeldingStatusView: View {
    @EnvironmentObject var lang: LanguageManager
    @EnvironmentObject var melding: MeldingStore
    @Binding var isPresented: Bool
    var onNogIetsMelden: () -> Void

    private var safeTop: CGFloat { AppDesign.safeAreaTop }

    private var datumTekst: String {
        let f = DateFormatter(); f.locale = Locale(identifier: "nl_NL"); f.dateFormat = "d MMMM"
        return Calendar.current.isDateInToday(melding.laatste.datum) ? lang.t("melding_vandaag") : f.string(from: melding.laatste.datum)
    }

    var body: some View {
        let m = melding.laatste
        ZStack(alignment: .topLeading) {
            AppColors.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    Color.clear.frame(height: safeTop + 44)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(lang.t("melding_status_title"))
                            .font(AppFont.theMix(size: 30, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                        Text(m.wat)
                            .font(AppFont.theSans(size: 17, weight: .plain))
                            .foregroundColor(AppColors.textSecondary)
                    }

                    // Tijdlijn
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(0..<3, id: \.self) { i in
                            stapRij(i, huidig: m.stap, isLast: i == 2)
                        }
                    }

                    // Gegevens
                    VStack(spacing: 0) {
                        rij(lang.t("melding_waar"), m.waar)
                        Divider()
                        rij(lang.t("melding_nummer"), m.nummer)
                        Divider()
                        rij(lang.t("melding_gemeld_op"), datumTekst)
                    }
                    .padding(.horizontal, 16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppDesign.cornerRadius))
                    .overlay(RoundedRectangle(cornerRadius: AppDesign.cornerRadius).stroke(AppColors.grijs2, lineWidth: 1))

                    Text(lang.t("melding_status_uitleg"))
                        .font(AppFont.theSans(size: 16, weight: .plain))
                        .foregroundColor(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Button(action: onNogIetsMelden) {
                        HStack(spacing: 8) {
                            Text(lang.t("melding_nog_een"))
                                .font(AppFont.theSans(size: 17, weight: .bold))
                            Spacer()
                            Image("arrow-right")
                                .renderingMode(.template).resizable().scaledToFit()
                                .frame(width: 18, height: 18)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 15)
                        .background(AppColors.groen3)
                        .clipShape(RoundedRectangle(cornerRadius: AppDesign.cornerRadius))
                    }
                    .buttonStyle(.plain)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, AppDesign.horizontalPadding)
            }
            .bovenVervaging()

            BackCircleButton { withAnimation(.easeInOut(duration: 0.3)) { isPresented = false } }
                .terugknopPlek()
        }
        .ignoresSafeArea(edges: .top)
        .onAppear { AnalyticsService.screen("melding_status") }
    }

    private func stapRij(_ i: Int, huidig: Int, isLast: Bool) -> some View {
        let klaar = i < huidig || (i == 2 && huidig == 2)
        let actief = i == huidig && huidig < 2
        return HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(klaar ? AppColors.groen3 : (actief ? AppColors.groen3.opacity(0.15) : Color.white))
                        .frame(width: 26, height: 26)
                        .overlay(Circle().stroke(klaar || actief ? AppColors.groen3 : AppColors.grijs2, lineWidth: 1.5))
                    if klaar {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    } else if actief {
                        Circle().fill(AppColors.groen3).frame(width: 9, height: 9)
                    }
                }
                if !isLast {
                    Rectangle()
                        .fill(i < huidig ? AppColors.groen3 : AppColors.grijs2)
                        .frame(width: 2, height: 34)
                }
            }
            Text(lang.t(MeldingStore.stapKeys[i]))
                .font(AppFont.theSans(size: 17, weight: actief ? .bold : .semiBold))
                .foregroundColor(actief || klaar ? AppColors.textPrimary : AppColors.textSecondary)
                .padding(.top, 2)
            Spacer()
        }
    }

    private func rij(_ label: String, _ waarde: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(AppFont.theSans(size: 16, weight: .plain))
                .foregroundColor(AppColors.textSecondary)
                .frame(width: 110, alignment: .leading)
            Text(waarde)
                .font(AppFont.theSans(size: 16, weight: .semiBold))
                .foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 14)
    }
}
