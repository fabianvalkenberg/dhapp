import SwiftUI
import FirebaseCore

@main
struct DenHaagApp: App {
    @StateObject private var languageManager = LanguageManager()
    // Eén gedeelde instantie voor onboarding én home, zodat de gekozen tegels
    // direct doorwerken (niet alleen via een UserDefaults-omweg).
    @StateObject private var settings = HomeSettingsModel()
    @StateObject private var versie = VersieManager()
    @StateObject private var afspraak = AfspraakStore()
    @StateObject private var berichten = BerichtenStore()
    @StateObject private var rol = RolManager()
    @StateObject private var melding = MeldingStore()
    @State private var showSplash = true
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Taal staat tijdelijk uit: altijd Nederlands, ook als er eerder iets anders is gekozen.
        UserDefaults.standard.set(AppLanguage.nl.rawValue, forKey: "app_language")
        FirebaseApp.configure()
        // Start de analytics-sessie zodra de app draait.
        AnalyticsService.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                // De app opent direct op home. De onboarding start je zelf
                // vanuit het profielmenu (SettingsView).
                MainTabView(settings: settings)
                .environmentObject(languageManager)
                .environmentObject(versie)
                .environmentObject(afspraak)
                .environmentObject(berichten)
                .environmentObject(rol)
                .environmentObject(melding)
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
                // Splash screen: logo, daarna naar home
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    showSplash = false
                }
            }
        }
    }
}
