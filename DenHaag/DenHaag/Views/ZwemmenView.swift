import SwiftUI

// MARK: - Mini-app Zwemmen
//
// Gebaseerd op het HTML-prototype in input/zwemmen. Eigen schermstapel binnen het
// overlay-scherm: elk scherm schuift van rechts in, net als de overlays in MainTabView.

struct ZwemmenView: View {
    @Binding var isPresented: Bool
    @StateObject private var model = ZwemmenModel()
    @EnvironmentObject var lang: LanguageManager

    var body: some View {
        ZStack {
            ZwemmenHomeView(sluit: { isPresented = false })

            ForEach(Array(model.pad.enumerated()), id: \.offset) { i, route in
                scherm(route)
                    .background(Color.white.ignoresSafeArea())
                    .transition(.move(edge: .trailing))
                    .zIndex(Double(i + 1))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: model.pad)
        .environmentObject(model)
        .fullScreenCover(item: $model.qr) { qr in
            ZwQRScherm(qr: qr) { model.qr = nil }
                .environmentObject(lang)
        }
        .onAppear { AnalyticsService.screen("zwemmen") }
    }

    @ViewBuilder
    private func scherm(_ route: ZwRoute) -> some View {
        switch route {
        case .kopen: ZwKopenView()
        case .activiteit(let a, let dag): ZwActiviteitView(activiteit: a, dag: dag)
        case .zwembad(let naam): ZwZwembadView(naam: naam)
        case .zwembaden: ZwZwembadenView()
        case .kaartjes: ZwKaartjesView()
        case .les: ZwLesView()
        case .wachttijden: ZwWachttijdenView()
        case .aanmelden: ZwAanmeldView()
        case .kind(let id): ZwKindView(id: id)
        case .voortgang(let id): ZwVoortgangView(id: id)
        case .abonnement(let id): ZwAbonnementView(id: id)
        }
    }
}

// MARK: - Startscherm

struct ZwemmenHomeView: View {
    let sluit: () -> Void
    @EnvironmentObject var model: ZwemmenModel
    @EnvironmentObject var lang: LanguageManager

    @State private var toonKiezer = false

    // Header animation states
    @State private var swimmerOffset: CGFloat = 100
    @State private var swimmerOpacity: Double = 0
    @State private var swimmerRotation: Double = 5
    @State private var splashScale: CGFloat = 0
    @State private var headerAppeared = false

    // Cloud animations
    @State private var cloud1X: CGFloat = 0
    @State private var cloud2X: CGFloat = 0
    @State private var cloud3X: CGFloat = 0
    @State private var cloud4X: CGFloat = 0

    private var safeTop: CGFloat { AppDesign.safeAreaTop }
    private var reservering: ZwReservering? {
        guard let r = model.reservering, r.isGeldig else { return nil }
        return r
    }

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    header

                    VStack(alignment: .leading, spacing: 32) {
                        if reservering != nil {
                            mijnKaartjesRij
                        } else if model.meldingZichtbaar {
                            melding
                        }
                        mijnZwembad
                        regelen
                        nieuws
                    }
                    .padding(.horizontal, ZwStijl.pad)
                    .padding(.top, 8)
                    .padding(.bottom, 120)
                }
            }

            // Floating nav bar: alleen de back-knop is sticky (titel scrollt mee).
            ZwTerugBalk(actie: sluit)
        }
        .background(AppColors.background)
        .ignoresSafeArea(edges: .top)
        .sheet(isPresented: $toonKiezer) {
            ZwZwembadKiezer(gekozen: model.mijnZwembad) { naam in
                model.mijnZwembad = naam
                toonKiezer = false
            } sluit: { toonKiezer = false }
            .environmentObject(lang)
            .presentationDetents([.large])
            .presentationCornerRadius(32)
        }
        .onAppear {
            startHeaderAnimation()
            startCloudAnimation()
        }
    }

    // MARK: Header (blauw, wolken, zwemmer, curve)

    private var header: some View {
        ZStack {
            AppColors.blauw1

            Group {
                Image("wolk01").resizable().scaledToFit().frame(width: 100)
                    .offset(x: -80 + cloud1X, y: -40)
                Image("wolk02").resizable().scaledToFit().frame(width: 70)
                    .offset(x: 100 + cloud2X, y: -55)
                Image("wolk01").resizable().scaledToFit().frame(width: 60).opacity(0.7)
                    .offset(x: 30 + cloud3X, y: -10)
                Image("wolk02").resizable().scaledToFit().frame(width: 50).opacity(0.5)
                    .offset(x: -130 + cloud4X, y: 5)
            }

            VStack(spacing: 0) {
                // Paginatitel scrollt mee; alleen de back-knop is sticky.
                HStack {
                    Spacer().frame(width: 52)
                    Text(lang.t("zw_title"))
                        .font(AppFont.theMix(size: 26, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                }
                .padding(.horizontal, ZwStijl.pad)
                .padding(.top, safeTop + 14)

                Spacer().frame(height: reservering == nil ? 40 : 28)

                if let r = reservering {
                    ZwReserveringKaart(reservering: r) { toonQR(r) }
                        .padding(.horizontal, ZwStijl.pad)
                        .transition(.scale.combined(with: .opacity))
                    Spacer().frame(height: 20)
                }

                // Illustration — curve overlay covers bottom ~40px
                ZStack(alignment: .bottom) {
                    Ellipse()
                        .fill(Color(hex: "C8D8E8"))
                        .frame(width: 280, height: 30)

                    ZStack {
                        Image("zwemmer")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 160)
                            .rotationEffect(.degrees(swimmerRotation))
                            .offset(x: swimmerOffset)
                            .opacity(swimmerOpacity)

                        Circle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 40, height: 40)
                            .scaleEffect(splashScale)
                            .offset(x: -20, y: 20)
                            .opacity(splashScale > 0 ? 1 - Double(splashScale / 3) : 0)
                    }
                    .padding(.bottom, 10)
                }
                .frame(height: 120)
                .padding(.bottom, 10)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: reservering)
        .overlay(alignment: .bottom) {
            HeaderCurveShape()
                .fill(AppColors.background)
                .frame(height: 75)
        }
    }

    // MARK: Blokken

    private var mijnKaartjesRij: some View {
        Button { model.push(.kaartjes) } label: {
            HStack(spacing: 12) {
                ZwIcon(naam: "zw-ticket", kleur: .white)
                Text(lang.t("zw_my_tickets"))
                    .font(ZwStijl.tekstVet)
                Spacer()
                Text("1").font(ZwStijl.tekstVet)
                ZwPijl(kleur: .white)
            }
            .foregroundColor(.white)
            .padding(16)
            .background(AppColors.groen3)
            .cornerRadius(ZwStijl.lijstRadius)
        }
        .buttonStyle(.plain)
    }

    private var melding: some View {
        HStack(alignment: .top, spacing: 8) {
            ZwIcon(naam: "zw-info", kleur: AppColors.blauw3).padding(.top, 2)
            VStack(alignment: .leading, spacing: 12) {
                Text(lang.t("zw_alert_hofbad"))
                    .font(ZwStijl.tekst)
                    .foregroundColor(AppColors.blauw3)
                    .fixedSize(horizontal: false, vertical: true)
                Button {} label: {
                    Text(lang.t("zw_read_more"))
                        .font(ZwStijl.tekst)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(AppColors.blauw3)
                        .cornerRadius(AppDesign.cornerRadius)
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                withAnimation(.easeInOut(duration: 0.25)) { model.meldingZichtbaar = false }
            } label: {
                ZwIcon(naam: "zw-close", kleur: AppColors.blauw3)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(lang.t("zw_close_alert"))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(AppColors.blauw1)
        .cornerRadius(AppDesign.cornerRadius)
    }

    @ViewBuilder
    private var mijnZwembad: some View {
        if let naam = model.mijnZwembad {
            ZwSectie(titel: lang.t("zw_my_pool"), actie: (lang.t("zw_change"), { toonKiezer = true })) {
                ZwZwembadKaart(zwembad: naam) { model.push(.zwembad(naam)) }
            }
        } else {
            ZwSectie(titel: lang.t("zw_my_pool")) {
                VStack(alignment: .leading, spacing: 4) {
                    ZwIcon(naam: "zw-pool")
                    Text(lang.t("zw_no_pool_title"))
                        .font(ZwStijl.tekstVet)
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.top, 4)
                    Text(lang.t("zw_no_pool_text"))
                        .font(ZwStijl.tekst)
                        .foregroundColor(AppColors.textSecondary)
                    ZwOmlijndeKnop(titel: lang.t("zw_choose_pool")) { toonKiezer = true }
                        .padding(.top, 8)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.warmGrijs)
                .cornerRadius(AppDesign.cornerRadius)
            }
        }
    }

    private var regelen: some View {
        ZwSectie(titel: lang.t("zw_arrange")) {
            ZwLijst {
                ZwLinkRij(icoon: "zw-ticket", titel: lang.t("zw_buy_ticket")) { model.openKopen() }
                ZwScheiding()
                ZwLinkRij(icoon: "zw-subscription", titel: lang.t("zw_buy_card"), sub: lang.t("zw_buy_card_sub")) {}
                ZwScheiding()
                ZwLinkRij(icoon: "zw-swimming", titel: lang.t("zw_lessons")) { model.push(.les) }
                ZwScheiding()
                ZwLinkRij(icoon: "zw-pool", titel: lang.t("zw_pools")) { model.push(.zwembaden) }
            }
        }
    }

    private var nieuws: some View {
        ZwSectie(titel: lang.t("zw_news"), actie: (lang.t("zw_preferences"), {})) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 16) {
                    ForEach(ZwData.nieuws) { n in
                        VStack(alignment: .leading, spacing: 20) {
                            HStack(alignment: .top, spacing: 20) {
                                ZwDatumBlok(datum: n.datum)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(n.tijd) · \(n.zwembad)")
                                        .font(ZwStijl.klein)
                                        .foregroundColor(AppColors.textSecondary)
                                        .lineLimit(1)
                                    Text(n.titel)
                                        .font(ZwStijl.tekstVet)
                                        .foregroundColor(AppColors.textPrimary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            Text(n.tekst)
                                .font(ZwStijl.tekst)
                                .foregroundColor(AppColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 24)
                        .frame(width: 300, alignment: .leading)
                        .frame(maxHeight: .infinity, alignment: .top)
                        .background(Color.white)
                        .cornerRadius(AppDesign.cornerRadius)
                        .overlay(RoundedRectangle(cornerRadius: AppDesign.cornerRadius).stroke(ZwStijl.lijn, lineWidth: 1))
                    }
                }
                .padding(.horizontal, ZwStijl.pad)
                .padding(.vertical, 1)
            }
            .padding(.horizontal, -ZwStijl.pad)
            .scrollTargetBehavior(.viewAligned)
        }
    }

    private func toonQR(_ r: ZwReservering) {
        model.qr = ZwQR(status: lang.t("zw_reserved"), toonVinkje: true, titel: r.activiteit.naam,
                        regels: ["\(lang.zwDagKort(r.datum)) \(r.activiteit.tijd)", r.activiteit.zwembad],
                        code: "DH-ZWEMMEN|\(r.activiteit.naam.uppercased())|\(r.activiteit.zwembad.uppercased())|\(r.activiteit.start)|KAARTJE-0001")
    }

    // MARK: Header Animation

    private func startHeaderAnimation() {
        guard !headerAppeared else { return }
        headerAppeared = true

        withAnimation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.2)) {
            swimmerOffset = 0
            swimmerOpacity = 1
            swimmerRotation = 0
        }

        withAnimation(.easeOut(duration: 0.4).delay(0.6)) {
            splashScale = 2.5
        }
    }

    private func startCloudAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 18).repeatForever(autoreverses: true)) { cloud1X = 50 }
            withAnimation(.easeInOut(duration: 22).repeatForever(autoreverses: true)) { cloud2X = -40 }
            withAnimation(.easeInOut(duration: 15).repeatForever(autoreverses: true)) { cloud3X = -35 }
            withAnimation(.easeInOut(duration: 20).repeatForever(autoreverses: true)) { cloud4X = 45 }
        }
    }
}

// MARK: - Zwembadkiezer (sheet)

struct ZwZwembadKiezer: View {
    let gekozen: String?
    let kies: (String) -> Void
    let sluit: () -> Void
    @EnvironmentObject var lang: LanguageManager

    var body: some View {
        VStack(spacing: 0) {
            ZwSheetKop(titel: lang.t("zw_choose_your_pool"), sluit: sluit)
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(ZwData.namen.enumerated()), id: \.offset) { i, naam in
                        if i > 0 { ZwScheiding(zacht: true) }
                        ZwKeuze(titel: naam, aan: naam == gekozen) { kies(naam) }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
            }
        }
    }
}
