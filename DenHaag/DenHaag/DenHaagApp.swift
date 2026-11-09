import SwiftUI
import FirebaseCore

@main
struct DenHaagApp: App {
    @StateObject private var languageManager = LanguageManager()
    // Eén gedeelde instantie voor onboarding én home, zodat de gekozen tegels
    // direct doorwerken (niet alleen via een UserDefaults-omweg).
    @StateObject private var settings = HomeSettingsModel()
    // In-memory (geen @AppStorage): zo wordt de onboarding bij élke koude start
    // opnieuw getoond — handig voor demo's — maar blijf je tijdens gebruik in de app.
    @State private var didCompleteOnboarding = false
    @State private var showSplash = true
    @Environment(\.scenePhase) private var scenePhase

    init() {
        FirebaseApp.configure()
        // Start de analytics-sessie zodra de app draait.
        AnalyticsService.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                Group {
                    if didCompleteOnboarding {
                        MainTabView(settings: settings)
                    } else {
                        OnboardingView(
                            settings: settings,
                            onFinish: {
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    didCompleteOnboarding = true
                                }
                            }
                        )
                    }
                }
                .environmentObject(languageManager)
                .opacity(showSplash ? 0 : 1)

                if showSplash {
                    SplashView()
                        .transition(.opacity)
                }
            }
            .preferredColorScheme(.light)
            .animation(.easeInOut(duration: 0.6), value: showSplash)
            .onChange(of: scenePhase) { _, phase in
                // Bij naar de achtergrond gaan: eindsamenvatting wegschrijven.
                if phase == .background { AnalyticsService.shared.endSession() }
            }
            .onAppear {
                #if DEBUG
                FontDebug.printAllFonts()
                #endif
                // Splash screen: show logo, then fade to onboarding/home
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    showSplash = false
                }
            }
        }
    }
}
