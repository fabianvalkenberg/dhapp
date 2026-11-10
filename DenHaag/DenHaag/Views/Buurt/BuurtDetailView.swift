import SwiftUI

/// Detailpagina van een buurt-item. Schuift als full-screen overlay binnen
/// (afgehandeld in MainTabView), in de stijl van de overige detailschermen.
struct BuurtDetailView: View {
    let item: NeighbourhoodItem
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var lang: LanguageManager
    @State private var pollChoice: String? = nil

    private let pollOpties = ["Meer groen", "Ruimte om te spelen", "Betere fietsroutes"]

    private var safeTop: CGFloat { AppDesign.safeAreaTop }

    private var typeColor: Color {
        switch item.type {
        case .evenement: return AppColors.blauw3
        case .werkzaamheden: return AppColors.geel3
        case .denkMee: return AppColors.groen3
        case .stalling, .koffie: return AppColors.geel3
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            AppColors.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    photoHeader

                    VStack(alignment: .leading, spacing: 20) {
                        typeBadge

                        Text(item.title)
                            .font(AppFont.theMix(size: 30, weight: .bold))
                            .foregroundColor(.black)
                            .fixedSize(horizontal: false, vertical: true)

                        VStack(alignment: .leading, spacing: 20) {
                            VStack(alignment: .leading, spacing: 12) {
                                detailRow(systemIcon: "calendar", text: item.dateRange)
                                detailRow(systemIcon: "mappin.and.ellipse", text: item.location)
                            }

                            Divider().background(AppColors.grijs2)

                            Text(lang.t("buurt_detail_about"))
                                .font(AppFont.theSans(size: 18, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)

                            Text(item.detailText)
                                .font(AppFont.theSans(size: 18, weight: .plain))
                                .foregroundColor(AppColors.textSecondary)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)

                            if item.type == .werkzaamheden {
                                werkzaamhedenInfo
                            }

                            if item.type == .denkMee {
                                denkMeePoll
                                ctaButton
                                    .padding(.top, 4)
                            }

                            Spacer(minLength: 40)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppDesign.horizontalPadding)
                    .padding(.top, 24)
                }
                .frame(width: UIScreen.main.bounds.width)
            }
            .bovenVervaging()
            .ignoresSafeArea(edges: .top)

            BackCircleButton(stijl: .foto) { dismiss() }
                .terugknopPlek(binnenSafeArea: true)
        }
    }

    // MARK: - Onderdelen

    private var photoHeader: some View {
        ZStack(alignment: .bottomLeading) {
            Image(item.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: UIScreen.main.bounds.width, height: 300)
                .clipped()

            // Datum-badge alleen bij evenementen — bij werkzaamheden/denk-mee
            // is een losse dag niet relevant (dat is een periode of een vraag).
            if item.type == .evenement {
                dateBadge
                    .padding(20)
            }
        }
        .frame(width: UIScreen.main.bounds.width, height: 300)
        .clipped()
    }

    private var dateBadge: some View {
        VStack(spacing: -2) {
            Text(item.day)
                .font(AppFont.theMix(size: 24, weight: .bold))
                .foregroundColor(AppColors.darkGrey)
            Text(item.month)
                .font(AppFont.theSans(size: 18, weight: .bold))
                .foregroundColor(AppColors.groen4)
        }
        .frame(width: 64, height: 64)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 2)
    }

    private var typeBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: item.type.systemIcon)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(typeColor)
            Text(lang.t(item.type.labelKey))
                .font(AppFont.theSans(size: 14, weight: .semiBold))
                .foregroundColor(AppColors.darkGrey)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(AppColors.warmGrijs)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(AppColors.tegelBorder, lineWidth: 1))
    }

    private func detailRow(systemIcon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemIcon)
                .font(.system(size: 16))
                .foregroundColor(AppColors.textSecondary)
                .frame(width: 20)
            Text(text)
                .font(AppFont.theSans(size: 16, weight: .plain))
                .foregroundColor(AppColors.textSecondary)
        }
    }

    // Werkzaamheden: periode, werktijden en het alternatief tijdens het werk.
    private var werkzaamhedenInfo: some View {
        VStack(alignment: .leading, spacing: 14) {
            Divider().background(AppColors.grijs2)
            Text("Goed om te weten")
                .font(AppFont.theSans(size: 18, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            infoRij(icon: "calendar", titel: "Periode", waarde: item.dateRange)
            infoRij(icon: "clock", titel: "Werktijden", waarde: "Maandag t/m vrijdag, 07:00–16:00")
            if let alt = item.alternatief {
                infoRij(icon: "arrow.triangle.turn.up.right.diamond", titel: "Alternatief", waarde: alt)
            }
        }
    }

    private func infoRij(icon: String, titel: String, waarde: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppColors.groen3)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(titel)
                    .font(AppFont.theSans(size: 15, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                Text(waarde)
                    .font(AppFont.theSans(size: 16, weight: .plain))
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // Denk mee: een lichte vraag zodat je al even kunt meedenken.
    private var denkMeePoll: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider().background(AppColors.grijs2)
            Text("Denk alvast even mee")
                .font(AppFont.theSans(size: 18, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            Text("Wat vind jij het belangrijkst voor dit project?")
                .font(AppFont.theSans(size: 16, weight: .plain))
                .foregroundColor(AppColors.textSecondary)
            VStack(spacing: 8) {
                ForEach(pollOpties, id: \.self) { opt in
                    pollOptie(opt)
                }
            }
        }
    }

    private func pollOptie(_ opt: String) -> some View {
        let sel = pollChoice == opt
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { pollChoice = opt }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle().stroke(sel ? AppColors.groen3 : AppColors.grijs2, lineWidth: 1.5).frame(width: 22, height: 22)
                    if sel { Circle().fill(AppColors.groen3).frame(width: 12, height: 12) }
                }
                Text(opt)
                    .font(AppFont.theSans(size: 16, weight: sel ? .semiBold : .plain))
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }
            .padding(14)
            .background(sel ? AppColors.groen1 : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppDesign.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppDesign.cornerRadius)
                    .stroke(sel ? AppColors.groen3 : AppColors.grijs2, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var ctaButton: some View {
        Button {
            // Prototype: nog geen echte inspraak-flow.
        } label: {
            Text(lang.t("buurt_denkmee_cta"))
                .font(AppFont.theSans(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppColors.groen3)
                .clipShape(RoundedRectangle(cornerRadius: AppDesign.cornerRadius))
        }
        .buttonStyle(PressableScaleStyle())
    }
}
