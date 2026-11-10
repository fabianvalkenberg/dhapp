import SwiftUI

/// Mijn fietspassen (Figma fietsen, flow 02 scherm 3, 7 en 7b; flow 03 scherm 3).
/// Zonder pas een lege plek met "Pas toevoegen"; met passen een carrousel van
/// kaarten, een rij per pas en onderin "Nog een pas toevoegen". Tik op een pas
/// om hem groot te laten scannen. De tabbalk staat zolang dit open is weg.
struct MijnFietspassenView: View {
    @EnvironmentObject var lang: LanguageManager
    @ObservedObject var store: FietspasStore
    @Binding var isPresented: Bool
    @Binding var verbergTabbalk: Bool
    /// Sluit dit scherm en opent de buurt-kaart op de fietsenstallingen.
    var onStallingen: () -> Void

    @State private var toonIntro = false
    @State private var toevoegen: ToevoegStart?
    @State private var detailID: UUID?
    /// De pas die groot open staat, met waar hij vandaan vloog en op welke schaal.
    @State private var groot: (pas: Fietspas, bron: CGRect, schaal: CGFloat)?
    @State private var kaartFrames: [UUID: CGRect] = [:]
    @State private var actieveID: UUID?

    struct ToevoegStart: Identifiable { let id = UUID(); var metCode = false }

    private var safeTop: CGFloat { AppDesign.safeAreaTop }

    /// Laatst gebruikte pas vooraan (flow 03), daarna in volgorde van toevoegen.
    private var passen: [Fietspas] {
        guard let id = store.laatstGebruiktID, let eerste = store.passen.first(where: { $0.id == id }) else {
            return store.passen
        }
        return [eerste] + store.passen.filter { $0.id != id }
    }

    var body: some View {
        ZStack {
            overzicht

            if toonIntro {
                FietspasIntroView(
                    onTerug: { toonIntro = false },
                    onScan: { toevoegen = ToevoegStart() },
                    onStallingen: onStallingen
                )
                .transition(.move(edge: .trailing))
                .zIndex(1)
            }

            if let id = detailID, let pas = store.passen.first(where: { $0.id == id }) {
                FietspasDetailView(
                    store: store,
                    pas: pas,
                    onTerug: { detailID = nil },
                    onToonPas: { frame in toonGroot(pas, bron: frame, schaal: 0.62) }
                )
                .transition(.move(edge: .trailing))
                .zIndex(2)
            }

            if let g = groot {
                FietspasGrootView(pas: g.pas, bron: g.bron, bronSchaal: g.schaal) {
                    groot = nil
                }
                .zIndex(5)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: toonIntro)
        .animation(.easeInOut(duration: 0.3), value: detailID)
        .fullScreenCover(item: $toevoegen) { start in
            FietspasToevoegenView(
                store: store,
                beginMetCode: start.metCode,
                onSluit: { toevoegen = nil },
                onToegevoegd: { nieuw in
                    store.voegToe(nieuw)
                    AnalyticsService.track("fietspas_toegevoegd", ["type": nieuw.type.rawValue])
                    toevoegen = nil
                    toonIntro = false
                    actieveID = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                        withAnimation(.easeInOut(duration: 0.4)) { actieveID = nieuw.id }
                    }
                },
                onNaarPas: { pas in
                    toevoegen = nil
                    toonIntro = false
                    actieveID = pas.id
                }
            )
            .environmentObject(lang)
        }
        .onAppear {
            AnalyticsService.screen("fietspassen")
            withAnimation(.easeInOut(duration: 0.25)) { verbergTabbalk = true }
        }
    }

    private func sluit() {
        withAnimation(.easeInOut(duration: 0.25)) { verbergTabbalk = false }
        withAnimation(.easeInOut(duration: 0.35)) { isPresented = false }
    }

    // MARK: - Overzicht

    private var overzicht: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            VStack(spacing: 0) {
                FpKop(titel: lang.t("fp_title"), onSluit: sluit)
                    .padding(.top, safeTop)
                if store.passen.isEmpty {
                    legeStaat
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            carrousel
                            lijst
                        }
                        .padding(.bottom, 24)
                    }
                    VStack(spacing: 0) {
                        Divider()
                        FietspasHoofdknop(titel: lang.t("fp2_nog_een")) { toevoegen = ToevoegStart() }
                            .padding(.horizontal, AppDesign.horizontalPadding)
                            .padding(.top, 16)
                            .padding(.bottom, 8)
                    }
                }
            }
        }
        .ignoresSafeArea(edges: .top)
    }

    /// Figma scherm 3: lege plek met plus, uitleg, "Pas toevoegen" en de link.
    private var legeStaat: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 12)
            Button { toevoegen = ToevoegStart() } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 18).fill(Color(hex: "F4F3F0"))
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(Color(hex: "C8C6C0"), style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
                    Image(systemName: "plus")
                        .font(.system(size: 40, weight: .light))
                        .foregroundColor(Color(hex: "9A9893"))
                }
                .frame(width: 216, height: 304)
            }
            .buttonStyle(.plain)
            Text(lang.t("fp2_leeg_kop"))
                .font(AppFont.theMix(size: 22, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .padding(.top, 32)
            Text(lang.t("fp_leeg_body"))
                .font(AppFont.theSans(size: 17, weight: .plain))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 32)
                .padding(.top, 10)
            Spacer()
            FpOnderknoppen(knop: lang.t("fp_toevoegen"), link: lang.t("fp2_hoe_kom_je"),
                           onKnop: { toevoegen = ToevoegStart() }, onLink: { toonIntro = true })
        }
    }

    private var carrousel: some View {
        VStack(spacing: 16) {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 20) {
                    ForEach(passen) { pas in
                        FietspasKaartView(pas: pas)
                            .opacity(pas.id == (actieveID ?? passen.first?.id) ? 1 : 0.6)
                            // Tijdens de vlucht staat de pas "los" van de carrousel.
                            .opacity(groot?.pas.id == pas.id ? 0 : 1)
                            .background(GeometryReader { g in
                                Color.clear.preference(key: KaartFrameKey.self, value: [pas.id: g.frame(in: .global)])
                            })
                            .onTapGesture {
                                toonGroot(pas, bron: kaartFrames[pas.id] ?? .zero, schaal: 1)
                            }
                            .id(pas.id)
                    }
                }
                .scrollTargetLayout()
                .padding(.vertical, 12)
            }
            .contentMargins(.horizontal, 71, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $actieveID)
            .scrollClipDisabled()
            .onPreferenceChange(KaartFrameKey.self) { kaartFrames = $0 }

            if passen.count > 1 {
                HStack(spacing: 6) {
                    ForEach(passen) { pas in
                        let actief = pas.id == (actieveID ?? passen.first?.id)
                        Capsule()
                            .fill(actief ? FietspasKleur.kop : AppColors.grijs2)
                            .frame(width: actief ? 22 : 8, height: 8)
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: actieveID)
            }
        }
    }

    private var lijst: some View {
        VStack(spacing: 10) {
            ForEach(passen) { pas in
                Button { detailID = pas.id } label: { pasRij(pas) }
                    .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppDesign.horizontalPadding)
        .padding(.top, 20)
    }

    /// "Mijn fiets · ABC8D6E · groene pas" in een lichtgrijze rij met pijl.
    private func pasRij(_ pas: Fietspas) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(pas.bijnaam.isEmpty ? pas.type.standaardBijnaam(lang) : pas.bijnaam)
                    .font(AppFont.theSans(size: 16, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                Text("\(pas.code) · \(lang.t(pas.type.kleurBijvoeglijkKey)) \(lang.t("fp_pas"))")
                    .font(AppFont.theSans(size: 14, weight: .plain))
                    .foregroundColor(FietspasKleur.tekstZacht)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(hex: "F4F3F0"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
    }

    // MARK: - Pas groot tonen

    private func toonGroot(_ pas: Fietspas, bron: CGRect, schaal: CGFloat) {
        groot = (pas, bron, schaal)
        store.markeerGebruikt(pas.id)
    }
}
