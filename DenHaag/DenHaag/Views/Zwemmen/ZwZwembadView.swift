import SwiftUI

// MARK: - Zwembad

struct ZwZwembadView: View {
    let naam: String
    @EnvironmentObject var model: ZwemmenModel
    @EnvironmentObject var lang: LanguageManager
    @Environment(\.openURL) private var openURL

    private var bad: Zwembad? { ZwData.zwembad(naam) }
    private var favoriet: Bool { model.mijnZwembad == naam }

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    hero
                    VStack(alignment: .leading, spacing: 32) {
                        if let bad { contact(bad) }
                        nuEnStraks
                        if let bad, !bad.voorzieningen.isEmpty { voorzieningen(bad) }
                    }
                    .padding(.horizontal, ZwStijl.pad)
                    .padding(.top, 24)
                    .padding(.bottom, 80)
                }
            }
            ZwTerugBalk(actie: { model.terug() }) {
                Button {
                    model.mijnZwembad = favoriet ? nil : naam
                } label: {
                    ZwIcon(naam: favoriet ? "zw-star" : "zw-star-outline", maat: 22,
                           kleur: favoriet ? AppColors.geel3 : AppColors.textPrimary)
                        .frame(width: 40, height: 40)
                        .background(Color.white.opacity(0.9))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(AppColors.grijs2, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(lang.t(favoriet ? "zw_fav_remove" : "zw_fav_add"))
            }
        }
        .ignoresSafeArea(edges: .top)
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            if let foto = bad?.foto {
                Image(foto).resizable().scaledToFill()
                    .frame(height: AppDesign.safeAreaTop + 178)
                    .frame(maxWidth: .infinity)
                    .clipped()
            } else {
                LinearGradient(colors: [AppColors.blauw3, Color(hex: "032C4E")], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
            LinearGradient(colors: [.black.opacity(0), .black.opacity(0.5)], startPoint: .top, endPoint: .bottom)
            Text(naam)
                .font(ZwStijl.titel(32))
                .foregroundColor(.white)
                .padding(.horizontal, ZwStijl.pad)
                .padding(.bottom, 12)
        }
        .frame(height: AppDesign.safeAreaTop + 178)
        .clipped()
    }

    private func contact(_ bad: Zwembad) -> some View {
        ZwLijst {
            ZwRij(icoon: "zw-pin", titel: bad.adres) {
                Button {
                    let q = "\(bad.adres), Den Haag".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                    if let url = URL(string: "maps://?daddr=\(q)") { openURL(url) }
                } label: {
                    HStack(spacing: 4) {
                        ZwIcon(naam: "zw-directions", maat: 20, kleur: AppColors.groen3)
                        Text(lang.t("zw_route")).font(AppFont.theSans(size: 18, weight: .bold))
                    }
                    .foregroundColor(AppColors.groen3)
                }
                .buttonStyle(.plain)
            }
            ZwScheiding()
            Button {
                if let url = URL(string: "tel:\(bad.telefoon.filter(\.isNumber))") { openURL(url) }
            } label: {
                ZwRij(icoon: "zw-phone", titel: bad.telefoon) { EmptyView() }
            }
            .buttonStyle(.plain)
        }
    }

    /// "Nu en straks": wat er nu bezig is en wat erna komt (max. 2). Het volledige rooster staat in Kaartje kopen.
    private var nuEnStraks: some View {
        let nu = ZwData.nuMinuten
        let vandaag = ZwData.rooster(0, zwembad: naam)
        let bezig = vandaag.filter { $0.startMin <= nu && nu < $0.eindMin }
        let straks = vandaag.filter { $0.startMin > nu }

        var titel = lang.t("zw_now_and_later")
        var noot: String? = nil
        var items: [(ZwActiviteit, Int)] = []

        if !bezig.isEmpty || !straks.isEmpty {
            let b = Array(bezig.prefix(straks.isEmpty ? 2 : 1))
            items = (b + straks.prefix(2 - b.count)).map { ($0, 0) }
        } else {
            noot = lang.t(vandaag.isEmpty ? "zw_none_today" : "zw_none_more_today")
            if let d = ZwData.volgendeDag(zwembad: naam) {
                titel = d == 1 ? lang.t("zw_tomorrow") : lang.zw.kortDatum(ZwData.dag(d)).capitalizedFirst
                items = ZwData.rooster(d, zwembad: naam).prefix(2).map { ($0, d) }
            } else {
                noot = (noot ?? "") + " " + lang.t("zw_none_two_weeks_sentence")
            }
        }

        return ZwSectie(titel: titel, actie: (lang.t("zw_all_activities"), { model.openAlleActiviteiten(naam) })) {
            if let noot {
                Text(noot).font(ZwStijl.tekst).foregroundColor(AppColors.textSecondary)
            }
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { i, item in
                    if i > 0 { ZwScheiding(zacht: true) }
                    ZwActiviteitRij(activiteit: item.0,
                                    status: item.1 == 0 && item.0.startMin <= nu ? .bezig : .geen,
                                    toonZwembad: false) {
                        model.push(.activiteit(item.0, dag: item.1))
                    }
                }
            }
            .padding(.top, -20)
        }
    }

    private func voorzieningen(_ bad: Zwembad) -> some View {
        ZwSectie(titel: lang.t("zw_facilities")) {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible())], alignment: .leading, spacing: 0) {
                ForEach(bad.voorzieningen, id: \.self) { v in
                    HStack(spacing: 12) {
                        ZwIcon(naam: v.icoon, kleur: AppColors.textSecondary)
                        Text(lang.t(v.key)).font(ZwStijl.tekst).foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }
}

// MARK: - Alle zwembaden

struct ZwZwembadenView: View {
    @EnvironmentObject var model: ZwemmenModel
    @EnvironmentObject var lang: LanguageManager

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    ZwPaginaTitel(titel: lang.t("zw_pools"))
                    VStack(spacing: 12) {
                        ForEach(ZwData.namen, id: \.self) { naam in
                            ZwZwembadKaart(zwembad: naam) { model.push(.zwembad(naam)) }
                        }
                    }
                    .padding(.horizontal, ZwStijl.pad)
                }
                .padding(.bottom, 80)
            }
            ZwTerugBalk { model.terug() }
        }
        .ignoresSafeArea(edges: .top)
    }
}

// MARK: - Mijn kaartjes

struct ZwKaartjesView: View {
    @EnvironmentObject var model: ZwemmenModel
    @EnvironmentObject var lang: LanguageManager

    private let gebruikt = 7
    private let totaal = 12
    private let geldigTot = ZwData.datum(2027, 3, 1)

    var body: some View {
        ZStack(alignment: .top) {
            AppColors.warmGrijs.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 32) {
                    ZwPaginaTitel(titel: lang.t("zw_my_tickets"))
                    VStack(alignment: .leading, spacing: 32) {
                        ZwSectie(titel: lang.t("zw_reservations")) {
                            if let r = model.reservering, r.isGeldig {
                                ZwReserveringKaart(reservering: r, omlijnd: true) { toonReservering(r) }
                            } else {
                                Text(lang.t("zw_no_reservations")).font(ZwStijl.tekst).foregroundColor(AppColors.textSecondary)
                            }
                        }
                        ZwSectie(titel: lang.t("zw_pool_cards")) { badenkaart }
                        HStack {
                            Text(lang.t("zw_expired")).font(ZwStijl.kop).foregroundColor(AppColors.textSecondary)
                            Spacer()
                            ZwIcon(naam: "zw-chevron-down", kleur: AppColors.textSecondary)
                        }
                    }
                    .padding(.horizontal, ZwStijl.pad)
                }
                .padding(.bottom, 80)
            }
            ZwTerugBalk { model.terug() }
        }
        .ignoresSafeArea(edges: .top)
    }

    private var badenkaart: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZwKapitaal(tekst: lang.t("zw_card_12"), kleur: AppColors.groen4)
                Spacer()
                Text(lang.t("zw_valid_until", lang.zw.volledig(geldigTot)))
                    .font(ZwStijl.klein)
                    .foregroundColor(AppColors.textSecondary)
            }
            Text(lang.t("zw_visits_left", totaal - gebruikt))
                .font(AppFont.theSans(size: 20, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            HStack {
                ForEach(0..<totaal, id: \.self) { i in
                    Circle()
                        .fill(i < gebruikt ? AppColors.grijs4 : Color(hex: "F1F1F1"))
                        .overlay(Circle().stroke(i < gebruikt ? .clear : AppColors.grijs2, lineWidth: 1))
                        .frame(width: 16, height: 16)
                    if i < totaal - 1 { Spacer(minLength: 2) }
                }
            }
            .accessibilityElement()
            .accessibilityLabel(lang.t("zw_visits_left", totaal - gebruikt))
            ZwPrimaireKnop(titel: lang.t("zw_show_qr")) {
                model.qr = ZwQR(status: lang.t("zw_card_12"), toonVinkje: false,
                                titel: lang.t("zw_visits_left", totaal - gebruikt),
                                regels: [lang.t("zw_valid_until", lang.zw.volledig(geldigTot))],
                                code: "DH-ZWEMMEN|12-BADENKAART|KAART-0001")
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(AppDesign.cornerRadius)
        .overlay(RoundedRectangle(cornerRadius: AppDesign.cornerRadius).stroke(ZwStijl.lijn, lineWidth: 1))
    }

    private func toonReservering(_ r: ZwReservering) {
        model.qr = ZwQR(status: lang.t("zw_reserved"), toonVinkje: true, titel: r.activiteit.naam,
                        regels: ["\(lang.zwDagKort(r.datum)) \(r.activiteit.tijd)", r.activiteit.zwembad],
                        code: "DH-ZWEMMEN|\(r.activiteit.naam.uppercased())|\(r.activiteit.zwembad.uppercased())|\(r.activiteit.start)|KAARTJE-0001")
    }
}
