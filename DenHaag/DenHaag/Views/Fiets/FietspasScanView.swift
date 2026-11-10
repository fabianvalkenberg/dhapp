import SwiftUI

/// Pas scannen. Niet in Figma. Prototype: geen echte camera; na een paar
/// tellen "vindt" hij de QR-code op je pas. Tikken in de zoeker scant meteen.
struct FietspasScanView: View {
    @EnvironmentObject var lang: LanguageManager
    var onSluit: () -> Void
    var onGevonden: () -> Void

    @State private var lijn: CGFloat = 0
    @State private var gevonden = false
    @State private var taak: DispatchWorkItem?

    private var safeTop: CGFloat { AppDesign.safeAreaTop }
    private let zoeker: CGFloat = 250

    var body: some View {
        ZStack {
            // Nagebootst camerabeeld: donker met een zachte gloed.
            RadialGradient(colors: [Color(hex: "3A3A36"), Color(hex: "111111")],
                           center: .center, startRadius: 20, endRadius: 500)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                ZStack {
                    ZoekerHoeken()
                        .stroke(gevonden ? AppColors.groen3 : .white,
                                style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    if !gevonden {
                        Capsule()
                            .fill(Color.white.opacity(0.8))
                            .frame(width: zoeker - 40, height: 2)
                            .offset(y: lijn)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(AppColors.groen3)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: zoeker, height: zoeker)
                .contentShape(Rectangle())
                .onTapGesture { vind() }

                Text(lang.t(gevonden ? "fp_scan_gevonden" : "fp_scan_hint"))
                    .font(AppFont.theSans(size: 17, weight: .semiBold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()
                Spacer()
            }

            VStack {
                HStack {
                    Text(lang.t("fp_scan_title"))
                        .font(AppFont.theMix(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: onSluit) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.18))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, AppDesign.horizontalPadding)
                .padding(.top, safeTop + 8)
                Spacer()
            }
        }
        .ignoresSafeArea(edges: .top)
        .onAppear {
            AnalyticsService.screen("fietspas_scan")
            lijn = -(zoeker / 2 - 24)
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                lijn = zoeker / 2 - 24
            }
            let werk = DispatchWorkItem { vind() }
            taak = werk
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.6, execute: werk)
        }
        .onDisappear { taak?.cancel() }
    }

    private func vind() {
        guard !gevonden else { return }
        taak?.cancel()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { gevonden = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { onGevonden() }
    }
}

/// Vier hoeken van een zoeker.
private struct ZoekerHoeken: Shape {
    func path(in rect: CGRect) -> Path {
        let l: CGFloat = 40, r: CGFloat = 18
        var p = Path()
        // linksboven
        p.move(to: CGPoint(x: rect.minX, y: rect.minY + l))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        p.addQuadCurve(to: CGPoint(x: rect.minX + r, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX + l, y: rect.minY))
        // rechtsboven
        p.move(to: CGPoint(x: rect.maxX - l, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + r), control: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + l))
        // rechtsonder
        p.move(to: CGPoint(x: rect.maxX, y: rect.maxY - l))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        p.addQuadCurve(to: CGPoint(x: rect.maxX - r, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX - l, y: rect.maxY))
        // linksonder
        p.move(to: CGPoint(x: rect.minX + l, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - r), control: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - l))
        return p
    }
}
