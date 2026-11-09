import SwiftUI

/// "Hoe kom ik aan een fietspas?" Niet in Figma; zelfde stijl als C4.
/// Drie stappen, de pastypes met hun kleur, en door naar de kaart of de scanner.
struct FietspasIntroView: View {
    @EnvironmentObject var lang: LanguageManager
    var onTerug: () -> Void
    var onScan: () -> Void
    var onStallingen: () -> Void

    private var safeTop: CGFloat { AppDesign.safeAreaTop }

    private let stappen: [(String, String)] = [
        ("fp_intro_stap1", "fp_intro_stap1_sub"),
        ("fp_intro_stap2", "fp_intro_stap2_sub"),
        ("fp_intro_stap3", "fp_intro_stap3_sub"),
    ]

    var body: some View {
        ZStack(alignment: .topLeading) {
            AppColors.warmGrijs.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    Color.clear.frame(height: safeTop + 58)

                    // Stappen
                    VStack(spacing: 0) {
                        ForEach(Array(stappen.enumerated()), id: \.offset) { i, stap in
                            if i > 0 { FietspasKleur.vlak.frame(height: 1) }
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(i + 1)")
                                    .font(AppFont.theSans(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 26, height: 26)
                                    .background(AppColors.groen3)
                                    .clipShape(Circle())
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(lang.t(stap.0))
                                        .font(AppFont.theSans(size: 16, weight: .bold))
                                        .foregroundColor(AppColors.textPrimary)
                                    Text(lang.t(stap.1))
                                        .font(AppFont.theSans(size: 14, weight: .plain))
                                        .foregroundColor(FietspasKleur.tekstZacht)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                        }
                    }
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Pastypes: de kleur onderaan je pas hoort bij je voertuig.
                    VStack(alignment: .leading, spacing: 12) {
                        Text(lang.t("fp_intro_types"))
                            .font(AppFont.theSans(size: 16, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                        Text(lang.t("fp_intro_types_sub"))
                            .font(AppFont.theSans(size: 14, weight: .plain))
                            .foregroundColor(FietspasKleur.tekstZacht)
                            .fixedSize(horizontal: false, vertical: true)
                        VStack(spacing: 8) {
                            ForEach(FietspasType.allCases) { type in
                                HStack(spacing: 10) {
                                    Image(type.icoon)
                                        .resizable()
                                        .frame(width: type.icoonBreedte * 0.5, height: 18)
                                        .frame(width: 40, height: 28)
                                        .background(type.kleur)
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                    Text(lang.t(type.naamKey))
                                        .font(AppFont.theSans(size: 15, weight: .plain))
                                        .foregroundColor(AppColors.textPrimary)
                                    Spacer()
                                    Text(lang.t(type.kleurKey))
                                        .font(AppFont.theSans(size: 14, weight: .plain))
                                        .foregroundColor(FietspasKleur.tekstZacht)
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    FietspasHoofdknop(titel: lang.t("fp_scan_knop"), action: onScan)
                        .padding(.top, 12)
                    FietspasOmlijndeKnop(titel: lang.t("fp_intro_kaart"), action: onStallingen)

                    Spacer().frame(height: 130)
                }
                .padding(.horizontal, AppDesign.horizontalPadding)
            }

            HStack(spacing: 12) {
                FietspasRondeKnop(icoon: "fp-terug", grootte: 22, action: onTerug)
                Text(lang.t("fp_intro_title"))
                    .font(AppFont.theMix(size: 24, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, AppDesign.horizontalPadding)
            .padding(.top, safeTop + 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.warmGrijs.frame(height: safeTop + 60).offset(y: -8), alignment: .top)
        }
        .ignoresSafeArea(edges: .top)
        .onAppear { AnalyticsService.screen("fietspas_intro") }
    }
}
