import SwiftUI

/// Kleuren uit de Figma-schetsen voor de fietspas die (nog) niet in AppColors staan.
enum FietspasKleur {
    static let kop = Color(hex: "00913F")
    static let tekstZacht = Color(hex: "555555")
    static let vlak = Color(hex: "EDEBE6")
    static let knopRand = Color(hex: "D2D2D2")
}

/// De fietspas als kaart (Figma component "fietspas-kaart", node 3453:571).
/// Op ware grootte 260 breed; `schaal` verkleint alles evenredig, zoals de
/// miniatuur op het detailscherm (0,36).
struct FietspasKaartView: View {
    @EnvironmentObject var lang: LanguageManager
    let pas: Fietspas
    var schaal: CGFloat = 1

    private func s(_ v: CGFloat) -> CGFloat { v * schaal }

    var body: some View {
        VStack(spacing: 0) {
            // Kop: groen met gaatje en beeldmerk "Den Haag Fietst!"
            VStack(spacing: s(10)) {
                Image("fp-gaatje")
                    .resizable()
                    .frame(width: s(22), height: s(22))
                HStack(alignment: .bottom, spacing: s(6)) {
                    Image("fp-logo-fiets")
                        .resizable()
                        .frame(width: s(40), height: s(26))
                    VStack(alignment: .leading, spacing: s(-4)) {
                        Text("Den Haag")
                            .font(AppFont.theSans(size: s(13), weight: .bold))
                        Text("Fietst!")
                            .font(AppFont.theSans(size: s(22), weight: .plain))
                    }
                    .foregroundColor(.white)
                }
            }
            .padding(.vertical, s(16))
            .frame(maxWidth: .infinity)
            .background(FietspasKleur.kop)

            // Code: QR (placeholder) met de pascode eronder
            VStack(spacing: s(8)) {
                Image("fp-qr")
                    .resizable()
                    .frame(width: s(176), height: s(176))
                Text(pas.code)
                    .font(AppFont.theSans(size: s(20), weight: .plain))
                    .tracking(s(1.2))
                    .foregroundColor(.black)
            }
            .padding(.top, s(20))
            .padding(.bottom, s(16))
            .frame(maxWidth: .infinity)
            .background(Color.white)

            // Voertuig: kleur en icoon per type
            HStack(spacing: s(10)) {
                Image(pas.type.icoon)
                    .resizable()
                    .frame(width: s(pas.type.icoonBreedte), height: s(36))
                Text(lang.t(pas.type.naamKey))
                    .font(AppFont.theSans(size: s(15), weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .padding(.vertical, s(12))
            .frame(maxWidth: .infinity)
            .background(pas.type.kleur)
        }
        .frame(width: s(260))
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: s(20)))
        .shadow(color: .black.opacity(0.14), radius: s(9), x: 0, y: s(6))
    }
}

/// Klein label met icoon en code in de kleur van het voertuig, zoals het
/// kentekenplaatje bij Parkeren (Figma "fietspas-label", node 3457:2229).
struct FietspasLabel: View {
    let pas: Fietspas

    var body: some View {
        HStack(spacing: 5) {
            Image(pas.type.icoon)
                .resizable()
                .scaledToFit()
                .frame(height: 12)
            Text(pas.code)
                .font(AppFont.theSans(size: 13, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.leading, 7)
        .padding(.trailing, 8)
        .padding(.vertical, 4)
        .background(pas.type.kleur)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

/// Ronde knop op het grijze vlak (sluiten of terug), 44 × 44.
struct FietspasRondeKnop: View {
    let icoon: String
    let grootte: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(icoon)
                .resizable()
                .frame(width: grootte, height: grootte)
                .frame(width: 44, height: 44)
                .background(FietspasKleur.vlak)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

/// Witte rij met titel, onderregel en pijltje (Figma "rij").
struct FietspasRij: View {
    var ster: Bool? = nil
    let titel: String
    let sub: String
    var icoonRechts = "fp-chevron"

    var body: some View {
        HStack(spacing: 12) {
            if let ster {
                Image(ster ? "fp-ster-aan" : "fp-ster-uit")
                    .resizable()
                    .frame(width: 24, height: 24)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(titel)
                    .font(AppFont.theSans(size: 16, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                Text(sub)
                    .font(AppFont.theSans(size: 14, weight: .plain))
                    .foregroundColor(FietspasKleur.tekstZacht)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(icoonRechts)
                .resizable()
                .frame(width: 20, height: 20)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
    }
}

/// Gevulde groene hoofdknop in de fietspas-schermen.
struct FietspasHoofdknop: View {
    let titel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(titel)
                .font(AppFont.theSans(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppColors.groen3)
                .clipShape(RoundedRectangle(cornerRadius: 3))
        }
        .buttonStyle(.plain)
    }
}

/// Omlijnde knop (Figma "button" onder de lijst: rand #D2D2D2, radius 3).
struct FietspasOmlijndeKnop: View {
    let titel: String
    var kleur: Color = AppColors.groen3
    /// Optioneel SF Symbol vóór de tekst, bv. "plus".
    var icoon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icoon {
                    Image(systemName: icoon)
                        .font(.system(size: 16, weight: .bold))
                }
                Text(titel)
                    .font(AppFont.theSans(size: 18, weight: .bold))
            }
                .foregroundColor(kleur)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(FietspasKleur.knopRand, lineWidth: 1)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
