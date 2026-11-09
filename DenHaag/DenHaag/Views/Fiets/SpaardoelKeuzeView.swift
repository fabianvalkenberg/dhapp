import SwiftUI

/// Je spaardoel kiezen: een kop koffie of je club. Dit is het onderdeel van
/// Dappre dat in de uitgebreide versies in de Den Haag-app zelf zit. Kies je
/// "je club", dan volgen de clubs: eerst die bij jou om de hoek, daarna de rest.
/// De clubs zijn verzonnen.
struct SpaardoelKeuzeView: View {
    @EnvironmentObject var lang: LanguageManager
    @Environment(\.dismiss) private var dismiss
    @Binding var spaardoelRaw: String
    /// Gekozen clubs als één tekst met "|" ertussen.
    @Binding var clubsRaw: String

    private var spaardoel: Spaardoel { Spaardoel(rawValue: spaardoelRaw) ?? .geen }
    private var gekozen: Set<String> { Set(clubsRaw.split(separator: "|").map(String.init)) }

    private func kies(_ doel: Spaardoel) {
        withAnimation(.easeInOut(duration: 0.2)) { spaardoelRaw = doel.rawValue }
        AnalyticsService.track("spaardoel_kies", ["doel": doel.rawValue])
    }

    private func toggle(_ club: String) {
        var set = gekozen
        if set.contains(club) { set.remove(club) } else { set.insert(club) }
        // Volgorde van de lijst aanhouden, zodat de pas steeds hetzelfde toont.
        clubsRaw = DappreClubs.all.filter(set.contains).joined(separator: "|")
        AnalyticsService.track("dappre_club_toggle", ["club": club])
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(lang.t("dappre_powered"))
                        .font(AppFont.theSans(size: 14, weight: .bold))
                        .foregroundColor(AppColors.groen4)
                        .padding(.bottom, 6)

                    Text(lang.t("spaardoel_question"))
                        .font(AppFont.theMix(size: 26, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 20)

                    lijst([
                        (lang.t("spaardoel_koffie"), spaardoel == .koffie, { kies(.koffie) }),
                        (lang.t("spaardoel_club"), spaardoel == .club, { kies(.club) }),
                        (lang.t("spaardoel_geen"), spaardoel == .geen, { kies(.geen) }),
                    ])

                    if spaardoel == .club {
                        Text(lang.t("clubs_title"))
                            .font(AppFont.theMix(size: 22, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 32)
                            .padding(.bottom, 6)

                        Text(lang.t("clubs_intro"))
                            .font(AppFont.theSans(size: 16, weight: .plain))
                            .foregroundColor(AppColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        kop(lang.t("clubs_nearby"), icon: "location.fill")
                        lijst(DappreClubs.dichtbij.map { club in (club, gekozen.contains(club), { toggle(club) }) })

                        kop(lang.t("clubs_more"), icon: nil)
                        lijst(DappreClubs.overig.map { club in (club, gekozen.contains(club), { toggle(club) }) })
                    }
                }
            }

            Button { dismiss() } label: {
                Text(lang.t("clubs_done"))
                    .font(AppFont.theSans(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppColors.groen3)
                    .clipShape(RoundedRectangle(cornerRadius: AppDesign.cornerRadius))
            }
            .padding(.top, 16)
        }
        .padding(AppDesign.horizontalPadding)
        .padding(.top, 20)
        .background(AppColors.background)
    }

    private func kop(_ titel: String, icon: String?) -> some View {
        HStack(spacing: 8) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.groen3)
            }
            Text(titel)
                .font(AppFont.theSans(size: 16, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
        }
        .padding(.top, 24)
        .padding(.bottom, 10)
    }

    /// Kader met rijen: titel, aangevinkt of niet, en wat tikken doet.
    private func lijst(_ rijen: [(String, Bool, () -> Void)]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(rijen.enumerated()), id: \.offset) { index, rij in
                Button(action: rij.2) {
                    HStack(spacing: 16) {
                        Text(rij.0)
                            .font(AppFont.theSans(size: 18, weight: rij.1 ? .bold : .plain))
                            .foregroundColor(AppColors.textPrimary)
                            .multilineTextAlignment(.leading)

                        Spacer()

                        if rij.1 {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(AppColors.groen3)
                        } else {
                            Circle()
                                .stroke(AppColors.grijs2, lineWidth: 1.5)
                                .frame(width: 22, height: 22)
                        }
                    }
                    .contentShape(Rectangle())
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .buttonStyle(.plain)

                if index < rijen.count - 1 {
                    Divider().padding(.leading, 20)
                }
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.grijs2, lineWidth: 1)
        )
    }
}
