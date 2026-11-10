import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var lang: LanguageManager
    @ObservedObject var settings: HomeSettingsModel
    @Binding var isPresented: Bool
    @State private var showUitgangspunten = false
    @State private var showResetConfirm = false
    @State private var showFeedback = false
    @State private var showVersie = false
    @State private var showOnboarding = false
    @EnvironmentObject var versie: VersieManager
    @EnvironmentObject var rol: RolManager
    @State private var showBerichtVoorkeuren = false

    private var safeTop: CGFloat { AppDesign.safeAreaTop }

    var body: some View {
        ZStack {
            // Main settings content
            ZStack(alignment: .top) {
                AppColors.background
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Green header with profile - extends under status bar
                        ZStack {
                            // Green facetten background
                            // Inwoner groen, ondernemer blauw.
                            (rol.isOndernemer ? AppColors.blauw3 : AppColors.groen3)

                            // Diagonal overlay for depth
                            GeometryReader { geo in
                                Path { path in
                                    path.move(to: CGPoint(x: 0, y: geo.size.height * 0.3))
                                    path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height * 0.6))
                                    path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                                    path.addLine(to: CGPoint(x: 0, y: geo.size.height))
                                    path.closeSubpath()
                                }
                                .fill(rol.isOndernemer ? Color(hex: "0B4C82") : AppColors.groen4)
                            }

                            // Swipe tussen jezelf en je zaak; de kleur volgt mee.
                            VStack(spacing: 14) {
                                Spacer().frame(height: safeTop + 44)
                                TabView(selection: Binding(
                                    get: { rol.rol },
                                    set: { nieuw in
                                        UISelectionFeedbackGenerator().selectionChanged()
                                        withAnimation(.easeInOut(duration: 0.35)) { rol.rol = nieuw }
                                    })) {
                                    profielPagina(ondernemer: false).tag(RolManager.Rol.inwoner)
                                    profielPagina(ondernemer: true).tag(RolManager.Rol.ondernemer)
                                }
                                .tabViewStyle(.page(indexDisplayMode: .never))
                                .frame(height: 290)

                                // Paginapuntjes + hint dat je kunt vegen
                                HStack(spacing: 8) {
                                    ForEach([RolManager.Rol.inwoner, .ondernemer], id: \.self) { r in
                                        Capsule()
                                            .fill(Color.white.opacity(rol.rol == r ? 1 : 0.4))
                                            .frame(width: rol.rol == r ? 22 : 8, height: 8)
                                    }
                                }
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: rol.rol)
                                Text(lang.t(rol.isOndernemer ? "rol_veeg_terug" : "rol_veeg_zaak"))
                                    .font(AppFont.theSans(size: 14, weight: .plain))
                                    .foregroundColor(.white.opacity(0.75))
                                Spacer().frame(height: 18)
                            }
                        }
                        .frame(height: 400 + safeTop)
                        .animation(.easeInOut(duration: 0.35), value: rol.rol)

                        // Menu items
                        VStack(spacing: 0) {
                            SettingsMenuItem(icon: "user", title: lang.t("personal_data"))
                            SettingsMenuItem(icon: "preferences", title: lang.t("settings"))
                            // Taalkeuze staat tijdelijk uit: de app is alleen Nederlands.
                            SettingsMenuItem(icon: "bell", title: lang.t("notifications"))

                            // Uitgangspunten
                            Button {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    showUitgangspunten = true
                                }
                            } label: {
                                SettingsMenuItem(systemIcon: "lightbulb", title: lang.t("uitgangspunten"))
                            }
                            .buttonStyle(.plain)

                            // Onboarding starten (voor demo's en tests)
                            Button {
                                showOnboarding = true
                            } label: {
                                SettingsMenuItem(systemIcon: "play.circle", title: lang.t("onboarding_start"))
                            }
                            .buttonStyle(.plain)

                            // Versie van de app (voor demo's)
                            Button {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    showVersie = true
                                }
                            } label: {
                                SettingsMenuItem(systemIcon: "square.stack.3d.up", title: lang.t("versie_title"), trailing: lang.t(versie.current.titleKey))
                            }
                            .buttonStyle(.plain)

                            // Feedback (testverslag)
                            Button {
                                AnalyticsService.track("open_feedback")
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    showFeedback = true
                                }
                            } label: {
                                SettingsMenuItem(systemIcon: "star", title: "Wat vond je hiervan?", isLast: true)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(AppDesign.horizontalPadding)

                        // Demo resetten + afsluiten — voor onderzoekers tussen
                        // sessies. Wist de deelnemer-data en beëindigt de app, zodat
                        // de volgende start weer schoon bij de onboarding begint.
                        Button {
                            showResetConfirm = true
                        } label: {
                            HStack(spacing: 16) {
                                Image(systemName: "arrow.counterclockwise.circle")
                                    .font(.system(size: 20))
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(AppColors.rood)
                                Text(lang.t("reset_demo"))
                                    .font(AppFont.bodyRegular())
                                    .foregroundColor(AppColors.rood)
                                Spacer()
                            }
                            .padding(18)
                            .background(Color.white)
                            .cornerRadius(AppDesign.cornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppDesign.cornerRadius)
                                    .stroke(AppColors.rood.opacity(0.25), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, AppDesign.horizontalPadding)
                        .padding(.top, 24)
                        .padding(.bottom, 40)
                    }
                }
                .ignoresSafeArea(edges: .top)

                // Back button overlay
                HStack {
                    Button {
                        isPresented = false
                    } label: {
                        Image("arrow-left")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.horizontal, AppDesign.horizontalPadding)
                .padding(.top, 6)
            }

            // Uitgangspunten overlay
            if showUitgangspunten {
                UitgangspuntenView(isPresented: $showUitgangspunten)
                    .transition(.move(edge: .trailing))
                    .zIndex(1)
            }

            if showBerichtVoorkeuren {
                BerichtVoorkeurenView(isPresented: $showBerichtVoorkeuren)
                    .transition(.move(edge: .trailing))
                    .zIndex(1)
            }

            // Versie-keuze overlay
            if showVersie {
                VersieSelectionView(isPresented: $showVersie)
                    .transition(.move(edge: .trailing))
                    .zIndex(1)
            }

            // Feedback overlay
            if showFeedback {
                FeedbackView(isPresented: $showFeedback)
                    .transition(.move(edge: .trailing))
                    .zIndex(1)
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            // Na afloop terug naar home, zodat je de gekozen tegels meteen ziet.
            OnboardingView(settings: settings, onFinish: {
                showOnboarding = false
                isPresented = false
            })
            .environmentObject(lang)
            .environmentObject(versie)
        }
        .onChange(of: showOnboarding) { _, v in if v { AnalyticsService.track("open_onboarding") } }
        .alert(lang.t("reset_demo"), isPresented: $showResetConfirm) {
            Button(lang.t("cancel"), role: .cancel) { }
            Button(lang.t("reset_demo_confirm"), role: .destructive) { resetAndQuit() }
        } message: {
            Text(lang.t("reset_demo_msg"))
        }
    }

    /// Eén kant van het profiel: jij (BSN) of je zaak (KvK).
    private func profielPagina(ondernemer: Bool) -> some View {
        VStack(spacing: 12) {
            Circle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 120, height: 120)
                .overlay(
                    Image(systemName: ondernemer ? "storefront.fill" : "person.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.white.opacity(0.7))
                )
                .overlay(Circle().stroke(Color.white, lineWidth: 3))

            Text(ondernemer ? lang.t("ond_business_name") : settings.greetingName)
                .font(AppFont.theMix(size: 22, weight: .bold))
                .foregroundColor(.white)

            Text(ondernemer ? lang.t("ond_profiel_sub") : lang.t("surname"))
                .font(AppFont.bodyRegular())
                .foregroundColor(.white.opacity(0.8))

            HStack(spacing: 8) {
                Text(ondernemer ? "KvK: 87654321" : "BSN: 123456788")
                    .font(AppFont.bodyRegular())
                    .foregroundColor(.white.opacity(0.8))
                Button {
                    UIPasteboard.general.string = ondernemer ? "87654321" : "123456788"
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// Wist de deelnemer-data en sluit de app af, zodat de volgende start
    /// schoon begint (een echte koude start, niet alleen schorsen/hervatten).
    private func resetAndQuit() {
        // Sessie netjes afsluiten vóór de app stopt.
        AnalyticsService.shared.endSession()
        let d = UserDefaults.standard
        d.removeObject(forKey: "selectedTileIDs")
        d.removeObject(forKey: "werkAddress")
        d.removeObject(forKey: "app_language")
        d.removeObject(forKey: "userName")
        d.removeObject(forKey: "spaardoel")
        d.removeObject(forKey: "dappreClubs")
        d.removeObject(forKey: FietspasStore.key)
        d.removeObject(forKey: "berichtVoorkeuren")
        d.synchronize()
        // Korte vertraging zodat de alert netjes sluit voor de app stopt.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            exit(0)
        }
    }
}

struct SettingsMenuItem: View {
    var icon: String? = nil
    var systemIcon: String? = nil
    let title: String
    var trailing: String? = nil
    var isLast: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                if let icon = icon {
                    Image(icon)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(AppColors.textSecondary)
                } else if let systemIcon = systemIcon {
                    Image(systemName: systemIcon)
                        .font(.system(size: 20))
                        .frame(width: 24, height: 24)
                        .foregroundColor(AppColors.textSecondary)
                }

                Text(title)
                    .font(AppFont.bodyRegular())
                    .foregroundColor(AppColors.textPrimary)

                Spacer()

                if let trailing = trailing {
                    Text(trailing)
                        .font(AppFont.theSans(size: 14, weight: .plain))
                        .foregroundColor(AppColors.textSecondary)
                }

                Image("arrow-right")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.vertical, 18)

            if !isLast {
                Divider()
            }
        }
        .background(Color.white)
    }
}
