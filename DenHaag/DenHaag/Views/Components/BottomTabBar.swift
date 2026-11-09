import SwiftUI

struct BottomTabBar: View {
    @EnvironmentObject var lang: LanguageManager
    @EnvironmentObject var versie: VersieManager
    @Binding var selectedTab: MainTabView.Tab
    @State private var animatingTab: MainTabView.Tab?

    var body: some View {
        HStack(spacing: 0) {
            Spacer()
            // Alleen de tabs die de gekozen versie van de app heeft.
            ForEach(versie.current.tabs, id: \.self) { tab in
                switch tab {
                case .home:    tabItem(tab: .home, icon: "home", label: lang.t("tab_home"))
                case .regelen: tabItem(tab: .regelen, icon: "done", label: lang.t("tab_regelen"))
                case .buurt:   tabItem(tab: .buurt, systemIcon: "map", label: lang.t("tab_buurt"))
                case .hulp:    tabItem(tab: .hulp, icon: "help", label: lang.t("tab_hulp"))
                }
                Spacer()
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 6)
        .frame(maxWidth: .infinity)
        // Witte balk met flink afgeronde bovenhoeken (30px) en lichte onderhoeken
        // (6px), met een 1px border #EDEDED die de vorm volgt — conform design
        // (node 2837:1107). De border + zachte schaduw maken de ronding zichtbaar.
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 30,
                bottomLeadingRadius: 6,
                bottomTrailingRadius: 6,
                topTrailingRadius: 30
            )
            .fill(Color.white)
            .overlay(
                UnevenRoundedRectangle(
                    topLeadingRadius: 30,
                    bottomLeadingRadius: 6,
                    bottomTrailingRadius: 6,
                    topTrailingRadius: 30
                )
                .stroke(Color(hex: "EDEDED"), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: -3)
            .shadow(color: Color.black.opacity(0.05), radius: 16, x: 0, y: 2)
            .ignoresSafeArea(edges: .bottom)
        )
        // Menu een fractie lager plaatsen.
        .offset(y: 8)
    }

    private func tabItem(tab: MainTabView.Tab, icon: String? = nil, systemIcon: String? = nil, label: String) -> some View {
        Button {
            guard selectedTab != tab else { return }
            // Eén bron voor de slide: de .animation(value: selectedTab) op de
            // content in MainTabView verzorgt de overgang (geen dubbele curve).
            selectedTab = tab
            // Trigger icon animation
            animatingTab = tab
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                animatingTab = nil
            }
        } label: {
            VStack(spacing: 6) {
                Group {
                    if let icon {
                        Image(icon)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                    } else if let systemIcon {
                        Image(systemName: systemIcon)
                            .resizable()
                            .scaledToFit()
                    }
                }
                .frame(width: 24, height: 24)
                // Icoon: groen wanneer actief, anders grijs.
                .foregroundColor(selectedTab == tab ? AppColors.groen3 : AppColors.textSecondary)
                .modifier(TabIconAnimator(tab: tab, isAnimating: animatingTab == tab))

                // Label: zwart + bold wanneer actief, anders grijs (conform design).
                Text(label)
                    .font(AppFont.theSans(size: 16, weight: selectedTab == tab ? .bold : .plain))
                    .foregroundColor(selectedTab == tab ? .black : AppColors.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tab Icon Animator

struct TabIconAnimator: ViewModifier {
    let tab: MainTabView.Tab
    let isAnimating: Bool
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0
    @State private var yOffset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .offset(y: yOffset)
            .onChange(of: isAnimating) { _, animating in
                if animating {
                    runAnimation()
                }
            }
    }

    private func runAnimation() {
        switch tab {
        case .home:
            // Home: gentle bounce up and back
            withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) {
                yOffset = -6
                scale = 1.15
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    yOffset = 0
                    scale = 1.0
                }
            }

        case .regelen:
            // Regelen (checkmark): scale up with a little rotation like "check!"
            withAnimation(.spring(response: 0.2, dampingFraction: 0.3)) {
                scale = 1.3
                rotation = -10
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) {
                    rotation = 5
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    scale = 1.0
                    rotation = 0
                }
            }

        case .buurt:
            // Buurt (map): subtle pop with a tiny tilt
            withAnimation(.spring(response: 0.22, dampingFraction: 0.35)) {
                scale = 1.2
                rotation = 6
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    scale = 1.0
                    rotation = 0
                }
            }

        case .hulp:
            // Hulp (question mark): pop up from below
            yOffset = 8
            scale = 0.5
            withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
                yOffset = -4
                scale = 1.15
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                    yOffset = 0
                    scale = 1.0
                }
            }
        }
    }
}
