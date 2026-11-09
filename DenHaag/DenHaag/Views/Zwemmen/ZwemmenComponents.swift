import SwiftUI
import CoreImage.CIFilterBuiltins

// MARK: - Bouwstenen van de mini-app Zwemmen
//
// Vertaling van de prototype-CSS naar het design system van de app:
// kleuren uit AppColors, fonts uit AppFont, padding uit AppDesign.

enum ZwStijl {
    static let pad = AppDesign.horizontalPadding
    static let lijn = AppColors.grijs2
    static let lijnZacht = AppColors.tegelBorder
    static let lijstRadius: CGFloat = 8

    static func titel(_ size: CGFloat = 26) -> Font { AppFont.theMix(size: size, weight: .bold) }
    static let kop = AppFont.theMix(size: 20, weight: .bold)
    static let tekst = AppFont.theSans(size: 18, weight: .plain)
    static let tekstVet = AppFont.theSans(size: 18, weight: .semiBold)
    static let klein = AppFont.theSans(size: 14, weight: .plain)
    static let label = AppFont.theSans(size: 12, weight: .bold)
}

// MARK: Iconen

struct ZwIcon: View {
    let naam: String
    var maat: CGFloat = 24
    var kleur: Color = AppColors.darkGrey

    var body: some View {
        Image(naam)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: maat, height: maat)
            .foregroundColor(kleur)
    }
}

struct ZwPijl: View {
    var kleur: Color = AppColors.darkGrey
    var body: some View { ZwIcon(naam: "arrow-right", maat: 20, kleur: kleur) }
}

// MARK: Koppen

/// Paginatitel naast de (zwevende) terugknop. Scrollt mee met de inhoud.
struct ZwPaginaTitel: View {
    let titel: String
    var body: some View {
        HStack(alignment: .top) {
            Spacer().frame(width: 52)
            Text(titel)
                .font(ZwStijl.titel())
                .foregroundColor(AppColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, ZwStijl.pad)
        .padding(.top, AppDesign.safeAreaTop + 12)
    }
}

/// Zwevende terugknop linksboven; optioneel een tweede knop rechts.
struct ZwTerugBalk<Rechts: View>: View {
    let actie: () -> Void
    @ViewBuilder var rechts: Rechts

    var body: some View {
        HStack {
            BackCircleButton(action: actie)
            Spacer()
            rechts
        }
        .padding(.horizontal, ZwStijl.pad)
        .padding(.top, AppDesign.safeAreaTop + 8)
    }
}

extension ZwTerugBalk where Rechts == EmptyView {
    init(actie: @escaping () -> Void) { self.actie = actie; self.rechts = EmptyView() }
}

struct ZwSectie<Inhoud: View>: View {
    let titel: String
    var actie: (titel: String, doe: () -> Void)? = nil
    @ViewBuilder var inhoud: Inhoud

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text(titel)
                    .font(ZwStijl.kop)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                if let actie {
                    Button(action: actie.doe) {
                        Text(actie.titel)
                            .font(AppFont.theSans(size: 18, weight: .bold))
                            .foregroundColor(AppColors.blauw3)
                    }
                    .buttonStyle(.plain)
                }
            }
            inhoud
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: Lijsten

/// Omkaderde lijst met rijen; plaats `ZwScheiding()` tussen de rijen.
struct ZwLijst<Inhoud: View>: View {
    @ViewBuilder var inhoud: Inhoud
    var body: some View {
        VStack(spacing: 0) { inhoud }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: ZwStijl.lijstRadius))
            .overlay(RoundedRectangle(cornerRadius: ZwStijl.lijstRadius).stroke(ZwStijl.lijn, lineWidth: 1))
    }
}

struct ZwScheiding: View {
    var zacht = false
    var body: some View { Rectangle().fill(zacht ? ZwStijl.lijnZacht : ZwStijl.lijn).frame(height: 1) }
}

/// Lijstrij: icoon · tekst (+ subtekst) · iets rechts.
struct ZwRij<Rechts: View>: View {
    var icoon: String? = nil
    let titel: String
    var sub: String? = nil
    var titelDonker = false
    @ViewBuilder var rechts: Rechts

    var body: some View {
        HStack(alignment: sub == nil ? .center : .top, spacing: 12) {
            if let icoon { ZwIcon(naam: icoon).padding(.top, sub == nil ? 0 : 1) }
            VStack(alignment: .leading, spacing: 2) {
                Text(titel)
                    .font(ZwStijl.tekst)
                    .foregroundColor(titelDonker ? AppColors.textPrimary : AppColors.textSecondary)
                if let sub {
                    Text(sub)
                        .font(ZwStijl.klein)
                        .foregroundColor(AppColors.grijs4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            rechts
        }
        .padding(16)
        .contentShape(Rectangle())
    }
}

/// Tikbare lijstrij met pijl.
struct ZwLinkRij: View {
    var icoon: String? = nil
    let titel: String
    var sub: String? = nil
    let actie: () -> Void

    var body: some View {
        Button(action: actie) {
            ZwRij(icoon: icoon, titel: titel, sub: sub) { ZwPijl() }
        }
        .buttonStyle(.plain)
    }
}

// MARK: Status

/// Statuslabel met stip, zoals "NU BEZIG" of "AFGELOPEN".
struct ZwStatus: View {
    enum Stijl { case live, grijs }
    let tekst: String
    var stijl: Stijl = .live

    var body: some View {
        HStack(spacing: 4) {
            ZwStip(stijl: stijl)
            Text(tekst.uppercased())
                .font(ZwStijl.label)
                .tracking(1)
                .foregroundColor(stijl == .live ? AppColors.groen3 : AppColors.grijs4)
                .lineLimit(1)
        }
    }
}

struct ZwStip: View {
    var stijl: ZwStatus.Stijl = .live
    var body: some View {
        Circle()
            .fill(stijl == .live ? AppColors.groen3 : AppColors.grijs4)
            .frame(width: 12, height: 12)
            .overlay(Circle().stroke(stijl == .live ? AppColors.groen1 : Color(hex: "F1F1F1"), lineWidth: 2))
            .frame(width: 16, height: 16)
    }
}

/// Groen kapitaal label met vinkje, zoals "GERESERVEERD".
struct ZwVinkLabel: View {
    let tekst: String
    var body: some View {
        HStack(spacing: 4) {
            ZwIcon(naam: "zw-check", maat: 16, kleur: AppColors.groen4)
            Text(tekst.uppercased())
                .font(ZwStijl.label)
                .tracking(1)
                .foregroundColor(AppColors.groen4)
        }
    }
}

struct ZwKapitaal: View {
    let tekst: String
    var kleur: Color = AppColors.textSecondary
    var body: some View {
        Text(tekst.uppercased())
            .font(ZwStijl.label)
            .tracking(1)
            .foregroundColor(kleur)
    }
}

// MARK: Knoppen

struct ZwPrimaireKnop: View {
    let titel: String
    let actie: () -> Void

    var body: some View {
        Button(action: actie) {
            Text(titel)
                .font(AppFont.theSans(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(AppColors.groen3)
                .cornerRadius(AppDesign.cornerRadius)
        }
        .buttonStyle(.plain)
    }
}

/// Groene omlijnde knop, zoals "Filters (0)" of "Toon QR-code" in een kaart.
struct ZwOmlijndeKnop: View {
    let titel: String
    var icoon: String? = nil
    var breed = false
    let actie: () -> Void

    var body: some View {
        Button(action: actie) {
            HStack(spacing: 6) {
                if let icoon { ZwIcon(naam: icoon, maat: 20, kleur: AppColors.groen3) }
                Text(titel)
                    .font(AppFont.theSans(size: 18, weight: .bold))
                    .lineLimit(1)
            }
            .foregroundColor(AppColors.groen3)
            .padding(.horizontal, 14)
            .frame(minHeight: 44)
            .frame(maxWidth: breed ? .infinity : nil)
            .overlay(RoundedRectangle(cornerRadius: AppDesign.cornerRadius).stroke(AppColors.groen3, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct ZwTekstKnop: View {
    let titel: String
    var kleur: Color = AppColors.groen3
    let actie: () -> Void
    var body: some View {
        Button(action: actie) {
            Text(titel)
                .font(AppFont.theSans(size: 18, weight: .bold))
                .foregroundColor(kleur)
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.plain)
    }
}

/// Witte balk onderaan met één of meer knoppen.
struct ZwKnoppenBalk<Inhoud: View>: View {
    @ViewBuilder var inhoud: Inhoud
    var body: some View {
        VStack(spacing: 8) { inhoud }
            .padding(.horizontal, ZwStijl.pad)
            .padding(.top, 16)
            .padding(.bottom, 12)
            .background(
                Color.white
                    .shadow(color: .black.opacity(0.06), radius: 8, y: -2)
                    .ignoresSafeArea(edges: .bottom)
            )
    }
}

// MARK: Kaarten

/// Datumblokje: maand · dag · weekdag.
struct ZwDatumBlok: View {
    let datum: Date
    @EnvironmentObject var lang: LanguageManager

    var body: some View {
        VStack(spacing: 0) {
            Text(lang.zw.maandKort(datum).uppercased())
                .font(ZwStijl.label)
                .tracking(1)
                .foregroundColor(AppColors.groen4)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 3)
                .background(AppColors.groen1)
            Text(lang.zw.dagNummer(datum))
                .font(AppFont.theMix(size: 18, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .padding(.top, 2)
            Text(lang.zw.weekdagKort(datum))
                .font(AppFont.theSans(size: 16, weight: .plain))
                .foregroundColor(AppColors.grijs4)
                .padding(.bottom, 4)
        }
        .frame(width: 64)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.black.opacity(0.08), lineWidth: 1))
    }
}

/// Fotootje van een zwembad.
struct ZwZwembadFoto: View {
    let zwembad: String
    var maat: CGFloat = 56
    var body: some View {
        Group {
            if let foto = ZwData.zwembad(zwembad)?.foto {
                Image(foto).resizable().scaledToFill()
            } else {
                ZwIcon(naam: "zw-pool")
            }
        }
        .frame(width: maat, height: maat)
        .background(Color(hex: "D9D9D9"))
        .clipShape(RoundedRectangle(cornerRadius: AppDesign.cornerRadius))
    }
}

/// Zwembadkaart: foto · naam · status van vandaag (of adres).
struct ZwZwembadKaart: View {
    let zwembad: String
    var toonAdres = false
    let actie: () -> Void
    @EnvironmentObject var lang: LanguageManager

    var body: some View {
        Button(action: actie) {
            HStack(spacing: 16) {
                ZwZwembadFoto(zwembad: zwembad)
                VStack(alignment: .leading, spacing: 2) {
                    Text(zwembad)
                        .font(ZwStijl.tekstVet)
                        .foregroundColor(AppColors.textPrimary)
                    if toonAdres {
                        Text(ZwData.zwembad(zwembad)?.adres ?? "")
                            .font(AppFont.theSans(size: 16, weight: .plain))
                            .foregroundColor(AppColors.textSecondary)
                    } else {
                        ZwZwembadStatus(zwembad: zwembad)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                ZwPijl()
            }
            .padding(16)
            .background(AppColors.warmGrijs)
            .cornerRadius(AppDesign.cornerRadius)
        }
        .buttonStyle(.plain)
    }
}

/// Status op de zwembadkaart: de activiteit die nu bezig is, anders de eerstvolgende
/// van vandaag, anders de eerstvolgende dag.
struct ZwZwembadStatus: View {
    let zwembad: String
    @EnvironmentObject var lang: LanguageManager

    var body: some View {
        let nu = ZwData.nuMinuten
        let vandaag = ZwData.rooster(0, zwembad: zwembad)
        if let bezig = vandaag.first(where: { $0.startMin <= nu && nu < $0.eindMin }) {
            regel(.live, naam: bezig.naam, tijd: lang.t("zw_until", bezig.eind))
        } else if let straks = vandaag.first(where: { $0.startMin > nu }) {
            regel(.grijs, naam: straks.naam, tijd: lang.t("zw_from", straks.start))
        } else if let d = ZwData.volgendeDag(zwembad: zwembad), let a = ZwData.rooster(d, zwembad: zwembad).first {
            regel(.grijs, voor: d == 1 ? lang.t("zw_tomorrow") : lang.zw.kortDatum(ZwData.dag(d)), naam: a.naam, tijd: lang.t("zw_from", a.start))
        } else {
            ZwStatus(tekst: lang.t("zw_none_two_weeks"), stijl: .grijs)
        }
    }

    private func regel(_ stijl: ZwStatus.Stijl, voor: String? = nil, naam: String, tijd: String) -> some View {
        HStack(spacing: 6) {
            ZwStip(stijl: stijl)
            if let voor { ZwKapitaal(tekst: voor, kleur: stijl == .live ? AppColors.groen3 : AppColors.grijs4).fixedSize() }
            ZwKapitaal(tekst: naam, kleur: stijl == .live ? AppColors.groen3 : AppColors.grijs4)
                .lineLimit(1)
                .truncationMode(.tail)
            ZwKapitaal(tekst: tijd, kleur: AppColors.textSecondary).fixedSize()
        }
    }
}

/// Activiteit in een lijst: zwemmer · tijd (+ status) · naam · zwembad.
struct ZwActiviteitRij: View {
    let activiteit: ZwActiviteit
    var status: Status = .geen
    var toonZwembad = true
    let actie: () -> Void
    @EnvironmentObject var lang: LanguageManager

    enum Status { case geen, bezig, afgelopen }

    var body: some View {
        Button(action: actie) {
            HStack(alignment: .center, spacing: 16) {
                Image("zw-zwemmer-thumb")
                    .resizable()
                    .frame(width: 56, height: 56)
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 8) {
                        Text(activiteit.tijd)
                            .font(ZwStijl.tekst)
                            .foregroundColor(AppColors.textSecondary)
                        if status == .bezig { ZwStatus(tekst: lang.t("zw_now_on")) }
                        if status == .afgelopen { ZwStatus(tekst: lang.t("zw_finished"), stijl: .grijs) }
                    }
                    Text(activiteit.naam)
                        .font(ZwStijl.tekstVet)
                        .foregroundColor(AppColors.textPrimary)
                        .multilineTextAlignment(.leading)
                    if toonZwembad {
                        Text(activiteit.zwembad)
                            .font(ZwStijl.tekst)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 20)
            .opacity(status == .afgelopen ? 0.5 : 1)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Reserveringskaart met datumblok en QR-knop.
struct ZwReserveringKaart: View {
    let reservering: ZwReservering
    var omlijnd = false
    let toonQR: () -> Void
    @EnvironmentObject var lang: LanguageManager

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 20) {
                ZwDatumBlok(datum: reservering.datum)
                VStack(alignment: .leading, spacing: 4) {
                    ZwVinkLabel(tekst: lang.t("zw_reserved"))
                    Text(reservering.activiteit.naam)
                        .font(AppFont.theSans(size: 20, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                    Text("\(reservering.activiteit.tijd) · \(reservering.activiteit.zwembad)")
                        .font(ZwStijl.klein)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            ZwPrimaireKnop(titel: lang.t("zw_show_qr"), actie: toonQR)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(AppDesign.cornerRadius)
        .overlay(RoundedRectangle(cornerRadius: AppDesign.cornerRadius).stroke(omlijnd ? ZwStijl.lijn : .clear, lineWidth: 1))
        .shadow(color: .black.opacity(omlijnd ? 0 : 0.1), radius: 8, x: 0, y: 4)
    }
}

/// Warm grijs vlak met titel, tekst en optioneel een knop.
struct ZwWarmeKaart<Onder: View>: View {
    let titel: String
    let tekst: String
    @ViewBuilder var onder: Onder

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titel).font(ZwStijl.tekstVet).foregroundColor(AppColors.textPrimary)
            Text(tekst).font(ZwStijl.tekst).foregroundColor(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            onder.padding(.top, 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.warmGrijs)
        .cornerRadius(AppDesign.cornerRadius)
    }
}

/// Omkaderde kaart met kapitaal label en groot getal of datum.
struct ZwGroteKaart<Inhoud: View>: View {
    let label: String
    let groot: String
    var kleiner = false
    @ViewBuilder var inhoud: Inhoud

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZwKapitaal(tekst: label)
            Text(groot)
                .font(AppFont.theMix(size: kleiner ? 24 : 32, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            inhoud
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(RoundedRectangle(cornerRadius: ZwStijl.lijstRadius).stroke(ZwStijl.lijn, lineWidth: 1))
    }
}

/// Groene bevestiging bovenaan een scherm.
struct ZwBevestiging: View {
    let tekst: String
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            ZwIcon(naam: "zw-check", maat: 20, kleur: AppColors.groen4).padding(.top, 2)
            Text(tekst)
                .font(AppFont.theSans(size: 18, weight: .bold))
                .foregroundColor(AppColors.groen4)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(AppColors.groen1)
        .cornerRadius(AppDesign.cornerRadius)
    }
}

/// Blauwe infobalk.
struct ZwBlauweNoot: View {
    let tekst: String
    var body: some View {
        Text(tekst)
            .font(ZwStijl.tekst)
            .foregroundColor(AppColors.blauw3)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.blauw1)
            .cornerRadius(AppDesign.cornerRadius)
    }
}

/// Niveau-balk van 7 blokjes.
struct ZwNiveauBalk: View {
    let niveau: Int
    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...7, id: \.self) { i in
                RoundedRectangle(cornerRadius: 4)
                    .fill(i < niveau ? AppColors.groen3 : i == niveau ? AppColors.groen1 : ZwStijl.lijnZacht)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(i == niveau ? AppColors.groen3 : .clear, lineWidth: 2))
                    .frame(height: 8)
            }
        }
    }
}

/// Keuzerondje of vinkvakje met label.
struct ZwKeuze: View {
    let titel: String
    var sub: String? = nil
    let aan: Bool
    var vakje = false
    let actie: () -> Void

    var body: some View {
        Button(action: actie) {
            HStack(spacing: 16) {
                ZStack {
                    if vakje {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(aan ? AppColors.groen3 : .white)
                            .overlay(RoundedRectangle(cornerRadius: 3).stroke(aan ? AppColors.groen3 : AppColors.textSecondary, lineWidth: 1))
                        if aan { ZwIcon(naam: "zw-check", maat: 16, kleur: .white) }
                    } else {
                        Circle().fill(.white)
                            .overlay(Circle().stroke(aan ? AppColors.groen3 : AppColors.textSecondary, lineWidth: aan ? 2 : 1))
                        if aan { Circle().fill(AppColors.groen3).frame(width: 12, height: 12) }
                    }
                }
                .frame(width: 22, height: 22)
                VStack(alignment: .leading, spacing: 2) {
                    Text(titel)
                        .font(aan ? ZwStijl.tekstVet : ZwStijl.tekst)
                        .foregroundColor(AppColors.textPrimary)
                    if let sub {
                        Text(sub).font(ZwStijl.klein).foregroundColor(AppColors.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(aan ? .isSelected : [])
    }
}

/// Kop van een bottom sheet: sluitknop + titel.
struct ZwSheetKop: View {
    let titel: String
    let sluit: () -> Void
    var body: some View {
        HStack(spacing: 16) {
            Button(action: sluit) {
                ZwIcon(naam: "zw-close", maat: 20, kleur: AppColors.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(Color.white)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(AppColors.grijs2, lineWidth: 1))
            }
            .buttonStyle(.plain)
            Text(titel).font(ZwStijl.kop).foregroundColor(AppColors.textPrimary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }
}

// MARK: QR-code

enum ZwQRCode {
    static func plaatje(_ tekst: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(tekst.utf8)
        filter.correctionLevel = "M"
        guard let uit = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 10, y: 10)),
              let cg = CIContext().createCGImage(uit, from: uit.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}

/// Schermvullende QR-code om te laten scannen bij de ingang.
struct ZwQRScherm: View {
    let qr: ZwQR
    let sluit: () -> Void
    @EnvironmentObject var lang: LanguageManager

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: sluit) {
                    ZwIcon(naam: "zw-close", maat: 20, kleur: AppColors.textPrimary)
                        .frame(width: 40, height: 40)
                        .overlay(Circle().stroke(AppColors.grijs2, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(lang.t("zw_close"))
            }
            .padding(.horizontal, ZwStijl.pad)
            .padding(.top, 8)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    VStack(spacing: 6) {
                        if qr.toonVinkje { ZwVinkLabel(tekst: qr.status) } else { ZwKapitaal(tekst: qr.status, kleur: AppColors.groen4) }
                        Text(qr.titel)
                            .font(ZwStijl.titel(32))
                            .foregroundColor(AppColors.textPrimary)
                        ForEach(qr.regels, id: \.self) { r in
                            Text(r).font(AppFont.theSans(size: 20, weight: .plain)).foregroundColor(AppColors.textSecondary)
                        }
                    }
                    .multilineTextAlignment(.center)

                    Group {
                        if let img = ZwQRCode.plaatje(qr.code) {
                            Image(uiImage: img).interpolation(.none).resizable().scaledToFit()
                        }
                    }
                    .padding(20)
                    .frame(width: 280, height: 280)
                    .overlay(RoundedRectangle(cornerRadius: ZwStijl.lijstRadius).stroke(ZwStijl.lijn, lineWidth: 1))
                    .accessibilityLabel(lang.t("zw_qr_label"))

                    Text(lang.t("zw_qr_hint"))
                        .font(ZwStijl.tekst)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 280)
                }
                .padding(.horizontal, ZwStijl.pad)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
        }
        .background(Color.white.ignoresSafeArea())
    }
}
