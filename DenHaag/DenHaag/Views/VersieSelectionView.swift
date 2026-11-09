import SwiftUI

/// Kiezen welke versie van de app je bekijkt. Per versie staat in bullets wat
/// erbij komt; versie 2 en 3 bouwen voort op de vorige.
struct VersieSelectionView: View {
    @EnvironmentObject var lang: LanguageManager
    @EnvironmentObject var versie: VersieManager
    @Binding var isPresented: Bool

    private var safeTop: CGFloat { AppDesign.safeAreaTop }

    var body: some View {
        ZStack(alignment: .top) {
            AppColors.background
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer().frame(height: safeTop + 56)

                    Text(lang.t("versie_title"))
                        .font(AppFont.theMix(size: 26, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.bottom, 12)

                    ForEach(AppVersie.allCases) { optie in
                        Button {
                            versie.current = optie
                        } label: {
                            versieRij(optie)
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }


                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, AppDesign.horizontalPadding)
            }
            .bovenVervaging()

            // Witte balk achter de terug-knop, zodat de lijst er niet doorheen scrolt.
            AppColors.background
                .frame(height: safeTop + 52)
                .ignoresSafeArea(edges: .top)

            HStack {
                BackCircleButton {
                    withAnimation(.easeInOut(duration: 0.25)) { isPresented = false }
                }
                Spacer()
            }
            .padding(.horizontal, AppDesign.horizontalPadding)
            .padding(.top, safeTop + 8)
        }
        // De notch-hoogte zit al in safeTop; niet dubbel tellen.
        .ignoresSafeArea(edges: .top)
    }

    private func versieRij(_ optie: AppVersie) -> some View {
        let actief = versie.current == optie
        return HStack(alignment: .top, spacing: 14) {
            keuzeRondje(actief)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 8) {
                Text(lang.t(optie.titleKey))
                    .font(AppFont.theSans(size: 18, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)

                if optie == .test {
                    Text(lang.t("versie_test_desc"))
                        .font(AppFont.theSans(size: 16, weight: .plain))
                        .foregroundColor(AppColors.textSecondary)
                } else if let vorige = optie.vorige {
                    Text(String(format: lang.t("versie_plus"), vorige.nummer))
                        .font(AppFont.theSans(size: 16, weight: .plain))
                        .foregroundColor(AppColors.textSecondary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(optie.nieuweOnderdelen.flatMap(\.labelKeys), id: \.self) { key in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("•")
                            Text(lang.t(key))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .font(AppFont.theSans(size: 16, weight: .plain))
                        .foregroundColor(AppColors.textPrimary)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 18)
        .contentShape(Rectangle())
    }

    /// Vaste maat, zodat de tekst niet verspringt tussen vinkje en leeg rondje.
    private func keuzeRondje(_ actief: Bool) -> some View {
        rondje(actief).frame(width: 24, height: 24)
    }

    @ViewBuilder
    private func rondje(_ actief: Bool) -> some View {
        if actief {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22))
                .foregroundColor(AppColors.groen3)
        } else {
            Circle()
                .stroke(AppColors.grijs2, lineWidth: 1.5)
                .frame(width: 22, height: 22)
        }
    }
}
