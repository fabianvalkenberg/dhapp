import SwiftUI

struct ChecklistItem: Identifiable {
    let id = UUID()
    let textKey: String
    var subKey: String? = nil
    var illustratie: String? = nil
    var isChecked: Bool = false
}

/// Detailscherm van de afspraak (geopend via de home-statuskaart "Bekijk afspraak").
/// Zelfde clean template als de andere detail-overlays: witte achtergrond, back-knop
/// met titel ernaast, en losse elementen zonder overbodige kaders.
struct AppointmentDetailView: View {
    @EnvironmentObject var lang: LanguageManager
    @EnvironmentObject var afspraak: AfspraakStore
    @EnvironmentObject var berichten: BerichtenStore
    @EnvironmentObject var versie: VersieManager
    var onClose: () -> Void = {}

    @State private var toonVerplaatsen = false
    @State private var toonAfzeggen = false
    /// Bevestiging na verplaatsen of afzeggen, bovenaan het scherm.
    @State private var bevestiging: String?

    @State private var floatingEmoji: String? = nil
    @State private var emojiOffset: CGFloat = 0
    @State private var emojiOpacity: Double = 1
    @State private var emojiItemIndex: Int? = nil

    private let celebrationIcons = [
        "hand.thumbsup.fill", "hands.clap.fill", "hand.raised.fill", "star.fill",
        "heart.fill", "sparkles", "checkmark.seal.fill", "bolt.fill"
    ]

    // Design review 2026-11 (variant A): drie vaste punten met illustratie;
    // aangifte en toestemming staan achter "Kwijt, gestolen of voor een kind?".
    @State private var checklist: [ChecklistItem] = [
        ChecklistItem(textKey: "mee_paspoort", illustratie: "ill-mee-paspoort"),
        ChecklistItem(textKey: "mee_pasfoto", subKey: "mee_pasfoto_sub", illustratie: "ill-mee-pasfoto"),
        ChecklistItem(textKey: "mee_betaal", subKey: "mee_betaal_sub", illustratie: "ill-mee-betaal"),
        ChecklistItem(textKey: "mee_aangifte"),
        ChecklistItem(textKey: "mee_toestemming", subKey: "mee_toestemming_sub"),
    ]
    @State private var toonExtra = false
    @Environment(\.openURL) private var openURL

    private var safeTop: CGFloat { AppDesign.safeAreaTop }

    var body: some View {
        ZStack(alignment: .topLeading) {
            AppColors.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    // Ruimte voor de zwevende back-knop; titel staat eronder (zelfde
                    // template als de paspoort- en aanvraag-pagina).
                    Color.clear.frame(height: safeTop + 44)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(lang.t("your_appointment"))
                            .font(AppFont.theMix(size: 30, weight: .bold))
                            .foregroundColor(AppColors.darkGrey)
                        Text(lang.t("passport_request"))
                            .font(AppFont.theSans(size: 17, weight: .plain))
                            .foregroundColor(Color(hex: "595959"))
                    }

                    if let bevestiging {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppColors.groen3)
                            Text(bevestiging)
                                .font(AppFont.theSans(size: 16, weight: .semiBold))
                                .foregroundColor(AppColors.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColors.groen1.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    if afspraak.afgezegd {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(lang.t("afspraak_afgezegd_tekst"))
                                .font(AppFont.theSans(size: 17, weight: .plain))
                                .foregroundColor(AppColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                            actionButton(title: lang.t("afspraak_kies_moment"), filled: true) { toonVerplaatsen = true }
                        }
                    }

                    Group {
                        wanneer
                        waar
                    }
                    .opacity(afspraak.afgezegd ? 0.45 : 1)

                    neemMee
                    kosten
                    goedOmTeWeten

                    if !afspraak.afgezegd {
                        VStack(spacing: 12) {
                            actionButton(title: lang.t("reschedule"), filled: true) { toonVerplaatsen = true }
                            actionButton(title: lang.t("cancel_appointment"), filled: false) { toonAfzeggen = true }
                        }
                    }

                    Spacer().frame(height: 60)
                }
                .padding(.horizontal, AppDesign.horizontalPadding)
            }
            .bovenVervaging()

            // Zwevende back-knop (titel scrollt eronder weg) — zelfde patroon overal.
            BackCircleButton { onClose() }
                .terugknopPlek()
        }
        // De notch-hoogte zit al in safeTop; niet dubbel tellen.
        .ignoresSafeArea(edges: .top)
        .animation(.easeInOut(duration: 0.3), value: bevestiging)
        .animation(.easeInOut(duration: 0.3), value: afspraak.afgezegd)
        .sheet(isPresented: $toonVerplaatsen) {
            AfspraakVerplaatsenView { nieuw in
                let wasAfgezegd = afspraak.afgezegd
                afspraak.datum = nieuw
                afspraak.afgezegd = false
                let moment = "\(AfspraakStore.dag(nieuw)) om \(AfspraakStore.tijd(nieuw))"
                bevestiging = String(format: lang.t(wasAfgezegd ? "afspraak_gemaakt_bev" : "afspraak_verplaatst_bev"), moment)
                AnalyticsService.track(wasAfgezegd ? "afspraak_nieuw" : "afspraak_verplaatst")
                if versie.current.heeft(.notificaties) {
                    berichten.stuur(.afspraken, titel: lang.t("afspraak_bevestigd_push"),
                                    tekst: String(format: lang.t("afspraak_bevestigd_push_tekst"), moment), na: 2)
                }
            }
            .environmentObject(lang)
            .environmentObject(afspraak)
            .presentationDetents([.large])
        }
        .alert(lang.t("afspraak_afzeggen_vraag"), isPresented: $toonAfzeggen) {
            Button(lang.t("afspraak_niet_afzeggen"), role: .cancel) { }
            Button(lang.t("cancel_appointment"), role: .destructive) {
                afspraak.afgezegd = true
                bevestiging = lang.t("afspraak_afgezegd_bev")
                AnalyticsService.track("afspraak_afgezegd")
            }
        } message: {
            Text(String(format: lang.t("afspraak_afzeggen_msg"), "\(AfspraakStore.dag(afspraak.datum)) om \(AfspraakStore.tijd(afspraak.datum))"))
        }
    }

    // MARK: - Blokken (Figma variant A "Overzicht")

    private var datumDelen: (dag: String, nr: String, maand: String) {
        let f = DateFormatter()
        f.locale = Locale(identifier: lang.current.rawValue)
        func d(_ fmt: String) -> String {
            f.dateFormat = fmt
            return f.string(from: afspraak.datum).replacingOccurrences(of: ".", with: "")
        }
        return (d("EEE").lowercased(), d("d"), d("MMM").lowercased())
    }

    /// Wanneer: groen datumblok, volledige datum, tijd groot, "Zet in je agenda".
    private var wanneer: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 0) {
                Text(datumDelen.dag).font(AppFont.theSans(size: 14, weight: .plain))
                Text(datumDelen.nr).font(AppFont.theMix(size: 20, weight: .bold))
                Text(datumDelen.maand).font(AppFont.theSans(size: 14, weight: .plain))
            }
            .foregroundColor(.white)
            .frame(width: 64, height: 78)
            .background(AppColors.groen3)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(AfspraakStore.dag(afspraak.datum).eersteHoofdletter)
                    .font(AppFont.theSans(size: 17, weight: .bold))
                    .foregroundColor(AppColors.darkGrey)
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(AppColors.groen3)
                        .frame(width: 20, height: 20)
                    Text(String(format: lang.t("afspraak_om"), AfspraakStore.tijd(afspraak.datum)))
                        .font(AppFont.theMix(size: 22, weight: .bold))
                        .foregroundColor(AppColors.darkGrey)
                }
                Button {
                    // Prototype: nagebootst, er gaat niets naar je echte agenda.
                    bevestiging = lang.t("afspraak_in_agenda_bev")
                    AnalyticsService.track("afspraak_in_agenda")
                } label: {
                    Text(lang.t("afspraak_in_agenda"))
                        .font(AppFont.theSans(size: 15, weight: .bold))
                        .foregroundColor(AppColors.blauw3)
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(AppColors.warmGrijs)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    /// Waar: foto van de ingang + adres met Route.
    private var waar: some View {
        VStack(alignment: .leading, spacing: 14) {
            blokTitel(lang.t("afspraak_waar"))
            VStack(spacing: 0) {
                Image("stadhuis-spui")
                    .resizable().scaledToFill()
                    .frame(height: 150).frame(maxWidth: .infinity)
                    .clipped()
                HStack(spacing: 12) {
                    Image("location-pin").renderingMode(.template).resizable().scaledToFit()
                        .frame(width: 22, height: 22)
                        .foregroundColor(AppColors.darkGrey)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(lang.t("afspraak_locatie_naam"))
                            .font(AppFont.theSans(size: 16, weight: .bold))
                            .foregroundColor(AppColors.darkGrey)
                        Text(lang.t("afspraak_locatie_adres"))
                            .font(AppFont.theSans(size: 15, weight: .plain))
                            .foregroundColor(Color(hex: "595959"))
                    }
                    Spacer(minLength: 0)
                    Button {
                        let q = "Spui 70, 2511 BT Den Haag".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                        if let url = URL(string: "maps://?daddr=\(q)") { openURL(url) }
                        AnalyticsService.track("afspraak_route")
                    } label: {
                        Text(lang.t("zw_route"))
                            .font(AppFont.theSans(size: 16, weight: .bold))
                            .foregroundColor(AppColors.groen3)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "E8E6E2"), lineWidth: 1))
        }
    }

    /// Neem dit mee: afvinklijst met illustraties; extra's achter een link.
    private var neemMee: some View {
        VStack(alignment: .leading, spacing: 14) {
            blokTitel(lang.t("afspraak_neem_mee"))
            Text(lang.t("afspraak_vink_af"))
                .font(AppFont.theSans(size: 16, weight: .plain))
                .foregroundColor(Color(hex: "595959"))
            VStack(spacing: 0) {
                ForEach(Array(checklist.enumerated()), id: \.element.id) { index, item in
                    if index < 3 || toonExtra {
                        checklistRow(index: index, item: item)
                            .transition(.opacity)
                    }
                }
            }
            if !toonExtra {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) { toonExtra = true }
                } label: {
                    HStack(alignment: .center, spacing: 6) {
                        Text(lang.t("mee_extra_link"))
                            .font(AppFont.theSans(size: 16, weight: .bold))
                            .foregroundColor(AppColors.blauw3)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppColors.blauw3)
                            .frame(width: 24, height: 24)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var kosten: some View {
        VStack(alignment: .leading, spacing: 14) {
            blokTitel(lang.t("costs"))
            VStack(spacing: 0) {
                costRow(label: lang.t("passport_adult"), value: lang.t("passport_price"))
                Rectangle().fill(Color(hex: "E8E6E2")).frame(height: 1)
                costRow(label: lang.t("express_rate"), value: lang.t("express_price"))
            }
            .padding(.horizontal, 16)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: "E8E6E2"), lineWidth: 1))
        }
    }

    private var goedOmTeWeten: some View {
        VStack(alignment: .leading, spacing: 14) {
            blokTitel(lang.t("good_to_know"))
            tipRow(icoon: "clock", text: lang.t("afspraak_tip_tijd"))
            tipRow(icoon: "calendar", text: lang.t("afspraak_tip_ophalen"))
            Button {
                if let url = URL(string: "https://www.denhaag.nl/nl/paspoort-en-identiteitskaart/paspoort-voor-volwassene-aanvragen/") {
                    openURL(url)
                }
            } label: {
                HStack(spacing: 6) {
                    Text(lang.t("afspraak_meer_info"))
                        .font(AppFont.theSans(size: 16, weight: .bold))
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(width: 24, height: 24)
                }
                .foregroundColor(AppColors.blauw3)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private func blokTitel(_ t: String) -> some View {
        Text(t)
            .font(AppFont.theMix(size: 20, weight: .bold))
            .foregroundColor(AppColors.darkGrey)
    }

    // MARK: - Checklist-rij

    private func checklistRow(index: Int, item: ChecklistItem) -> some View {
        ZStack(alignment: .trailing) {
            Button {
                let wasChecked = checklist[index].isChecked
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    checklist[index].isChecked.toggle()
                }
                if !wasChecked { triggerEmoji(at: index) }
            } label: {
                HStack(spacing: 14) {
                    Group {
                        if let ill = item.illustratie {
                            Image(ill).resizable().scaledToFit()
                        } else {
                            Image(systemName: "doc.text")
                                .font(.system(size: 22))
                                .foregroundColor(AppColors.blauw3)
                        }
                    }
                    .frame(width: 44, height: 44)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(lang.t(item.textKey))
                            .font(AppFont.theSans(size: 17, weight: .bold))
                            .foregroundColor(item.isChecked ? AppColors.textSecondary : AppColors.darkGrey)
                            .strikethrough(item.isChecked, color: AppColors.textSecondary)
                        if let sub = item.subKey {
                            Text(lang.t(sub))
                                .font(AppFont.theSans(size: 15, weight: .plain))
                                .foregroundColor(Color(hex: "595959"))
                        }
                    }
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    ZStack {
                        Circle()
                            .stroke(item.isChecked ? AppColors.groen3 : Color(hex: "999999"), lineWidth: 1.5)
                            .frame(width: 26, height: 26)
                            .background(Circle().fill(item.isChecked ? AppColors.groen3 : Color.clear))
                        if item.isChecked {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .scaleEffect(item.isChecked ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: item.isChecked)
                }
                .padding(.vertical, 12)
                .frame(minHeight: 69)
                .contentShape(Rectangle())
                .overlay(alignment: .bottom) {
                    Rectangle().fill(Color(hex: "E8E6E2")).frame(height: 1)
                }
            }
            .buttonStyle(.plain)

            if emojiItemIndex == index, let icon = floatingEmoji {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(AppColors.groen3)
                    .offset(x: -1, y: emojiOffset)
                    .opacity(emojiOpacity)
                    .allowsHitTesting(false)
            }
        }
    }

    /// Figma: gevuld groen 50 hoog, of rood omlijnd; tekst gecentreerd, 17 vet.
    private func actionButton(title: String, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppFont.theSans(size: 17, weight: .bold))
                .foregroundColor(filled ? .white : Color(hex: "CC211A"))
                .frame(maxWidth: .infinity)
                .frame(height: filled ? 50 : 53)
                .background(filled ? AppColors.groen3 : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(filled ? Color.clear : Color(hex: "CC211A"), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Emoji-celebratie

    private func triggerEmoji(at index: Int) {
        let icon = celebrationIcons.randomElement() ?? "hand.thumbsup.fill"
        floatingEmoji = icon
        emojiItemIndex = index
        emojiOffset = 0
        emojiOpacity = 1
        withAnimation(.easeOut(duration: 0.8)) {
            emojiOffset = -50
            emojiOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            floatingEmoji = nil
            emojiItemIndex = nil
        }
    }

    // MARK: - Losse rijen

    private func costRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
        }
        .font(AppFont.theSans(size: 16, weight: .plain))
        .foregroundColor(AppColors.darkGrey)
        .padding(.vertical, 12)
    }

    private func tipRow(icoon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icoon)
                .font(.system(size: 18))
                .foregroundColor(AppColors.groen3)
                .frame(width: 22, height: 22)
            Text(text)
                .font(AppFont.theSans(size: 16, weight: .plain))
                .foregroundColor(AppColors.darkGrey)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
