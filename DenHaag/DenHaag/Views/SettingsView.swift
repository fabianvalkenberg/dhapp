import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var lang: LanguageManager
    @ObservedObject var settings: HomeSettingsModel
    @Binding var isPresented: Bool
    @State private var showLanguageSelection = false
    @State private var showUitgangspunten = false
    @State private var showResetConfirm = false
    @State private var showFeedback = false

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
                            AppColors.groen3

                            // Diagonal overlay for depth
                            GeometryReader { geo in
                                Path { path in
                                    path.move(to: CGPoint(x: 0, y: geo.size.height * 0.3))
                                    path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height * 0.6))
                                    path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                                    path.addLine(to: CGPoint(x: 0, y: geo.size.height))
                                    path.closeSubpath()
                                }
                                .fill(AppColors.groen4)
                            }

                            VStack(spacing: 12) {
                                Spacer()
                                    .frame(height: safeTop + 50)

                                // Profile photo
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 120, height: 120)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 50, height: 50)
                                            .foregroundColor(.white.opacity(0.7))
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 3)
                                    )

                                // Name
                                Text(lang.t("name_anne"))
                                    .font(AppFont.theMix(size: 22, weight: .bold))
                                    .foregroundColor(.white)

                                Text(lang.t("surname"))
                                    .font(AppFont.bodyRegular())
                                    .foregroundColor(.white.opacity(0.8))

                                // BSN
                                HStack(spacing: 8) {
                                    Text("BSN: 123456788")
                                        .font(AppFont.bodyRegular())
                                        .foregroundColor(.white.opacity(0.8))

                                    Button {
                                        UIPasteboard.general.string = "123456788"
                                    } label: {
                                        Image(systemName: "doc.on.doc")
                                            .font(.system(size: 16))
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }

                                Spacer()
                                    .frame(height: 20)
                            }
                        }
                        .frame(height: 340 + safeTop)

                        // Menu items
                        VStack(spacing: 0) {
                            SettingsMenuItem(icon: "user", title: lang.t("personal_data"))
                            SettingsMenuItem(icon: "preferences", title: lang.t("settings"))
                            Button {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    showLanguageSelection = true
                                }
                            } label: {
                                SettingsMenuItem(systemIcon: "textformat.size", title: lang.t("language"), trailing: lang.current.displayName)
                            }
                            .buttonStyle(.plain)
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
                .padding(.top, safeTop + 8)
            }

            // Language selection overlay
            if showLanguageSelection {
                LanguageSelectionView(isPresented: $showLanguageSelection)
                    .transition(.move(edge: .trailing))
                    .zIndex(1)
            }

            // Uitgangspunten overlay
            if showUitgangspunten {
                UitgangspuntenView(isPresented: $showUitgangspunten)
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
        .alert(lang.t("reset_demo"), isPresented: $showResetConfirm) {
            Button(lang.t("cancel"), role: .cancel) { }
            Button(lang.t("reset_demo_confirm"), role: .destructive) { resetAndQuit() }
        } message: {
            Text(lang.t("reset_demo_msg"))
        }
    }

    /// Wist de deelnemer-data en sluit de app af. Omdat de onboarding-gate een
    /// in-memory `@State` is, start de app daarna gegarandeerd schoon op bij de
    /// onboarding (een echte koude start, niet alleen schorsen/hervatten).
    private func resetAndQuit() {
        // Sessie netjes afsluiten vóór de app stopt.
        AnalyticsService.shared.endSession()
        let d = UserDefaults.standard
        d.removeObject(forKey: "selectedTileIDs")
        d.removeObject(forKey: "werkAddress")
        d.removeObject(forKey: "app_language")
        d.removeObject(forKey: "userName")
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
