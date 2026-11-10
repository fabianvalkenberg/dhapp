import SwiftUI

// MARK: - Dappre-uitleg (gedeeld door detailscherm en popup)

struct DappreUitleg: View {
    @EnvironmentObject var lang: LanguageManager
    var icoonMaat: CGFloat
    var titelMaat: CGFloat

    private let stappen: [(String, String)] = [
        ("dappre_stap1", "dappre_stap1_sub"),
        ("dappre_stap2", "dappre_stap2_sub"),
        ("dappre_stap3", "dappre_stap3_sub"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: 0) {
                Image("fp-dappre")
                    .resizable()
                    .frame(width: icoonMaat, height: icoonMaat)
                    .clipShape(RoundedRectangle(cornerRadius: icoonMaat < 100 ? 16 : 24))
                Text(lang.t("dappre_titel"))
                    .font(AppFont.theMix(size: titelMaat, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)
                Text(lang.t("dappre_onderregel"))
                    .font(AppFont.theSans(size: 17, weight: .plain))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 32)
                    .padding(.top, 10)
            }
            .frame(maxWidth: .infinity)

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
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.grijs2, lineWidth: 1))
            .padding(.top, 24)
        }
    }
}

// MARK: - Detailscherm "Sparen met Dappre"

struct FietspasDappreView: View {
    @EnvironmentObject var lang: LanguageManager
    @Environment(\.openURL) private var openURL
    var onTerug: () -> Void

    private var safeTop: CGFloat { AppDesign.safeAreaTop }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Color.clear.frame(height: safeTop + 58)
                        DappreUitleg(icoonMaat: 104, titelMaat: 32)
                            .padding(.horizontal, AppDesign.horizontalPadding)
                        Spacer().frame(height: 40)
                    }
                }
                VStack(spacing: 0) {
                    Divider()
                    FpOnderknoppen(
                        knop: lang.t("dappre_knop"),
                        link: lang.t("dappre_link"),
                        onKnop: {
                            AnalyticsService.track("dappre_download")
                            openURL(DappreClubs.url)
                        },
                        onLink: {
                            AnalyticsService.track("dappre_meer")
                            openURL(DappreClubs.url)
                        }
                    )
                }
            }

            HStack(spacing: 12) {
                BackCircleButton(action: onTerug)
                Spacer()
            }
            .padding(.leading, AppDesign.horizontalPadding)
            .padding(.top, safeTop + AppDesign.terugknopTop)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.frame(height: safeTop + 60).offset(y: -8), alignment: .top)
        }
        .ignoresSafeArea(edges: .top)
        .onAppear { AnalyticsService.screen("dappre") }
    }
}

// MARK: - Pop-up "Sparen met Dappre"

struct DapprePopup: View {
    @EnvironmentObject var lang: LanguageManager
    @Environment(\.openURL) private var openURL
    var onSluit: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(action: onSluit) {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                            .frame(width: BackCircleButton.maat, height: BackCircleButton.maat)
                            .background(Color(hex: "F2F2F1"))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, AppDesign.horizontalPadding)
                .padding(.top, 12)

                DappreUitleg(icoonMaat: 72, titelMaat: 28)
                    .padding(.horizontal, AppDesign.horizontalPadding)
                    .padding(.top, 4)

                Spacer(minLength: 0)

                VStack(spacing: 0) {
                    FpOnderknoppen(
                        knop: lang.t("dappre_knop"),
                        link: nil,
                        onKnop: {
                            AnalyticsService.track("dappre_download")
                            openURL(DappreClubs.url)
                        },
                        onLink: {}
                    )
                    Button {
                        onSluit()
                    } label: {
                        Text(lang.t("dappre_nu_niet"))
                            .font(AppFont.theSans(size: 16, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, AppDesign.horizontalPadding)
                    .padding(.bottom, 8)
                    .padding(.top, 6)
                }
            }
        }
    }
}
