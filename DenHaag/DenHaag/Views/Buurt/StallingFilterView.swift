import SwiftUI

/// Filters voor stallingen (Figma fietsen, flow 01 scherm 6 en 6b): fietstype,
/// openingstijden en voorzieningen. Werkt op een kopie; "Toon N stallingen"
/// past toe, het kruisje sluit zonder iets te veranderen.
struct StallingFilterView: View {
    @EnvironmentObject var lang: LanguageManager
    @Environment(\.dismiss) private var dismiss

    let stallingen: [KaartPlek]
    /// Fietstypen uit je eigen fietspassen ("Op basis van je fietspassen").
    let uitPassen: Set<FietspasType>
    let begin: StallingFilter
    var onToepassen: (StallingFilter) -> Void

    @State private var filter = StallingFilter()

    private var aantal: Int { stallingen.filter { filter.past($0) }.count }

    /// Alleen voorzieningen die het verschil maken: bij minstens één stalling,
    /// maar niet bij allemaal (bewaakt zijn ze bijvoorbeeld allemaal).
    private var voorzieningOpties: [String] {
        let lijsten = stallingen.map { Set(StallingFilter.voorzieningen($0)) }
        let alle = lijsten.reduce(Set<String>()) { $0.union($1) }
        return alle.filter { v in !lijsten.allSatisfy { $0.contains(v) } }.sorted()
    }

    private var heeftDagEnNacht: Bool { stallingen.contains { StallingFilter.isDagEnNacht($0) } }

    var body: some View {
        VStack(spacing: 0) {
            kop
            Divider()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    if !filter.isLeeg {
                        actief
                        scheiding
                    }
                    jeFiets
                    scheiding
                    openingstijden
                    if !voorzieningOpties.isEmpty {
                        scheiding
                        voorzieningen
                    }
                }
                .padding(.horizontal, AppDesign.horizontalPadding)
                .padding(.top, 20)
                .padding(.bottom, 24)
            }
            onderbalk
        }
        .background(Color.white)
        .onAppear { filter = begin }
        .animation(.easeInOut(duration: 0.2), value: filter)
    }

    // MARK: Kop

    private var kop: some View {
        ZStack {
            Text(lang.t("sf_filters"))
                .font(AppFont.theSans(size: 18, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(Text(lang.t("terug")))
                Spacer()
            }
            .padding(.leading, 8)
        }
        .frame(height: 56)
    }

    private var scheiding: some View {
        Rectangle().fill(AppColors.tegelBorder).frame(height: 1).padding(.vertical, 20)
    }

    private func sectieTitel(_ t: String) -> some View {
        Text(t)
            .font(AppFont.theSans(size: 18, weight: .bold))
            .foregroundColor(AppColors.textPrimary)
    }

    // MARK: Actieve filters (6b)

    private var tags: [(label: String, wis: () -> Void)] {
        var lijst: [(String, () -> Void)] = []
        for t in StallingFilter.typen where filter.fietstypen.contains(t) {
            lijst.append((lang.t(t.naamKey), { filter.fietstypen.remove(t) }))
        }
        if filter.open != .alle {
            lijst.append((lang.t(filter.open == .nuOpen ? "sf_nu_open" : "sf_24"), { filter.open = .alle }))
        }
        for v in filter.voorzieningen.sorted() {
            lijst.append((v, { filter.voorzieningen.remove(v) }))
        }
        return lijst
    }

    private var actief: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectieTitel(String(format: lang.t("sf_actief"), filter.aantalActief))
            TagStroom(spacing: 8) {
                ForEach(Array(tags.enumerated()), id: \.offset) { _, tag in
                    Button(action: tag.wis) {
                        HStack(spacing: 6) {
                            Text(tag.label)
                                .font(AppFont.theSans(size: 16, weight: .semiBold))
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(AppColors.groen4)
                        .padding(.horizontal, 14)
                        .frame(height: 36)
                        .background(AppColors.groen1)
                        .clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(AppColors.groen4, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Je fiets

    private var jeFiets: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectieTitel(lang.t("sf_je_fiets"))
            Text(lang.t("sf_je_fiets_uitleg"))
                .font(AppFont.theSans(size: 14, weight: .plain))
                .foregroundColor(Color(hex: "666666"))
                .padding(.top, 6)
                .padding(.bottom, 8)
            ForEach(StallingFilter.typen) { t in
                rij(aan: filter.fietstypen.contains(t), rond: false) {
                    if filter.fietstypen.contains(t) { filter.fietstypen.remove(t) } else { filter.fietstypen.insert(t) }
                } label: {
                    HStack(spacing: 14) {
                        // De pas-iconen zijn wit (voor op de pas); hier in de paskleur.
                        Image(t.icoon).renderingMode(.template).resizable().scaledToFit()
                            .foregroundColor(t.kleur)
                            .frame(width: 40, height: 26)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(lang.t(t.naamKey))
                                .font(AppFont.theSans(size: 16, weight: .plain))
                                .foregroundColor(AppColors.textPrimary)
                            if uitPassen.contains(t) {
                                Text(lang.t("sf_op_basis_passen"))
                                    .font(AppFont.theSans(size: 13, weight: .plain))
                                    .foregroundColor(AppColors.groen3)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: Openingstijden

    private var openingstijden: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectieTitel(lang.t("stalling_openingstijden")).padding(.bottom, 4)
            ForEach(StallingFilter.Open.allCases.filter { $0 != .dagEnNacht || heeftDagEnNacht }, id: \.self) { o in
                rij(aan: filter.open == o, rond: true) { filter.open = o } label: {
                    Text(lang.t(o == .alle ? "sf_alle" : o == .nuOpen ? "sf_nu_open" : "sf_24"))
                        .font(AppFont.theSans(size: 16, weight: .plain))
                        .foregroundColor(AppColors.textPrimary)
                }
            }
        }
    }

    // MARK: Voorzieningen

    private var voorzieningen: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectieTitel(lang.t("zw_facilities")).padding(.bottom, 4)
            ForEach(voorzieningOpties, id: \.self) { v in
                rij(aan: filter.voorzieningen.contains(v), rond: false) {
                    if filter.voorzieningen.contains(v) { filter.voorzieningen.remove(v) } else { filter.voorzieningen.insert(v) }
                } label: {
                    Text(v)
                        .font(AppFont.theSans(size: 16, weight: .plain))
                        .foregroundColor(AppColors.textPrimary)
                }
            }
        }
    }

    /// Figma: rij van 56 hoog, label links, vinkje of rondje (24) rechts.
    private func rij<L: View>(aan: Bool, rond: Bool, actie: @escaping () -> Void,
                              @ViewBuilder label: () -> L) -> some View {
        Button(action: actie) {
            HStack {
                label()
                Spacer(minLength: 12)
                if rond {
                    ZStack {
                        Circle().strokeBorder(aan ? AppColors.groen3 : Color(hex: "8C8C8C"), lineWidth: aan ? 2 : 1.5)
                        if aan { Circle().fill(AppColors.groen3).frame(width: 12, height: 12) }
                    }
                    .frame(width: 24, height: 24)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(aan ? AppColors.groen3 : Color.white)
                        RoundedRectangle(cornerRadius: 5)
                            .strokeBorder(aan ? Color.clear : Color(hex: "8C8C8C"), lineWidth: 1.5)
                        if aan {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: 24, height: 24)
                }
            }
            .frame(minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Onderbalk

    private var onderbalk: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                Button { filter = StallingFilter() } label: {
                    Text(lang.t("sf_wis_alles"))
                        .font(AppFont.theSans(size: 16, weight: .bold))
                        .underline()
                        .foregroundColor(filter.isLeeg ? AppColors.grijs4 : AppColors.textPrimary)
                }
                .buttonStyle(.plain)
                .disabled(filter.isLeeg)
                Spacer()
                Button {
                    onToepassen(filter)
                    dismiss()
                } label: {
                    Text(aantal == 0 ? lang.t("sf_geen") : aantal == 1 ? lang.t("sf_toon_1") : String(format: lang.t("sf_toon"), aantal))
                        .font(AppFont.theSans(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .frame(height: 48)
                        .background(aantal == 0 ? AppColors.grijs4 : AppColors.groen3)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
                .disabled(aantal == 0)
            }
            .padding(.horizontal, AppDesign.horizontalPadding)
            .padding(.top, 14)
            .padding(.bottom, 14)
        }
        .background(Color.white)
    }
}

/// Eenvoudige regelafbrekende rij voor tags.
struct TagStroom: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let breedte = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rijHoogte: CGFloat = 0, maxX: CGFloat = 0
        for v in subviews {
            let m = v.sizeThatFits(.unspecified)
            if x > 0, x + m.width > breedte { x = 0; y += rijHoogte + spacing; rijHoogte = 0 }
            x += m.width + spacing
            maxX = max(maxX, x - spacing)
            rijHoogte = max(rijHoogte, m.height)
        }
        return CGSize(width: min(maxX, breedte), height: y + rijHoogte)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rijHoogte: CGFloat = 0
        for v in subviews {
            let m = v.sizeThatFits(.unspecified)
            if x > bounds.minX, x + m.width > bounds.maxX { x = bounds.minX; y += rijHoogte + spacing; rijHoogte = 0 }
            v.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(m))
            x += m.width + spacing
            rijHoogte = max(rijHoogte, m.height)
        }
    }
}
