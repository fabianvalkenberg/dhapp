import SwiftUI
import UIKit

/// De pas schermvullend, om te laten scannen bij de stalling. Vliegt vanaf de
/// plek waar je tikte naar het midden en wordt groter; ondertussen gaat de
/// helderheid van het scherm omhoog. Sluiten speelt alles terug. Niet in Figma.
struct FietspasGrootView: View {
    @EnvironmentObject var lang: LanguageManager
    let pas: Fietspas
    /// Waar de pas stond (globale coördinaten) en op welke schaal.
    let bron: CGRect
    let bronSchaal: CGFloat
    var onGesloten: () -> Void

    @State private var open = false
    @State private var sluit = false

    private let eindSchaal: CGFloat = 1.3

    var body: some View {
        GeometryReader { geo in
            let midden = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2 - 20)
            let start = CGPoint(x: bron.midX, y: bron.midY)

            ZStack {
                Color.black
                    .opacity(open ? 0.92 : 0)
                    .ignoresSafeArea()

                FietspasKaartView(pas: pas)
                    .scaleEffect(open ? eindSchaal : bronSchaal)
                    .rotation3DEffect(.degrees(open ? 0 : -8), axis: (x: 1, y: 0, z: 0), perspective: 0.6)
                    .position(open ? midden : start)

                Text(lang.t("fp_groot_hint"))
                    .font(AppFont.theSans(size: 16, weight: .semiBold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(open ? 1 : 0)
                    .offset(y: open ? 0 : 12)
                    .position(x: midden.x, y: midden.y + 412 * eindSchaal / 2 + 44)
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: sluiten)
        }
        .ignoresSafeArea()
        .onAppear {
            AnalyticsService.track("fietspas_groot", ["type": pas.type.rawValue])
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) { open = true }
            Helderheid.shared.naarMax()
        }
    }

    private func sluiten() {
        guard !sluit else { return }
        sluit = true
        Helderheid.shared.terug()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) { open = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { onGesloten() }
    }
}

/// Zet de schermhelderheid geleidelijk op maximaal en daarna terug naar wat
/// het was. UIKit animeert helderheid niet zelf, dus in kleine stapjes.
final class Helderheid {
    static let shared = Helderheid()
    private var oud: CGFloat?
    private var timer: Timer?

    private var scherm: UIScreen? {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen
    }

    func naarMax() {
        guard let scherm else { return }
        if oud == nil { oud = scherm.brightness }
        animeer(naar: 1)
    }

    func terug() {
        guard let doel = oud else { return }
        oud = nil
        animeer(naar: doel)
    }

    private func animeer(naar doel: CGFloat, duur: TimeInterval = 0.4) {
        timer?.invalidate()
        guard let scherm else { return }
        let begin = scherm.brightness
        let stappen = 20
        var stap = 0
        timer = Timer.scheduledTimer(withTimeInterval: duur / Double(stappen), repeats: true) { [weak self] t in
            stap += 1
            let p = CGFloat(stap) / CGFloat(stappen)
            scherm.brightness = begin + (doel - begin) * p
            if stap >= stappen { t.invalidate(); self?.timer = nil }
        }
    }
}

/// Frame van een kaart in globale coördinaten, voor de vlucht naar groot.
struct KaartFrameKey: PreferenceKey {
    static var defaultValue: [UUID: CGRect] = [:]
    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue()) { _, nieuw in nieuw }
    }
}
