import SwiftUI

/// Korte start van de testversie: alleen je naam, zodat de app je meteen bij
/// naam noemt. De volledige onboarding staat in het profielmenu.
struct NaamOnboardingView: View {
    @EnvironmentObject var lang: LanguageManager
    @ObservedObject var settings: HomeSettingsModel
    var onKlaar: () -> Void

    @FocusState private var focus: Bool

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
                .onTapGesture { focus = false }

            VStack(spacing: 0) {
                // Compact bovenaan: "Overslaan" moet boven het toetsenbord blijven.
                Spacer().frame(height: 24)

                Image("ill-buurt")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)
                    .padding(.bottom, 24)

                Text(lang.t("naam_welkom"))
                    .font(AppFont.theMix(size: 30, weight: .bold))
                    .foregroundColor(AppColors.darkGrey)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 10)

                Text(lang.t("naam_vraag"))
                    .font(AppFont.theSans(size: 18, weight: .plain))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 28)

                TextField(lang.t("onb_naam_placeholder"), text: $settings.userName)
                    .font(AppFont.theSans(size: 20, weight: .plain))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppDesign.cornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppDesign.cornerRadius)
                            .stroke(focus ? AppColors.groen3 : AppColors.grijs2, lineWidth: focus ? 1.5 : 1)
                    )
                    .focused($focus)
                    .textContentType(.givenName)
                    .submitLabel(.go)
                    .onSubmit(klaar)

                Button(action: klaar) {
                    Text(lang.t("naam_start"))
                        .font(AppFont.theSans(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColors.groen3)
                        .clipShape(RoundedRectangle(cornerRadius: AppDesign.cornerRadius))
                }
                .buttonStyle(.plain)
                .padding(.top, 16)

                Button(action: { settings.userName = ""; klaar() }) {
                    Text(lang.t("onb_skip"))
                        .font(AppFont.theSans(size: 16, weight: .bold))
                        .foregroundColor(AppColors.groen3)
                        .padding(.vertical, 12)
                }
                .padding(.top, 4)

                Spacer()
            }
            .padding(.horizontal, AppDesign.horizontalPadding)
        }
        .onAppear {
            settings.userName = ""
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { focus = true }
            AnalyticsService.screen("naam_onboarding")
        }
    }

    private func klaar() {
        focus = false
        AnalyticsService.setSession(["name": settings.userName.trimmingCharacters(in: .whitespacesAndNewlines)])
        AnalyticsService.track("naam_onboarding_klaar", ["ingevuld": !settings.userName.isEmpty])
        onKlaar()
    }
}

/// Mijn vergunningen (ondernemer). Gebruikt de bestaande vergunningenlijst.
struct VergunningenPageView: View {
    @EnvironmentObject var lang: LanguageManager
    @Binding var isPresented: Bool

    private var safeTop: CGFloat { AppDesign.safeAreaTop }

    var body: some View {
        ZStack(alignment: .topLeading) {
            AppColors.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    Color.clear.frame(height: safeTop + 44)
                    Text(lang.t("ond_business_name"))
                        .font(AppFont.theMix(size: 30, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.horizontal, AppDesign.horizontalPadding)
                    Text(lang.t("ond_kvk_subtitle"))
                        .font(AppFont.theSans(size: 16, weight: .plain))
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.horizontal, AppDesign.horizontalPadding)
                        .padding(.top, -14)
                    VergunningenSection()
                    Spacer().frame(height: 60)
                }
            }
            .bovenVervaging()

            BackCircleButton { withAnimation(.easeInOut(duration: 0.3)) { isPresented = false } }
                .terugknopPlek()
        }
        .ignoresSafeArea(edges: .top)
    }
}
