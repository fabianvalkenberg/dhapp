import SwiftUI

/// Bouwstenen van de meldflow, 1-op-1 uit Figma "prototype MOR '26"
/// (Progress header, App button, Answers, button-graag/nee, inputfield, summary).
enum MORStijl {
    static let donkerRood = Color(hex: "A30500")
    static let knopTekstUit = Color(hex: "EBD47D")
    static let label = Color(hex: "272727")
    static let titel = AppFont.theMix(size: 22, weight: .extraBold)
    static let body = AppFont.theSans(size: 18, weight: .plain)
    static let bodyBold = AppFont.theSans(size: 18, weight: .bold)
}

/// Schermtitel: TheMixB ExtraBold 22, gecentreerd.
struct MORTitel: View {
    let tekst: String
    var body: some View {
        Text(tekst)
            .font(MORStijl.titel)
            .foregroundColor(AppColors.darkGrey)
            .multilineTextAlignment(.center)
            .lineSpacing(2.6)
            .padding(.vertical, 1.3)
            .frame(maxWidth: .infinity)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// Progress header: terug, voortgangsbalk (geel op warm grijs), hulp, sluiten. 86 hoog.
struct MORHeader: View {
    let voortgang: CGFloat
    var onTerug: () -> Void
    var onHulp: () -> Void
    var onSluit: () -> Void

    var body: some View {
        HStack(spacing: 32) {
            Button(action: onTerug) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(AppColors.darkGrey)
                    .frame(width: 24, height: 24)
            }
            ZStack(alignment: .leading) {
                Capsule().fill(AppColors.warmGrijs).frame(height: 4)
                GeometryReader { g in
                    Capsule().fill(AppColors.geel3)
                        .frame(width: g.size.width * voortgang, height: 4)
                        .animation(.easeInOut(duration: 0.35), value: voortgang)
                }
                .frame(height: 4)
            }
            .padding(.vertical, 10)
            HStack(spacing: 12) {
                Button(action: onHulp) {
                    Image("mor-help").resizable().frame(width: 24, height: 24)
                }
                Button(action: onSluit) {
                    Image(systemName: "xmark")
                        .font(.system(size: 19, weight: .regular))
                        .foregroundColor(AppColors.darkGrey)
                        .frame(width: 24, height: 24)
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .frame(height: 86)
        .background(Color.white)
    }
}

/// App button: 69 hoog, radius 3. Geel (actief), lichtgeel (uit) of groen.
struct MORKnop: View {
    enum Soort { case geel, groen }
    let titel: String
    var soort: Soort = .geel
    var actief = true
    var icoon: String? = "arrow.right"
    var eigenIcoon: String? = nil
    let action: () -> Void

    private var achtergrond: Color {
        switch soort {
        case .groen: return AppColors.groen3
        case .geel:  return actief ? AppColors.geel3 : AppColors.geel1
        }
    }
    private var tekstkleur: Color {
        switch soort {
        case .groen: return AppColors.warmGrijs
        case .geel:  return actief ? AppColors.darkGrey : MORStijl.knopTekstUit
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(titel)
                    .font(MORStijl.bodyBold)
                if let eigenIcoon {
                    Image(eigenIcoon)
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 24, height: 24)
                } else if let icoon {
                    Image(systemName: icoon)
                        .font(.system(size: 18, weight: .medium))
                        .frame(width: 24, height: 24)
                }
            }
            .foregroundColor(tekstkleur)
            .frame(maxWidth: .infinity)
            .frame(height: 69)
            .background(achtergrond)
            .clipShape(RoundedRectangle(cornerRadius: 3))
        }
        .buttonStyle(.plain)
        .disabled(!actief)
        .animation(.easeInOut(duration: 0.2), value: actief)
    }
}

/// Antwoord in een lijst (Figma "Answers", type List): warm grijs, gekozen groen.
struct MORAntwoord: View {
    let tekst: String
    let gekozen: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(tekst)
                .font(gekozen ? MORStijl.bodyBold : MORStijl.body)
                .foregroundColor(gekozen ? .white : AppColors.darkGrey)
                .multilineTextAlignment(.leading)
                .lineSpacing(1.5)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, minHeight: 24, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                .background(gekozen ? AppColors.groen3 : AppColors.warmGrijs)
                .clipShape(RoundedRectangle(cornerRadius: 3))
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(gekozen ? AppColors.groen4 : AppColors.grijs2, lineWidth: 1)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: gekozen)
    }
}

/// Onderwerp-tegel (Figma "Answers", type Tile): emoji 30 en tekst 18, 143 hoog.
struct MORTegel: View {
    let emoji: String
    let tekst: String
    let gekozen: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(emoji).font(.system(size: 30))
                Text(tekst)
                    .font(MORStijl.body)
                    .foregroundColor(gekozen ? .white : AppColors.darkGrey)
                    .multilineTextAlignment(.center)
                    .lineSpacing(0)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(height: 48)
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .frame(height: 143)
            .background(gekozen ? AppColors.groen3 : AppColors.warmGrijs)
            .clipShape(RoundedRectangle(cornerRadius: 3))
        }
        .buttonStyle(PressableScaleStyle())
        .animation(.easeInOut(duration: 0.15), value: gekozen)
    }
}

/// Graag / Nee (Figma button-graag, button-nee): wit met grijze rand, of
/// gevuld groen (graag) of rood (nee) als gekozen.
struct MORJaNee: View {
    @EnvironmentObject var lang: LanguageManager
    @Binding var keuze: Bool?

    var body: some View {
        HStack(spacing: 8) {
            knop(lang.t("mor_graag"), icoon: "checkmark", waarde: true, kleur: AppColors.groen3, rand: AppColors.groen4)
            knop(lang.t("mor_nee"), icoon: "xmark", waarde: false, kleur: AppColors.rood, rand: MORStijl.donkerRood)
        }
    }

    private func knop(_ titel: String, icoon: String, waarde: Bool, kleur: Color, rand: Color) -> some View {
        let aan = keuze == waarde
        return Button { withAnimation(.easeInOut(duration: 0.15)) { keuze = waarde } } label: {
            HStack(spacing: 5) {
                Text(titel).font(MORStijl.bodyBold)
                Image(systemName: icoon).font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(aan ? .white : AppColors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(aan ? kleur : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(aan ? rand : AppColors.textSecondary, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

/// Invoerveld met label (Figma "inputfield"): 59 hoog, rand #D2D2D2, radius 3.
struct MORInvoer: View {
    let label: String
    let placeholder: String
    @Binding var tekst: String
    var toetsenbord: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(MORStijl.body)
                .foregroundColor(MORStijl.label)
            TextField("", text: $tekst, prompt: Text(placeholder).foregroundColor(AppColors.textSecondary))
                .font(MORStijl.body)
                .foregroundColor(AppColors.darkGrey)
                .keyboardType(toetsenbord)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.horizontal, 12)
                .frame(height: 59)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 3))
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(AppColors.grijs2, lineWidth: 1))
        }
    }
}

/// Samenvattingskaart (Figma "summary"): warm grijs, bewerkknop, gekartelde onderrand.
struct MORSamenvatting: View {
    let regels: [(String, String)]
    var onBewerk: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 6) {
                VStack(alignment: .leading, spacing: 17) {
                    ForEach(Array(regels.enumerated()), id: \.offset) { _, regel in
                        VStack(alignment: .leading, spacing: 0) {
                            Text(regel.0).font(MORStijl.bodyBold)
                            Text(regel.1).font(MORStijl.body)
                        }
                        .foregroundColor(AppColors.darkGrey)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Button(action: onBewerk) {
                    ZStack {
                        Image("mor-edit-bg").resizable().frame(width: 30, height: 30)
                        Image("mor-edit").resizable().frame(width: 20, height: 20)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(24)
            .background(AppColors.warmGrijs)
            Image("mor-kartel")
                .resizable()
                .frame(height: 6)
        }
    }
}

/// Draaiend groen rondje met "Laden" (Figma "Step 1 - Loading curtain").
struct MORLaden: View {
    @EnvironmentObject var lang: LanguageManager
    @State private var draai = false

    var body: some View {
        VStack(spacing: 11) {
            ZStack {
                Circle().stroke(AppColors.grijs2, lineWidth: 5)
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(AppColors.groen3, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(draai ? 360 : 0))
            }
            .frame(width: 50, height: 50)
            Text(lang.t("mor_laden"))
                .font(AppFont.theSans(size: 16, weight: .plain))
                .foregroundColor(AppColors.darkGrey)
        }
        .onAppear {
            withAnimation(.linear(duration: 0.9).repeatForever(autoreverses: false)) { draai = true }
        }
    }
}


/// Omlijnde knop onder de kaart (Figma "locatie buttons"): rand 1 #2D2D2D,
/// padding 16/20, tekst Bold 18 met regelhoogte 20, icoon 20.
struct MORLocatieKnop: View {
    let titel: String
    let icoon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Text(titel).font(MORStijl.bodyBold).frame(height: 20)
                Image(icoon).renderingMode(.template).resizable().frame(width: 20, height: 20)
            }
            .foregroundColor(AppColors.darkGrey)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(AppColors.darkGrey, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Wolkje bij de gekozen container (Figma "Frame 3405"): wit, padding 16,
/// radius 3, tekst Regular 18 zwart, gecentreerd, 257 breed.
struct MORWolkje: View {
    let tekst: String
    var body: some View {
        Text(tekst)
            .font(MORStijl.body)
            .foregroundColor(.black)
            .multilineTextAlignment(.center)
            .lineSpacing(1.5)
            .fixedSize(horizontal: false, vertical: true)
            .padding(16)
            .frame(width: 257)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
    }
}
