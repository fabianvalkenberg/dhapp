import SwiftUI

/// Mijn fietspassen (Figma C2/C5, nodes 3460:2201 en 3460:3101). Zonder pas
/// een lege staat met scannen en uitleg; met passen een carrousel van kaarten
/// plus een lijst. Vanuit hier: intro, scannen, pas gevonden en pasdetail (C4).
/// Ligt onder de tabbalk, zoals in de schetsen.
struct MijnFietspassenView: View {
    @EnvironmentObject var lang: LanguageManager
    @Environment(\.openURL) private var openURL
    @ObservedObject var store: FietspasStore
    @Binding var isPresented: Bool
    /// true zolang een pas schermvullend open staat; dan zakt de tabbalk weg.
    @Binding var verbergTabbalk: Bool
    /// Sluit dit scherm en opent de buurt-kaart op de fietsenstallingen.
    var onStallingen: () -> Void

    @State private var toonIntro = false
    @State private var toonScan = false
    @State private var gevonden: Fietspas?
    @State private var detailID: UUID?
    /// De pas die groot open staat, met waar hij vandaan vloog en op welke schaal.
    @State private var groot: (pas: Fietspas, bron: CGRect, schaal: CGFloat)?
    @State private var kaartFrames: [UUID: CGRect] = [:]
    @State private var actieveID: UUID?

    private var safeTop: CGFloat { AppDesign.safeAreaTop }

    var body: some View {
        ZStack {
            overzicht

            if toonIntro {
                FietspasIntroView(
                    onTerug: { toonIntro = false },
                    onScan: { toonScan = true },
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
                    onToonPas: { frame in toonGroot(pas, bron: frame, schaal: 0.36) }
                )
                .transition(.move(edge: .trailing))
                .zIndex(2)
            }

            if let pas = gevonden {
                FietspasGevondenView(
                    pas: pas,
                    onToevoegen: { nieuw in
                        store.voegToe(nieuw)
                        AnalyticsService.track("fietspas_toegevoegd", ["type": nieuw.type.rawValue])
                        toonIntro = false
                        gevonden = nil
                        // Pas naar de nieuwe pas schuiven als die in de carrousel staat.
                        actieveID = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                            withAnimation(.easeInOut(duration: 0.4)) { actieveID = nieuw.id }
                        }
                    },
                    onTerug: { gevonden = nil }
                )
                .transition(.move(edge: .trailing))
                .zIndex(3)
            }

            if let g = groot {
                FietspasGrootView(pas: g.pas, bron: g.bron, bronSchaal: g.schaal) {
                    groot = nil
                    withAnimation(.easeInOut(duration: 0.25)) { verbergTabbalk = false }
                }
                .zIndex(5)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: toonIntro)
        .animation(.easeInOut(duration: 0.3), value: gevonden)
        .animation(.easeInOut(duration: 0.3), value: detailID)
        // Camera schermvullend, over de tabbalk, met een lichte statusbalk.
        .fullScreenCover(isPresented: $toonScan) {
            FietspasScanView(
                onSluit: { toonScan = false },
                onGevonden: {
                    gevonden = store.volgendeScan()
                    toonScan = false
                }
            )
            .environmentObject(lang)
            .preferredColorScheme(.dark)
        }
        .onAppear { AnalyticsService.screen("fietspassen") }
    }

    // MARK: - Overzicht

    private var overzicht: some View {
        ZStack(alignment: .topTrailing) {
            AppColors.warmGrijs.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Color.clear.frame(height: safeTop + 16)

                    Text(lang.t(store.passen.isEmpty ? "fp_title_leeg" : "fp_title"))
                        .font(AppFont.theMix(size: 28, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(height: 36)
                        .padding(.horizontal, AppDesign.horizontalPadding)

                    if store.passen.isEmpty {
                        legeStaat
                    } else {
                        carrousel
                        lijst
                    }

                    // Ruimte voor de tabbalk.
                    Spacer().frame(height: 130)
                }
            }

            FietspasRondeKnop(icoon: "fp-sluiten", grootte: 20) {
                withAnimation(.easeInOut(duration: 0.35)) { isPresented = false }
            }
                .padding(.trailing, AppDesign.horizontalPadding)
                .padding(.top, safeTop + 8)
        }
        .ignoresSafeArea(edges: .top)
    }

    /// Nog geen pas: eerst scannen, of lezen hoe je eraan komt. Niet in Figma;
    /// zelfde opbouw en stijl als de andere fietspas-schermen.
    private var legeStaat: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image("ill-fietspas")
                .resizable()
                .scaledToFit()
                .frame(height: 150)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)

            Text(lang.t("fp_leeg_title"))
                .font(AppFont.theMix(size: 22, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .padding(.top, 24)

            Text(lang.t("fp_leeg_body"))
                .font(AppFont.theSans(size: 16, weight: .plain))
                .foregroundColor(FietspasKleur.tekstZacht)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)

            FietspasHoofdknop(titel: lang.t("fp_scan_knop")) { toonScan = true }
                .padding(.top, 24)

            Button { toonIntro = true } label: {
                FietspasRij(titel: lang.t("fp_intro_link"), sub: lang.t("fp_intro_link_sub"))
            }
            .buttonStyle(.plain)
            .padding(.top, 12)
        }
        .padding(.horizontal, AppDesign.horizontalPadding)
        .padding(.top, 22)
    }

    private var carrousel: some View {
        let passen = store.gesorteerd
        return VStack(spacing: 16) {
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
                .padding(.vertical, 22)
            }
            .contentMargins(.horizontal, 71, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $actieveID)
            .scrollClipDisabled()
            .onPreferenceChange(KaartFrameKey.self) { kaartFrames = $0 }

            // Paginadots
            HStack(spacing: 6) {
                ForEach(passen) { pas in
                    let actief = pas.id == (actieveID ?? passen.first?.id)
                    Capsule()
                        .fill(actief ? FietspasKleur.kop : AppColors.grijs2)
                        .frame(width: actief ? 22 : 8, height: 8)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, -22)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: actieveID)
        }
    }

    private var lijst: some View {
        let metSter = store.passen.contains(where: \.favoriet)
        return VStack(spacing: 10) {
            ForEach(store.gesorteerd) { pas in
                Button { detailID = pas.id } label: {
                    FietspasRij(
                        ster: metSter ? pas.favoriet : nil,
                        titel: lang.t(pas.type.naamKey),
                        sub: pasRegel(pas)
                    )
                }
                .buttonStyle(.plain)
            }

            // Omlijnde knop, groene tekst met een plus.
            FietspasOmlijndeKnop(titel: lang.t("fp_toevoegen"), icoon: "plus") {
                toonScan = true
            }

            // Sparen met Dappre: staat erbij om het idee te laten zien, doet nog niets.
            FietspasRij(titel: lang.t("fp_dappre_title"), sub: lang.t("fp_dappre_sub"), icoonRechts: "fp-extern")
                .padding(.top, 14)
        }
        .padding(.horizontal, AppDesign.horizontalPadding)
        .padding(.top, 24)
    }

    /// "ABC8D6E · groene pas", met "· favoriet" erachter als dat zo is.
    private func pasRegel(_ pas: Fietspas) -> String {
        var regel = "\(pas.code) · \(lang.t(pas.type.kleurBijvoeglijkKey)) \(lang.t("fp_pas"))"
        if pas.favoriet { regel += " · \(lang.t("fp_favoriet").lowercased())" }
        return regel
    }

    // MARK: - Pas groot tonen

    private func toonGroot(_ pas: Fietspas, bron: CGRect, schaal: CGFloat) {
        groot = (pas, bron, schaal)
        withAnimation(.easeInOut(duration: 0.3)) { verbergTabbalk = true }
    }
}
