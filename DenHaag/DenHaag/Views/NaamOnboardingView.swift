import SwiftUI

/// Korte start van de testversie: alleen je naam, zodat de app je meteen bij
/// naam noemt. De volledige onboarding staat in het profielmenu.
struct NaamOnboardingView: View {
    @EnvironmentObject var lang: LanguageManager
    @ObservedObject var settings: HomeSettingsModel
    var onKlaar: () -> Void

    @FocusState private var focus: Bool

    private var safeTop: CGFloat { AppDesign.safeAreaTop }

    /// "Hi jij," wordt live "Hi Anne," terwijl je typt (Figma variant A).
    private var groet: String {
        let naam = settings.userName.trimmingCharacters(in: .whitespacesAndNewlines)
        return naam.isEmpty ? lang.t("naam_hi_jij") : String(format: lang.t("naam_hi"), naam)
    }

    /// Design review 2026-11, variant A "Geel vlak": dezelfde gele kop als home,
    /// zodat de eerste indruk meteen aansluit op wat je daarna ziet.
    var body: some View {
        ZStack(alignment: .top) {
            AppColors.background.ignoresSafeArea()
                .onTapGesture { focus = false }

            VStack(spacing: 0) {
                gelekop

                VStack(spacing: 0) {
                    TextField(lang.t("onb_naam_placeholder"), text: $settings.userName)
                        .font(AppFont.theSans(size: 18, weight: .plain))
                        .padding(.horizontal, 18)
                        .frame(height: 59)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
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
                            .frame(height: 55)
                            .background(AppColors.groen3)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 16)

                    Button(action: { settings.userName = ""; klaar() }) {
                        Text(lang.t("onb_skip"))
                            .font(AppFont.theSans(size: 17, weight: .bold))
                            .foregroundColor(AppColors.groen3)
                            .padding(.vertical, 8)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, AppDesign.horizontalPadding)
                .padding(.top, 28)

                Spacer(minLength: 0)
            }
        }
        .ignoresSafeArea(edges: .top)
        // Het toetsenbord mag de kop niet samendrukken; alles past erboven.
        .ignoresSafeArea(.keyboard)
        .onAppear {
            settings.userName = ""
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { focus = true }
            AnalyticsService.screen("naam_onboarding")
        }
    }

    private var gelekop: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(groet)
                .font(AppFont.theMix(size: 38, weight: .extraBold))
                .foregroundColor(Color(hex: "1D1A0D"))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .animation(.easeOut(duration: 0.15), value: groet)
            Text(lang.t("naam_vraag"))
                .font(AppFont.theMix(size: 22, weight: .bold))
                .foregroundColor(Color(hex: "1D1A0D"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppDesign.horizontalPadding)
        .padding(.top, safeTop + 50)
        // Figma: geel vlak loopt tot 257 pt onder de statusbalk, met de boog van home.
        .frame(height: safeTop + 257, alignment: .top)
        .background(
            // Zelfde schaal en uitsnede als de home-kop (HeaderView), die ca.
            // 468 pt hoog is; anders lijken de facetten ingezoomd.
            GeometryReader { geo in
                let homeHoogte: CGFloat = 468
                Image("facetten-geel")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width * 1.4, height: homeHoogte * 1.4)
                    .position(x: geo.size.width / 2, y: homeHoogte / 2)
            }
            .clipped()
        )
        .overlay(alignment: .bottom) {
            BottomTransitionShape(isLarge: true)
                .fill(AppColors.background)
                .frame(height: 50)
                .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
        .onTapGesture { focus = false }
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
