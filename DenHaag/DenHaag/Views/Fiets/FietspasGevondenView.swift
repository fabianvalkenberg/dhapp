import SwiftUI

/// Na het scannen: welke pas is gevonden, een bijnaam geven en toevoegen.
/// Niet in Figma; het pasblok is hetzelfde als op het detailscherm (C4).
/// Veld en knop staan bovenaan, zodat het toetsenbord ze niet bedekt.
struct FietspasGevondenView: View {
    @EnvironmentObject var lang: LanguageManager
    let pas: Fietspas
    var onToevoegen: (Fietspas) -> Void
    var onTerug: () -> Void

    @State private var bijnaam = ""
    @FocusState private var focus: Bool

    private var safeTop: CGFloat { AppDesign.safeAreaTop }

    /// "Mijn fiets", "Mijn bakfiets", …
    static func standaardBijnaam(_ type: FietspasType, _ lang: LanguageManager) -> String {
        String(format: lang.t("fp_bijnaam_standaard"), lang.t(type.naamKey).lowercased())
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            AppColors.warmGrijs.ignoresSafeArea()
                .onTapGesture { focus = false }

            VStack(alignment: .leading, spacing: 12) {
                Color.clear.frame(height: safeTop + 58)

                HStack(spacing: 16) {
                    FietspasKaartView(pas: pas, schaal: 0.36)
                    VStack(alignment: .leading, spacing: 6) {
                        FietspasLabel(pas: pas)
                        Text("\(lang.t(pas.type.naamKey)) · \(lang.t(pas.type.kleurBijvoeglijkKey)) \(lang.t("fp_pas"))")
                            .font(AppFont.theSans(size: 16, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                        Text(lang.t("fp_gevonden_sub"))
                            .font(AppFont.theSans(size: 14, weight: .plain))
                            .foregroundColor(FietspasKleur.tekstZacht)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.leading, 12)
                .padding(.trailing, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 6) {
                    Text(lang.t("fp_bijnaam"))
                        .font(AppFont.theSans(size: 16, weight: .plain))
                        .foregroundColor(FietspasKleur.tekstZacht)
                    TextField(Self.standaardBijnaam(pas.type, lang), text: $bijnaam)
                        .font(AppFont.theSans(size: 16, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                        .focused($focus)
                        .submitLabel(.done)
                        .onSubmit { voegToe() }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(focus ? AppColors.groen3 : .clear, lineWidth: 1.5)
                )

                FietspasHoofdknop(titel: lang.t("fp_gevonden_knop"), action: voegToe)
                    .padding(.top, 12)

                Spacer()
            }
            .padding(.horizontal, AppDesign.horizontalPadding)

            HStack(spacing: 12) {
                FietspasRondeKnop(icoon: "fp-terug", grootte: 22, action: onTerug)
                Text(lang.t("fp_gevonden_title"))
                    .font(AppFont.theMix(size: 24, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
            }
            .padding(.leading, AppDesign.horizontalPadding)
            .padding(.top, safeTop + 8)
        }
        .ignoresSafeArea(edges: .top)
        .onAppear { AnalyticsService.screen("fietspas_gevonden") }
    }

    private func voegToe() {
        focus = false
        var nieuw = pas
        nieuw.bijnaam = bijnaam.trimmingCharacters(in: .whitespacesAndNewlines)
        onToevoegen(nieuw)
    }
}
