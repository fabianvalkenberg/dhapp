import SwiftUI

// MARK: - Zwemles

struct ZwLesView: View {
    @EnvironmentObject var model: ZwemmenModel
    @EnvironmentObject var lang: LanguageManager

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 32) {
                    ZwPaginaTitel(titel: lang.t("zw_lessons"))
                    VStack(alignment: .leading, spacing: 32) {
                        if model.kinderen.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(lang.t("zw_les_intro_title")).font(ZwStijl.kop).foregroundColor(AppColors.textPrimary)
                                Text(lang.t("zw_les_intro_text")).font(ZwStijl.tekst).foregroundColor(AppColors.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                                ZwPrimaireKnop(titel: lang.t("zw_register_child")) { model.push(.aanmelden) }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 24)
                            .background(AppColors.warmGrijs)
                            .cornerRadius(AppDesign.cornerRadius)
                        } else {
                            ZwSectie(titel: lang.t("zw_my_children")) {
                                VStack(spacing: 12) {
                                    ForEach(model.kinderen) { k in kindKaart(k) }
                                }
                                ZwOmlijndeKnop(titel: lang.t("zw_register_another"), breed: true) { model.push(.aanmelden) }
                            }
                        }
                        ZwSectie(titel: lang.t("zw_good_to_know")) {
                            ZwLijst {
                                ZwLinkRij(icoon: "zw-clock", titel: lang.t("zw_waiting_times"), sub: lang.t("zw_waiting_times_sub")) {
                                    model.push(.wachttijden)
                                }
                                ZwScheiding()
                                ZwLinkRij(icoon: "zw-swimming", titel: lang.t("zw_how_lessons_work"), sub: lang.t("zw_how_lessons_work_sub")) {}
                                ZwScheiding()
                                ZwLinkRij(icoon: "zw-subscription", titel: lang.t("zw_costs"), sub: lang.t("zw_costs_sub")) {}
                            }
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

    private func kindKaart(_ k: ZwKind) -> some View {
        Button { model.push(.kind(k.id)) } label: {
            HStack(spacing: 16) {
                ZwAvatar(naam: k.naam)
                VStack(alignment: .leading, spacing: 2) {
                    Text(k.naam).font(ZwStijl.tekstVet).foregroundColor(AppColors.textPrimary)
                    if k.status == .les {
                        ZwStatus(tekst: lang.t("zw_on_lessons_diploma", k.diploma))
                        let les = ZwData.volgendeLes(k)
                        Text(lang.t("zw_next_lesson_meta", les.map { lang.zw.kortDatum($0.datum) } ?? "-", k.lesstart, k.zwembad))
                            .font(ZwStijl.klein).foregroundColor(AppColors.textSecondary)
                    } else {
                        ZwStatus(tekst: lang.t("zw_on_waitlist"), stijl: .grijs)
                        Text(lang.t("zw_waitlist_meta", k.plek, k.zwembad, k.oproep.map { lang.zw.maandJaar($0) } ?? "-"))
                            .font(ZwStijl.klein).foregroundColor(AppColors.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                ZwPijl()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .background(AppColors.warmGrijs)
            .cornerRadius(AppDesign.cornerRadius)
        }
        .buttonStyle(.plain)
    }
}

struct ZwAvatar: View {
    let naam: String
    var body: some View {
        Text(String(naam.prefix(1)).uppercased())
            .font(AppFont.theMix(size: 20, weight: .bold))
            .foregroundColor(AppColors.blauw3)
            .frame(width: 48, height: 48)
            .background(AppColors.blauw1)
            .clipShape(Circle())
            .accessibilityHidden(true)
    }
}

// MARK: - Wachttijden

struct ZwWachttijdenView: View {
    @EnvironmentObject var model: ZwemmenModel
    @EnvironmentObject var lang: LanguageManager

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        ZwPaginaTitel(titel: lang.t("zw_waiting_times"))
                        VStack(alignment: .leading, spacing: 24) {
                            Text(lang.t("zw_waiting_intro")).font(ZwStijl.tekst).foregroundColor(AppColors.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                            ZwLijst {
                                ForEach(Array(ZwData.wachttijden.enumerated()), id: \.offset) { i, w in
                                    if i > 0 { ZwScheiding() }
                                    ZwRij(titel: w.zwembad, titelDonker: true) {
                                        Text(lang.t("zw_months", w.maanden)).font(ZwStijl.tekstVet).foregroundColor(AppColors.textPrimary)
                                    }
                                }
                                ZwScheiding()
                                ZwRij(titel: "Het Hofbad", sub: lang.t("zw_no_lessons_here")) { EmptyView() }
                            }
                            Text(lang.t("zw_waiting_other_pool")).font(AppFont.theSans(size: 16, weight: .plain))
                                .foregroundColor(AppColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, ZwStijl.pad)
                    }
                    .padding(.bottom, 32)
                }
                ZwTerugBalk { model.terug() }
            }
            ZwKnoppenBalk {
                ZwPrimaireKnop(titel: lang.t("zw_register_child")) { model.push(.aanmelden) }
            }
        }
        .ignoresSafeArea(edges: .top)
    }
}

// MARK: - Kind aanmelden (3 stappen)

struct ZwAanmeldView: View {
    @EnvironmentObject var model: ZwemmenModel
    @EnvironmentObject var lang: LanguageManager
    @State private var a = ZwAanmelding()
    @State private var toetsenbord: CGFloat = 0
    @State private var toonDatumKiezer = false
    @FocusState private var focus: Veld?

    private enum Veld { case voornaam, achternaam }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 20) {
                            ZwPaginaTitel(titel: lang.t(a.stap < 4 ? "zw_register_child" : "zw_registered"))
                                .id("top")
                            VStack(alignment: .leading, spacing: 20) {
                                switch a.stap {
                                case 1: stap1
                                case 2: stap2
                                case 3: stap3
                                default: klaar
                                }
                            }
                            .padding(.horizontal, ZwStijl.pad)
                        }
                        .padding(.bottom, 32)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: a.stap) { _, _ in proxy.scrollTo("top", anchor: .top) }
                }
                ZwTerugBalk { terug() }
            }
            ZwKnoppenBalk { knoppen }
                .padding(.bottom, toetsenbord > 0 ? toetsenbord - 34 : 0)
        }
        .ignoresSafeArea(edges: .top)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { note in
            if let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeOut(duration: 0.25)) { toetsenbord = frame.height }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.25)) { toetsenbord = 0 }
        }
    }

    // MARK: Stappen

    private func stappenBalk(_ n: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(lang.t("zw_step_of", n, 3)).font(ZwStijl.klein).foregroundColor(AppColors.textSecondary)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(ZwStijl.lijnZacht)
                    Capsule().fill(AppColors.groen3).frame(width: g.size.width * CGFloat(n) / 3)
                }
            }
            .frame(height: 4)
        }
    }

    private func kop(_ key: String) -> some View {
        Text(lang.t(key)).font(ZwStijl.titel(24)).foregroundColor(AppColors.textPrimary)
    }

    private func fout(_ veld: String) -> some View {
        Group {
            if let key = a.fouten[veld] {
                Text(lang.t(key))
                    .font(AppFont.theSans(size: 16, weight: .plain))
                    .foregroundColor(AppColors.rood)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func tekstveld(_ label: String, _ veld: String, _ tekst: Binding<String>, _ f: Veld) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(ZwStijl.tekstVet).foregroundColor(AppColors.textPrimary)
            fout(veld)
            TextField("", text: tekst)
                .font(ZwStijl.tekst)
                .foregroundColor(AppColors.textPrimary)
                .textContentType(f == .voornaam ? .givenName : .familyName)
                .autocorrectionDisabled()
                .submitLabel(.next)
                .focused($focus, equals: f)
                .onSubmit { focus = f == .voornaam ? .achternaam : nil }
                .padding(.horizontal, 12)
                .frame(height: 48)
                .overlay(RoundedRectangle(cornerRadius: AppDesign.cornerRadius)
                    .stroke(a.fouten[veld] != nil ? AppColors.rood : AppColors.textSecondary, lineWidth: a.fouten[veld] != nil ? 2 : 1))
                .onChange(of: tekst.wrappedValue) { _, _ in a.fouten[veld] = nil }
        }
    }

    private var stap1: some View {
        VStack(alignment: .leading, spacing: 20) {
            stappenBalk(1)
            kop("zw_about_child")
            tekstveld(lang.t("zw_first_name"), "voornaam", $a.voornaam, .voornaam)
            tekstveld(lang.t("zw_last_name"), "achternaam", $a.achternaam, .achternaam)

            VStack(alignment: .leading, spacing: 6) {
                Text(lang.t("zw_birth_date")).font(ZwStijl.tekstVet).foregroundColor(AppColors.textPrimary)
                Text(lang.t("zw_birth_date_hint")).font(ZwStijl.klein).foregroundColor(AppColors.textSecondary)
                fout("datum")
                Button {
                    focus = nil
                    if a.geboortedatum == nil { a.geboortedatum = ZwData.datum(2020, 1, 1) }
                    withAnimation(.easeInOut(duration: 0.25)) { toonDatumKiezer.toggle() }
                    a.fouten["datum"] = nil
                } label: {
                    HStack {
                        Text(a.geboortedatum.map { lang.zw.volledig($0) } ?? lang.t("zw_choose_date"))
                            .font(ZwStijl.tekst)
                            .foregroundColor(a.geboortedatum == nil ? AppColors.grijs4 : AppColors.textPrimary)
                        Spacer()
                        Image(systemName: "calendar").foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 48)
                    .overlay(RoundedRectangle(cornerRadius: AppDesign.cornerRadius)
                        .stroke(a.fouten["datum"] != nil ? AppColors.rood : AppColors.textSecondary, lineWidth: a.fouten["datum"] != nil ? 2 : 1))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if toonDatumKiezer {
                    DatePicker("", selection: Binding(get: { a.geboortedatum ?? Date() }, set: { a.geboortedatum = $0 }),
                               in: ...Date(), displayedComponents: .date)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .environment(\.locale, Locale(identifier: lang.current == .en ? "en_GB" : lang.current == .tr ? "tr_TR" : "nl_NL"))
                        .frame(maxWidth: .infinity)
                }
            }

            VStack(alignment: .leading, spacing: 0) {
                Text(lang.t("zw_experience_q")).font(ZwStijl.tekstVet).foregroundColor(AppColors.textPrimary).padding(.bottom, 4)
                fout("ervaring")
                ZwKeuze(titel: lang.t("zw_no"), aan: a.ervaring == false) { a.ervaring = false; a.fouten["ervaring"] = nil }
                ZwKeuze(titel: lang.t("zw_yes"), sub: lang.t("zw_experience_yes_sub"), aan: a.ervaring == true) {
                    a.ervaring = true; a.fouten["ervaring"] = nil
                }
            }
        }
    }

    private var stap2: some View {
        VStack(alignment: .leading, spacing: 20) {
            stappenBalk(2)
            kop("zw_choose_a_pool")
            fout("zwembad")
            VStack(spacing: 0) {
                ForEach(ZwData.wachttijden, id: \.zwembad) { w in
                    ZwKeuze(titel: w.zwembad, sub: lang.t("zw_wait_approx", w.maanden), aan: a.zwembad == w.zwembad) {
                        a.zwembad = w.zwembad
                        a.extra.removeAll { $0 == w.zwembad }
                        a.fouten["zwembad"] = nil
                    }
                }
            }
            if let gekozen = a.zwembad {
                VStack(alignment: .leading, spacing: 0) {
                    Text(lang.t("zw_also_fine")).font(ZwStijl.tekstVet).foregroundColor(AppColors.textPrimary)
                    Text(lang.t("zw_also_fine_sub")).font(AppFont.theSans(size: 16, weight: .plain))
                        .foregroundColor(AppColors.textSecondary).padding(.bottom, 4)
                    ForEach(ZwData.wachttijden.filter { $0.zwembad != gekozen }, id: \.zwembad) { w in
                        ZwKeuze(titel: w.zwembad, aan: a.extra.contains(w.zwembad), vakje: true) {
                            if let i = a.extra.firstIndex(of: w.zwembad) { a.extra.remove(at: i) } else { a.extra.append(w.zwembad) }
                        }
                    }
                }
            }
        }
    }

    private var stap3: some View {
        VStack(alignment: .leading, spacing: 20) {
            stappenBalk(3)
            kop("zw_check_registration")
            Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 16, verticalSpacing: 8) {
                samenvatting(lang.t("zw_child"), "\(a.voornaam) \(a.achternaam)")
                samenvatting(lang.t("zw_birth_date"), a.geboortedatum.map { lang.zw.volledig($0) } ?? "")
                samenvatting(lang.t("zw_experience"), lang.t(a.ervaring == true ? "zw_yes" : "zw_no"))
                samenvatting(lang.t("zw_pool"), a.zwembad ?? "")
                samenvatting(lang.t("zw_also_fine_short"), a.extra.isEmpty ? lang.t("zw_no_other_pool") : a.extra.joined(separator: ", "))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.warmGrijs)
            .cornerRadius(AppDesign.cornerRadius)

            Button { withAnimation { a.stap = 1 } } label: {
                Text(lang.t("zw_edit_details")).font(AppFont.theSans(size: 18, weight: .bold)).foregroundColor(AppColors.blauw3)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(lang.t("zw_registration_fee")).font(ZwStijl.tekst)
                    Spacer()
                    Text("€12,50").font(ZwStijl.tekstVet)
                }
                .foregroundColor(AppColors.textPrimary)
                Text(lang.t("zw_registration_fee_note")).font(AppFont.theSans(size: 16, weight: .plain))
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if a.ervaring == true {
                ZwBlauweNoot(tekst: lang.t("zw_swim_test_note"))
            }
        }
    }

    private func samenvatting(_ label: String, _ waarde: String) -> some View {
        GridRow {
            Text(label).font(ZwStijl.tekst).foregroundColor(AppColors.textSecondary)
            Text(waarde).font(ZwStijl.tekstVet).foregroundColor(AppColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var klaar: some View {
        if let id = a.nieuwId, let k = model.kind(id) {
            VStack(alignment: .leading, spacing: 12) {
                ZwIcon(naam: "zw-check", maat: 28, kleur: AppColors.groen4)
                    .frame(width: 48, height: 48)
                    .background(AppColors.groen1)
                    .clipShape(Circle())
                Text(lang.t("zw_on_waitlist_title", k.naam)).font(ZwStijl.titel(24)).foregroundColor(AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(lang.t("zw_on_waitlist_text", k.naam, k.plek, k.zwembad, k.oproep.map { lang.zw.maandJaar($0) } ?? ""))
                    .font(ZwStijl.tekst).foregroundColor(AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            ZwWachtverzachter(naam: k.naam)
        }
    }

    @ViewBuilder
    private var knoppen: some View {
        switch a.stap {
        case 1, 2:
            ZwPrimaireKnop(titel: lang.t("zw_next")) { volgende() }
        case 3:
            ZwPrimaireKnop(titel: lang.t("zw_pay_and_register")) { betaal() }
        default:
            ZwPrimaireKnop(titel: lang.t("zw_to_lessons")) { model.naarLes() }
            ZwTekstKnop(titel: lang.t("zw_register_another")) { withAnimation { a = ZwAanmelding(); toonDatumKiezer = false } }
        }
    }

    // MARK: Logica

    private func terug() {
        focus = nil
        if a.stap > 1 && a.stap < 4 { withAnimation { a.stap -= 1 } }
        else if a.stap == 4 { model.naarLes() }
        else { model.terug() }
    }

    private func controleer() -> Bool {
        var f: [String: String] = [:]
        if a.stap == 1 {
            if a.voornaam.trimmingCharacters(in: .whitespaces).isEmpty { f["voornaam"] = "zw_err_first_name" }
            if a.achternaam.trimmingCharacters(in: .whitespaces).isEmpty { f["achternaam"] = "zw_err_last_name" }
            if let d = a.geboortedatum {
                if ZwData.leeftijd(d) < 5 { f["datum"] = "zw_err_too_young" }
            } else {
                f["datum"] = "zw_err_birth_date"
            }
            if a.ervaring == nil { f["ervaring"] = "zw_err_experience" }
        }
        if a.stap == 2 && a.zwembad == nil { f["zwembad"] = "zw_err_pool" }
        a.fouten = f
        return f.isEmpty
    }

    private func volgende() {
        focus = nil
        if controleer() {
            toonDatumKiezer = false
            withAnimation { a.stap += 1 }
        }
    }

    /// Plek op de wachtlijst en verwachte oproep zijn een schatting op basis van de wachttijd.
    private func betaal() {
        guard let bad = a.zwembad, let w = ZwData.wachttijden.first(where: { $0.zwembad == bad }) else { return }
        let plek = w.maanden * 25 + 13
        let oproep = Calendar.current.date(byAdding: .month, value: w.maanden, to: ZwData.maandEinde()) ?? Date()
        let k = ZwKind(id: "k\(Int(Date().timeIntervalSince1970))", naam: a.voornaam.trimmingCharacters(in: .whitespaces),
                       status: .wacht, zwembad: bad, plek: plek, startPlek: plek, sinds: Date(), oproep: oproep,
                       ervaring: a.ervaring == true, extra: a.extra)
        model.kinderen.append(k)
        AnalyticsService.track("zwemles_aangemeld", ["zwembad": bad])
        a.nieuwId = k.id
        withAnimation { a.stap = 4 }
    }
}

/// "Gratis zwemmen tijdens het wachten" met QR-code.
struct ZwWachtverzachter: View {
    let naam: String
    @EnvironmentObject var model: ZwemmenModel
    @EnvironmentObject var lang: LanguageManager

    var body: some View {
        ZwWarmeKaart(titel: lang.t("zw_free_swim_title"), tekst: lang.t("zw_free_swim_text", naam)) {
            ZwOmlijndeKnop(titel: lang.t("zw_show_qr")) {
                model.qr = ZwQR(status: lang.t("zw_waitlist_card"), toonVinkje: false, titel: naam,
                                regels: [lang.t("zw_free_swim_title"), lang.t("zw_valid_until_a")],
                                code: "DH-ZWEMLES|WACHTVERZACHTER|\(naam.uppercased())")
            }
        }
    }
}

// MARK: - Kind (wachtlijst of op les)

struct ZwKindView: View {
    let id: String
    @EnvironmentObject var model: ZwemmenModel
    @EnvironmentObject var lang: LanguageManager
    @State private var afmelden: ZwLes?

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    if let k = model.kind(id) {
                        ZwPaginaTitel(titel: k.naam)
                        VStack(alignment: .leading, spacing: 24) {
                            if let b = model.bevestiging { ZwBevestiging(tekst: b) }
                            if k.status == .wacht { wachtlijst(k) } else { opLes(k) }
                        }
                        .padding(.horizontal, ZwStijl.pad)
                    }
                }
                .padding(.bottom, 80)
            }
            ZwTerugBalk { model.terug() }
        }
        .ignoresSafeArea(edges: .top)
        .onDisappear { model.bevestiging = nil }
        .sheet(item: $afmelden) { les in
            if let k = model.kind(id) {
                ZwAfmeldSheet(kind: k, les: les) {
                    model.wijzig(id) { $0.afgemeld.append(les.key) }
                    model.bevestiging = lang.t("zw_cancelled_msg", k.naam, lang.zw.weekdagDagMaand(les.datum).lowercased())
                    afmelden = nil
                } annuleer: { afmelden = nil }
                .environmentObject(lang)
                .presentationDetents([.height(320)])
                .presentationCornerRadius(32)
            }
        }
    }

    @ViewBuilder
    private func wachtlijst(_ k: ZwKind) -> some View {
        let opgeschoven = k.startPlek - k.plek
        ZwGroteKaart(label: lang.t("zw_on_waitlist"), groot: lang.t("zw_number", k.plek)) {
            Text(lang.t("zw_at_pool", k.zwembad) + (k.extra.isEmpty ? "" : " · " + lang.t("zw_also_fine_list", k.extra.joined(separator: ", "))))
                .font(ZwStijl.tekst).foregroundColor(AppColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            if opgeschoven > 0 {
                Text(lang.t("zw_moved_up", opgeschoven, k.sinds.map { lang.zw.volledig($0) } ?? ""))
                    .font(AppFont.theSans(size: 16, weight: .bold)).foregroundColor(AppColors.groen4)
            } else {
                Text(lang.t("zw_registered_on", k.sinds.map { lang.zw.volledig($0) } ?? ""))
                    .font(AppFont.theSans(size: 16, weight: .plain)).foregroundColor(AppColors.grijs4)
            }
            VStack(alignment: .leading, spacing: 6) {
                ZwScheiding(zacht: true)
                HStack {
                    Text(lang.t("zw_expected_call")).font(ZwStijl.tekst)
                    Spacer()
                    Text(k.oproep.map { lang.zw.maandJaar($0) } ?? "-").font(ZwStijl.tekstVet)
                }
                .foregroundColor(AppColors.textPrimary)
                .padding(.top, 6)
                Text(lang.t("zw_indication_note")).font(AppFont.theSans(size: 16, weight: .plain)).foregroundColor(AppColors.textSecondary)
            }
            .padding(.top, 12)
        }

        ZwSectie(titel: lang.t("zw_what_next")) {
            VStack(alignment: .leading, spacing: 0) {
                tijdlijnStap(lang.t("zw_tl_registered"), k.sinds.map { lang.zw.volledig($0) } ?? "", .klaar)
                tijdlijnStap(lang.t("zw_on_waitlist"), lang.t("zw_now"), .nu)
                tijdlijnStap(lang.t(k.ervaring ? "zw_tl_invite_test" : "zw_tl_invite_first"),
                             lang.t("zw_expected_in", k.oproep.map { lang.zw.maandJaar($0) } ?? ""), .straks)
                tijdlijnStap(lang.t("zw_tl_first_lesson"), lang.t("zw_tl_first_lesson_sub"), .straks, laatste: true)
            }
        }

        ZwWachtverzachter(naam: k.naam)

        ZwLijst {
            ZwLinkRij(icoon: "zw-pool", titel: lang.t("zw_situation_changed"), sub: lang.t("zw_situation_changed_sub")) {}
        }
    }

    private enum StapStatus { case klaar, nu, straks }

    private func tijdlijnStap(_ titel: String, _ sub: String, _ s: StapStatus, laatste: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 0) {
                Circle()
                    .fill(s == .klaar ? AppColors.groen3 : Color.white)
                    .overlay(Circle().stroke(s == .straks ? ZwStijl.lijn : AppColors.groen3, lineWidth: s == .nu ? 5 : 2))
                    .frame(width: 16, height: 16)
                    .padding(.top, 4)
                if !laatste {
                    Rectangle().fill(s == .klaar ? AppColors.groen3 : ZwStijl.lijn).frame(width: 2).frame(maxHeight: .infinity)
                        .padding(.top, 2)
                }
            }
            .frame(width: 20)
            VStack(alignment: .leading, spacing: 0) {
                Text(titel).font(ZwStijl.tekstVet).foregroundColor(AppColors.textPrimary)
                Text(sub).font(ZwStijl.klein).foregroundColor(AppColors.textSecondary)
            }
            .padding(.bottom, laatste ? 0 : 20)
            .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private func opLes(_ k: ZwKind) -> some View {
        if let les = ZwData.volgendeLes(k) {
            ZwGroteKaart(label: lang.t("zw_next_lesson"), groot: lang.zw.weekdagDagMaand(les.datum), kleiner: true) {
                Text("\(k.lestijd) · \(k.zwembad) · \(lang.t("zw_diploma", k.diploma))")
                    .font(ZwStijl.tekst).foregroundColor(AppColors.textPrimary)
                ZwOmlijndeKnop(titel: lang.t("zw_cancel_lesson")) { afmelden = les }
                    .padding(.top, 12)
            }
        }

        navKaart(titel: lang.t("zw_progress"), regel: lang.t("zw_diploma_level", k.diploma, k.niveau),
                 extra: lang.t("zw_gold_count", k.gouden, k.oefeningen.count), balk: k.niveau) {
            model.push(.voortgang(k.id))
        }
        navKaart(titel: lang.t("zw_subscription"),
                 regel: lang.t("zw_monthly_valid_until", lang.zw.volledig(ZwData.maandEinde(k.verlengd ? 1 : 0))),
                 extra: k.verlengd ? nil : lang.t("zw_renew_for", lang.zw.maand(ZwData.volgendeMaand.datum))) {
            model.push(.abonnement(k.id))
        }

        ZwSectie(titel: lang.t("zw_upcoming_lessons")) {
            ZwLijst {
                ForEach(Array(ZwData.lessen(k, 4).enumerated()), id: \.offset) { i, les in
                    if i > 0 { ZwScheiding() }
                    ZwRij(titel: lang.zw.weekdagDagMaand(les.datum), sub: "\(k.lestijd) · \(k.zwembad)", titelDonker: true) {
                        if k.afgemeld.contains(les.key) {
                            Text(lang.t("zw_cancelled"))
                                .font(AppFont.theSans(size: 14, weight: .semiBold))
                                .foregroundColor(AppColors.textSecondary)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(AppColors.warmGrijs)
                                .cornerRadius(4)
                        } else {
                            Button { afmelden = les } label: {
                                Text(lang.t("zw_cancel")).font(AppFont.theSans(size: 18, weight: .bold)).foregroundColor(AppColors.blauw3)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            Text(lang.t("zw_three_missed_note")).font(AppFont.theSans(size: 16, weight: .plain)).foregroundColor(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }

        ZwSectie(titel: lang.t("zw_important_dates")) {
            ZwLijst {
                ZwRij(titel: lang.t("zw_viewing_days"), sub: lang.t("zw_viewing_days_sub"), titelDonker: true) {
                    Text(lang.t("zw_viewing_days_date")).font(ZwStijl.tekst).foregroundColor(AppColors.textPrimary)
                }
                ZwScheiding()
                ZwRij(titel: lang.t("zw_diploma_swim_a"), titelDonker: true) {
                    Text(lang.zw.dagMaand(ZwData.datum(2026, 12, 16))).font(ZwStijl.tekst).foregroundColor(AppColors.textPrimary)
                }
            }
        }
    }

    private func navKaart(titel: String, regel: String, extra: String?, balk: Int? = nil, actie: @escaping () -> Void) -> some View {
        Button(action: actie) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(titel).font(ZwStijl.kop).foregroundColor(AppColors.textPrimary)
                    Spacer()
                    ZwPijl()
                }
                Text(regel).font(ZwStijl.tekst).foregroundColor(AppColors.textPrimary)
                if let balk { ZwNiveauBalk(niveau: balk).padding(.vertical, 4) }
                if let extra { Text(extra).font(ZwStijl.klein).foregroundColor(AppColors.textSecondary) }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .overlay(RoundedRectangle(cornerRadius: ZwStijl.lijstRadius).stroke(ZwStijl.lijn, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Les afmelden (sheet)

struct ZwAfmeldSheet: View {
    let kind: ZwKind
    let les: ZwLes
    let bevestig: () -> Void
    let annuleer: () -> Void
    @EnvironmentObject var lang: LanguageManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(lang.t("zw_cancel_lesson_q")).font(ZwStijl.kop).foregroundColor(AppColors.textPrimary)
            Text(lang.t("zw_cancel_lesson_text", kind.naam, lang.zw.weekdagDagMaand(les.datum).lowercased(), kind.lestijd))
                .font(ZwStijl.tekst).foregroundColor(AppColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            ZwPrimaireKnop(titel: lang.t("zw_cancel"), actie: bevestig)
            ZwTekstKnop(titel: lang.t("zw_keep"), actie: annuleer)
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .padding(.bottom, 8)
    }
}

extension ZwLes: Identifiable { var id: String { key } }

// MARK: - Voortgang

struct ZwVoortgangView: View {
    let id: String
    @EnvironmentObject var model: ZwemmenModel
    @EnvironmentObject var lang: LanguageManager

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    if let k = model.kind(id) {
                        ZwPaginaTitel(titel: lang.t("zw_progress_of", k.naam))
                        VStack(alignment: .leading, spacing: 32) {
                            ZwGroteKaart(label: lang.t("zw_diploma", k.diploma), groot: lang.t("zw_level_of", k.niveau), kleiner: true) {
                                ZwNiveauBalk(niveau: k.niveau).padding(.vertical, 8)
                                Text(lang.t("zw_updated_by", k.bijgewerkt.map { lang.zw.dagMaand($0) } ?? ""))
                                    .font(AppFont.theSans(size: 16, weight: .plain)).foregroundColor(AppColors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            ZwSectie(titel: lang.t("zw_exercises")) {
                                Text(lang.t("zw_exercises_text", k.gouden, k.oefeningen.count, k.naam, k.naam))
                                    .font(ZwStijl.tekst).foregroundColor(AppColors.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                                ZwLijst {
                                    ForEach(Array(k.oefeningen.enumerated()), id: \.offset) { i, o in
                                        if i > 0 { ZwScheiding() }
                                        HStack(spacing: 12) {
                                            ZwSter(niveau: o.niveau)
                                            Text(lang.t(o.key)).font(ZwStijl.tekst).foregroundColor(AppColors.textPrimary)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .fixedSize(horizontal: false, vertical: true)
                                            Text(lang.t(ZwSter.naamKey(o.niveau)))
                                                .font(AppFont.theSans(size: 14, weight: .semiBold))
                                                .foregroundColor(AppColors.textSecondary)
                                                .padding(.horizontal, 8).padding(.vertical, 4)
                                                .background(AppColors.warmGrijs)
                                                .cornerRadius(4)
                                        }
                                        .padding(16)
                                    }
                                }
                            }
                            ZwSectie(titel: lang.t("zw_stars_meaning")) {
                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(1...3, id: \.self) { n in
                                        HStack(spacing: 12) {
                                            ZwSter(niveau: n)
                                            Text(lang.t("zw_star_legend_\(n)")).font(ZwStijl.tekst).foregroundColor(AppColors.textSecondary)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, ZwStijl.pad)
                    }
                }
                .padding(.bottom, 80)
            }
            ZwTerugBalk { model.terug() }
        }
        .ignoresSafeArea(edges: .top)
    }
}

struct ZwSter: View {
    let niveau: Int
    static func naamKey(_ n: Int) -> String { n == 3 ? "zw_gold" : n == 2 ? "zw_silver" : "zw_bronze" }
    var body: some View {
        ZwIcon(naam: "zw-star", kleur: niveau == 3 ? Color(hex: "E3A008") : niveau == 2 ? Color(hex: "9AA0A6") : Color(hex: "B87333"))
            .accessibilityHidden(true)
    }
}

// MARK: - Abonnement

struct ZwAbonnementView: View {
    let id: String
    @EnvironmentObject var model: ZwemmenModel
    @EnvironmentObject var lang: LanguageManager

    var body: some View {
        let k = model.kind(id)
        let maand = ZwData.volgendeMaand
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        if let k {
                            ZwPaginaTitel(titel: lang.t("zw_subscription_of", k.naam))
                            VStack(alignment: .leading, spacing: 32) {
                                if let b = model.bevestiging { ZwBevestiging(tekst: b) }
                                ZwGroteKaart(label: lang.t("zw_monthly_15"),
                                             groot: lang.t("zw_valid_until_incl", lang.zw.volledig(ZwData.maandEinde(k.verlengd ? 1 : 0))),
                                             kleiner: true) {
                                    Text("\(k.naam) · \(k.zwembad)").font(ZwStijl.tekst).foregroundColor(AppColors.textPrimary)
                                }
                                if !k.verlengd {
                                    ZwSectie(titel: lang.t("zw_renew_for_title", lang.zw.maand(maand.datum))) {
                                        ZwLijst {
                                            ZwRij(titel: lang.t("zw_monthly_for", lang.zw.maand(maand.datum)), titelDonker: true) {
                                                Text(maand.gratis ? lang.t("zw_free") : "€28,80").font(ZwStijl.tekstVet).foregroundColor(AppColors.textPrimary)
                                            }
                                        }
                                    }
                                }
                                ZwSectie(titel: lang.t("zw_good_to_know")) {
                                    Text(lang.t("zw_summer_free")).font(ZwStijl.tekst).foregroundColor(AppColors.textPrimary)
                                    Text(lang.t("zw_ooievaarspas_lessons")).font(ZwStijl.tekst).foregroundColor(AppColors.textPrimary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding(.horizontal, ZwStijl.pad)
                        }
                    }
                    .padding(.bottom, 32)
                }
                ZwTerugBalk { model.terug() }
            }
            if let k, !k.verlengd {
                ZwKnoppenBalk {
                    ZwPrimaireKnop(titel: lang.t("zw_renew_and_pay")) {
                        model.wijzig(id) { $0.verlengd = true }
                        model.bevestiging = lang.t("zw_renewed_msg", lang.zw.volledig(ZwData.maandEinde(1)))
                    }
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .onDisappear { model.bevestiging = nil }
    }
}
