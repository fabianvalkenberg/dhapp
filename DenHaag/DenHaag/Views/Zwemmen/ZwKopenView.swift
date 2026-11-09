import SwiftUI

// MARK: - Kaartje kopen (activiteitenoverzicht)

struct ZwKopenView: View {
    @EnvironmentObject var model: ZwemmenModel
    @EnvironmentObject var lang: LanguageManager
    @State private var toonFilters = false

    private var lijst: [ZwActiviteit] { ZwData.rooster(model.dag).filter { model.filters.past($0) } }

    private func status(_ a: ZwActiviteit) -> ZwActiviteitRij.Status {
        guard model.dag == 0 else { return .geen }
        let nu = ZwData.nuMinuten
        if a.eindMin <= nu { return .afgelopen }
        if a.startMin <= nu { return .bezig }
        return .geen
    }

    var body: some View {
        VStack(spacing: 0) {
            kop
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        Color.clear.frame(height: 0).id("boven")
                        if lijst.isEmpty {
                            geenResultaat
                        }
                        ForEach(Array(lijst.enumerated()), id: \.element.id) { i, a in
                            if i > 0 { ZwScheiding(zacht: true) }
                            ZwActiviteitRij(activiteit: a, status: status(a)) {
                                model.push(.activiteit(a, dag: model.dag))
                            }
                            .id(a.id)
                        }
                    }
                    .padding(.horizontal, ZwStijl.pad)
                    .padding(.bottom, 40)
                }
                .onAppear { scrollNaarNu(proxy, vertraging: 0.45) }
                .onChange(of: model.dag) { _, _ in scrollNaarNu(proxy, vertraging: 0.1) }
                .onChange(of: model.filters) { _, _ in scrollNaarNu(proxy, vertraging: 0.1) }
            }
        }
        .ignoresSafeArea(edges: .top)
        .sheet(isPresented: $toonFilters) {
            ZwFiltersSheet(dag: model.dag, start: model.filters) { nieuw in
                model.filters = nieuw
                toonFilters = false
            } sluit: { toonFilters = false }
            .environmentObject(lang)
            .presentationDetents([.large])
            .presentationCornerRadius(32)
        }
    }

    /// Vaste kop: terug · titel · dagen · dagkop met filters · actieve filters.
    private var kop: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                BackCircleButton { model.terug() }
                Text(lang.t("zw_buy_ticket"))
                    .font(ZwStijl.titel())
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }
            .padding(.horizontal, ZwStijl.pad)
            .padding(.top, AppDesign.safeAreaTop + 8)

            dagen

            HStack {
                Text(lang.zwDagLabel(model.dag))
                    .font(AppFont.theSans(size: 20, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                ZwOmlijndeKnop(titel: lang.t("zw_filters_count", model.filters.aantal), icoon: "zw-filters") {
                    toonFilters = true
                }
            }
            .padding(.horizontal, ZwStijl.pad)

            if model.filters.aantal > 0 { actieveFilters.padding(.top, 12) }

            Spacer().frame(height: 12)
            ZwScheiding(zacht: true)
        }
        .background(Color.white)
    }

    private var dagen: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(0..<ZwData.aantalDagen, id: \.self) { i in
                        let d = ZwData.dag(i)
                        let aan = i == model.dag
                        Button {
                            model.dag = i
                        } label: {
                            VStack(spacing: 0) {
                                Text(lang.zw.weekdagKort(d)).font(ZwStijl.klein)
                                Text(lang.zw.dagNummer(d))
                                    .font(AppFont.theMix(size: 20, weight: .bold))
                                    .foregroundColor(aan ? .white : AppColors.textPrimary)
                                Text(lang.zw.maandKort(d)).font(ZwStijl.klein)
                            }
                            .foregroundColor(aan ? .white : AppColors.grijs4)
                            .frame(width: 64)
                            .padding(.vertical, 8)
                            .background(aan ? AppColors.groen3 : Color.white)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(aan ? .clear : Color.black.opacity(0.08), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(aan ? .isSelected : [])
                        .id(i)
                    }
                }
                .padding(.horizontal, ZwStijl.pad)
                .padding(.vertical, 16)
            }
            .onAppear { if model.dag > 3 { proxy.scrollTo(model.dag, anchor: .leading) } }
        }
    }

    private var actieveFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(model.filters.zwembaden, id: \.self) { z in
                    filterChip(z) { model.filters.zwembaden.removeAll { $0 == z } }
                }
                ForEach(model.filters.categorieen, id: \.self) { c in
                    filterChip(lang.t(c.titelKey)) { model.filters.categorieen.removeAll { $0 == c } }
                }
                ForEach(model.filters.dagdelen, id: \.self) { p in
                    filterChip(lang.t(p.titelKey)) { model.filters.dagdelen.removeAll { $0 == p } }
                }
            }
            .padding(.horizontal, ZwStijl.pad)
        }
    }

    private func filterChip(_ titel: String, weg: @escaping () -> Void) -> some View {
        Button(action: weg) {
            HStack(spacing: 6) {
                Text(titel).font(AppFont.theSans(size: 16, weight: .semiBold))
                Image(systemName: "xmark").font(.system(size: 11, weight: .bold))
            }
            .foregroundColor(AppColors.groen4)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(AppColors.groen1)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(lang.t("zw_remove_filter", titel))
    }

    private var geenResultaat: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(lang.t("zw_no_results_title"))
                .font(ZwStijl.tekstVet)
                .foregroundColor(AppColors.textPrimary)
            Text(lang.t("zw_no_results_text"))
                .font(ZwStijl.tekst)
                .foregroundColor(AppColors.textSecondary)
            ZwOmlijndeKnop(titel: lang.t("zw_clear_filters")) { model.filters = ZwFilters() }
                .padding(.top, 8)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Bij openen zichtbaar doorscrollen naar de eerste activiteit die nog niet afgelopen is.
    private func scrollNaarNu(_ proxy: ScrollViewProxy, vertraging: Double) {
        proxy.scrollTo("boven", anchor: .top)
        guard model.dag == 0,
              lijst.contains(where: { status($0) == .afgelopen }),
              let doel = lijst.first(where: { status($0) != .afgelopen }) else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + vertraging) {
            withAnimation(.easeInOut(duration: 0.8)) { proxy.scrollTo(doel.id, anchor: .top) }
        }
    }
}

// MARK: - Filters (sheet)

struct ZwFiltersSheet: View {
    let dag: Int
    let pasToe: (ZwFilters) -> Void
    let sluit: () -> Void
    @EnvironmentObject var lang: LanguageManager
    @State private var concept: ZwFilters

    init(dag: Int, start: ZwFilters, pasToe: @escaping (ZwFilters) -> Void, sluit: @escaping () -> Void) {
        self.dag = dag
        self.pasToe = pasToe
        self.sluit = sluit
        _concept = State(initialValue: start)
    }

    private var aantal: Int { ZwData.rooster(dag).filter { concept.past($0) }.count }

    var body: some View {
        VStack(spacing: 0) {
            ZwSheetKop(titel: lang.t("zw_filters"), sluit: sluit)
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    groep(lang.t("zw_filter_pool")) {
                        ForEach(ZwData.namen, id: \.self) { z in
                            ZwKeuze(titel: z, aan: concept.zwembaden.contains(z), vakje: true) {
                                wissel(&concept.zwembaden, z)
                            }
                        }
                    }
                    groep(lang.t("zw_filter_activity")) {
                        ForEach(ZwCategorie.allCases, id: \.self) { c in
                            ZwKeuze(titel: lang.t(c.titelKey), sub: c.subKey.map { lang.t($0) },
                                    aan: concept.categorieen.contains(c), vakje: true) {
                                wissel(&concept.categorieen, c)
                            }
                        }
                    }
                    groep(lang.t("zw_filter_part")) {
                        ForEach(ZwDagdeel.allCases, id: \.self) { p in
                            ZwKeuze(titel: lang.t(p.titelKey), sub: lang.t(p.subKey),
                                    aan: concept.dagdelen.contains(p), vakje: true) {
                                wissel(&concept.dagdelen, p)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
            }
            ZwKnoppenBalk {
                ZwPrimaireKnop(titel: lang.t(aantal == 1 ? "zw_show_1_activity" : "zw_show_n_activities", aantal)) {
                    pasToe(concept)
                }
                ZwTekstKnop(titel: lang.t("zw_clear_filters")) { concept = ZwFilters() }
            }
        }
    }

    private func groep<Inhoud: View>(_ titel: String, @ViewBuilder inhoud: () -> Inhoud) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(titel).font(ZwStijl.kop).foregroundColor(AppColors.textPrimary).padding(.bottom, 4)
            inhoud()
        }
    }

    private func wissel<T: Equatable>(_ lijst: inout [T], _ w: T) {
        if let i = lijst.firstIndex(of: w) { lijst.remove(at: i) } else { lijst.append(w) }
    }
}

// MARK: - Activiteit

struct ZwActiviteitView: View {
    let activiteit: ZwActiviteit
    let dag: Int
    @EnvironmentObject var model: ZwemmenModel
    @EnvironmentObject var lang: LanguageManager

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        VStack(alignment: .leading, spacing: 24) {
                            VStack(alignment: .leading, spacing: 0) {
                                HStack(spacing: 8) {
                                    Text(activiteit.tijd)
                                        .font(AppFont.theSans(size: 20, weight: .plain))
                                        .foregroundColor(AppColors.textSecondary)
                                    status
                                }
                                Text(activiteit.naam)
                                    .font(ZwStijl.titel(32))
                                    .foregroundColor(AppColors.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(dag == 0 ? activiteit.zwembad : "\(lang.zwDagLabel(dag)) · \(activiteit.zwembad)")
                                    .font(AppFont.theSans(size: 20, weight: .plain))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            ZwZwembadKaart(zwembad: activiteit.zwembad, toonAdres: true) {
                                model.push(.zwembad(activiteit.zwembad))
                            }
                        }
                        prijzen
                        if activiteit.naam == "Banenzwemmen" {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(lang.t("zw_what_is_it")).font(ZwStijl.kop).foregroundColor(AppColors.textPrimary)
                                Text(lang.t("zw_banen_text"))
                                    .font(ZwStijl.tekst)
                                    .foregroundColor(AppColors.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(.horizontal, ZwStijl.pad)
                    .padding(.top, AppDesign.safeAreaTop + 64)
                    .padding(.bottom, 32)
                }
                ZwTerugBalk { model.terug() }
            }
            ZwKnoppenBalk {
                ZwPrimaireKnop(titel: lang.t("zw_buy_ticket")) { model.koop(activiteit, dag: dag) }
            }
        }
        .ignoresSafeArea(edges: .top)
    }

    @ViewBuilder
    private var status: some View {
        if dag == 0 {
            let nu = ZwData.nuMinuten
            if activiteit.eindMin <= nu {
                ZwStatus(tekst: lang.t("zw_finished"), stijl: .grijs)
            } else if activiteit.startMin <= nu {
                ZwStatus(tekst: lang.t("zw_now_on"))
            }
        }
    }

    // MARK: Prijzen 2026 van denhaag.nl (Kosten zwemactiviteiten)

    private enum Groep { case basis, aqua, vitaal }

    private var groep: Groep? {
        let n = activiteit.naam
        if n.hasPrefix("AquaVitaal") { return .vitaal }
        switch activiteit.categorie {
        case .vrij, .banen: return .basis
        case .aqua, .baby, .training: return .aqua
        case .overig: return n.hasPrefix("Zwangerschaps") ? .aqua : nil
        }
    }

    @ViewBuilder
    private var prijzen: some View {
        if let g = groep {
            ZwSectie(titel: lang.t("zw_prices")) {
                ZwLijst {
                    switch g {
                    case .basis:
                        prijsRij("zw-ticket", lang.t("zw_single_ticket"), nil, "€4,90")
                        ZwScheiding()
                        prijsRij("zw-subscription", lang.t("zw_card_12"), lang.t("zw_valid_all_pools"), "€49", "€4,08")
                        ZwScheiding()
                        prijsRij("zw-subscription", lang.t("zw_card_25"), lang.t("zw_valid_all_pools"), "€98", "€3,92")
                    case .aqua:
                        prijsRij("zw-ticket", lang.t("zw_single_ticket"), nil, "€7,90")
                        ZwScheiding()
                        prijsRij("zw-subscription", lang.t("zw_card_12"), lang.t("zw_all_aqua"), "€79", "€6,58")
                        ZwScheiding()
                        prijsRij("zw-subscription", lang.t("zw_card_25"), lang.t("zw_all_aqua"), "€158", "€6,32")
                    case .vitaal:
                        prijsRij("zw-ticket", lang.t("zw_course_period"), lang.t(ZwData.vitaalPeriodeKey), "€38")
                    }
                }
                Text(prijsNoot(g) + " " + lang.t("zw_ooievaarspas_discount"))
                    .font(AppFont.theSans(size: 16, weight: .plain))
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func prijsNoot(_ g: Groep) -> String {
        switch g {
        case .basis: return lang.t("zw_price_note_basis")
        case .aqua: return lang.t(activiteit.categorie == .baby ? "zw_price_note_baby" : "zw_price_note_aqua")
        case .vitaal: return lang.t("zw_price_note_vitaal")
        }
    }

    private func prijsRij(_ icoon: String, _ titel: String, _ sub: String?, _ prijs: String, _ perKeer: String? = nil) -> some View {
        ZwRij(icoon: icoon, titel: titel, sub: sub, titelDonker: true) {
            VStack(alignment: .trailing, spacing: 2) {
                Text(prijs).font(ZwStijl.tekst).foregroundColor(AppColors.textPrimary)
                if let perKeer {
                    Text(lang.t("zw_per_visit", perKeer)).font(ZwStijl.klein).foregroundColor(AppColors.textSecondary)
                }
            }
            .fixedSize()
        }
    }
}
