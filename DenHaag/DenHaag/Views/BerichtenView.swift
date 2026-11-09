import SwiftUI

/// Berichten van de gemeente (notificaties), via het belletje op home. Alleen
/// over onderdelen die in de gekozen versie zitten. Tikken markeert als gelezen.
struct BerichtenView: View {
    @EnvironmentObject var lang: LanguageManager
    @EnvironmentObject var versie: VersieManager
    @EnvironmentObject var berichten: BerichtenStore
    @Binding var isPresented: Bool
    @State private var toonVoorkeuren = false

    private var safeTop: CGFloat { AppDesign.safeAreaTop }

    var body: some View {
        ZStack(alignment: .topLeading) {
            AppColors.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Color.clear.frame(height: safeTop + 56)

                    Text(lang.t("berichten_title"))
                        .font(AppFont.theMix(size: 30, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.bottom, 20)

                    let lijst = berichten.zichtbaar(in: versie.current)
                    if lijst.isEmpty {
                        Text(lang.t("berichten_leeg"))
                            .font(AppFont.theSans(size: 17, weight: .plain))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    ForEach(lijst) { bericht in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { berichten.markeerGelezen(bericht.id) }
                        } label: {
                            BerichtRij(bericht: bericht)
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }

                    Button { withAnimation(.easeInOut(duration: 0.25)) { toonVoorkeuren = true } } label: {
                        HStack(spacing: 8) {
                            Image("preferences")
                                .renderingMode(.template)
                                .resizable()
                                .frame(width: 18, height: 18)
                            Text(lang.t("berichten_instellen"))
                                .font(AppFont.theSans(size: 16, weight: .bold))
                        }
                        .foregroundColor(AppColors.groen3)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 24)

                    Spacer().frame(height: 60)
                }
                .padding(.horizontal, AppDesign.horizontalPadding)
            }
            .bovenVervaging()

            AppColors.background
                .frame(height: safeTop + 52)
                .frame(maxWidth: .infinity)
                .allowsHitTesting(false)

            BackCircleButton { withAnimation(.easeInOut(duration: 0.3)) { isPresented = false } }
                .terugknopPlek()

            if toonVoorkeuren {
                BerichtVoorkeurenView(isPresented: $toonVoorkeuren)
                    .transition(.move(edge: .trailing))
                    .zIndex(1)
            }
        }
        .ignoresSafeArea(edges: .top)
        .onAppear { AnalyticsService.screen("berichten") }
    }
}

private struct BerichtRij: View {
    @EnvironmentObject var lang: LanguageManager
    let bericht: Bericht

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: bericht.onderwerp.icoon)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(AppColors.groen3)
                .frame(width: 40, height: 40)
                .background(AppColors.groen1.opacity(0.6))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(bericht.titel)
                        .font(AppFont.theSans(size: 17, weight: bericht.gelezen ? .semiBold : .bold))
                        .foregroundColor(AppColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    if !bericht.gelezen {
                        Circle().fill(AppColors.rood).frame(width: 9, height: 9)
                    }
                }
                Text(bericht.tekst)
                    .font(AppFont.theSans(size: 15, weight: .plain))
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(lang.t(bericht.onderwerp.labelKey)) · \(bericht.wanneer)")
                    .font(AppFont.theSans(size: 13, weight: .plain))
                    .foregroundColor(AppColors.grijs4)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 16)
        .contentShape(Rectangle())
    }
}

/// Welke berichten je wilt krijgen, per onderwerp. Via de berichten of via het
/// profielmenu.
struct BerichtVoorkeurenView: View {
    @EnvironmentObject var lang: LanguageManager
    @EnvironmentObject var versie: VersieManager
    @EnvironmentObject var berichten: BerichtenStore
    @Binding var isPresented: Bool

    private var safeTop: CGFloat { AppDesign.safeAreaTop }

    var body: some View {
        ZStack(alignment: .topLeading) {
            AppColors.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Color.clear.frame(height: safeTop + 56)

                    Text(lang.t("berichten_voorkeuren_title"))
                        .font(AppFont.theMix(size: 30, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.bottom, 8)
                    Text(lang.t("berichten_voorkeuren_sub"))
                        .font(AppFont.theSans(size: 17, weight: .plain))
                        .foregroundColor(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 20)

                    VStack(spacing: 0) {
                        let onderwerpen = BerichtOnderwerp.allCases.filter { versie.current.heeft($0.onderdeel) }
                        ForEach(Array(onderwerpen.enumerated()), id: \.element.id) { i, onderwerp in
                            if i > 0 { Divider().padding(.leading, 52) }
                            HStack(spacing: 14) {
                                Image(systemName: onderwerp.icoon)
                                    .font(.system(size: 17))
                                    .foregroundColor(AppColors.groen3)
                                    .frame(width: 24)
                                Text(lang.t(onderwerp.labelKey))
                                    .font(AppFont.theSans(size: 17, weight: .plain))
                                    .foregroundColor(AppColors.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Toggle("", isOn: .constant(berichten.aan[onderwerp] ?? true))
                                    .labelsHidden()
                                    .tint(AppColors.groen3)
                                    .allowsHitTesting(false)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                            // Hele rij schakelt (een losse schakelaar mist soms een tik).
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    berichten.aan[onderwerp] = !(berichten.aan[onderwerp] ?? true)
                                }
                            }
                        }
                    }
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppDesign.cornerRadius))
                    .overlay(RoundedRectangle(cornerRadius: AppDesign.cornerRadius).stroke(AppColors.grijs2, lineWidth: 1))

                    Spacer().frame(height: 60)
                }
                .padding(.horizontal, AppDesign.horizontalPadding)
            }
            .bovenVervaging()

            AppColors.background
                .frame(height: safeTop + 52)
                .frame(maxWidth: .infinity)
                .allowsHitTesting(false)

            BackCircleButton { withAnimation(.easeInOut(duration: 0.25)) { isPresented = false } }
                .terugknopPlek()
        }
        .ignoresSafeArea(edges: .top)
    }
}

/// Nagebootste pushmelding bovenin het scherm. Tikken opent de berichten.
struct PushBannerView: View {
    @EnvironmentObject var lang: LanguageManager
    let bericht: Bericht
    var onTik: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image("ill-melding")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .padding(3)
                .background(AppColors.geel3)
                .clipShape(RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(lang.t("push_app"))
                        .font(AppFont.theSans(size: 13, weight: .semiBold))
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    Text(lang.t("push_nu"))
                        .font(AppFont.theSans(size: 13, weight: .plain))
                        .foregroundColor(AppColors.grijs4)
                }
                Text(bericht.titel)
                    .font(AppFont.theSans(size: 16, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                Text(bericht.tekst)
                    .font(AppFont.theSans(size: 15, weight: .plain))
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(2)
            }
        }
        .padding(14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.15), radius: 16, y: 6)
        .padding(.horizontal, 10)
        .onTapGesture(perform: onTik)
    }
}
