import SwiftUI

/// Pasdetail en bewerken (Figma C4, node 3460:2789): miniatuur van de pas,
/// bijnaam, type, code, favoriet en "Pas kwijt?".
struct FietspasDetailView: View {
    @EnvironmentObject var lang: LanguageManager
    @ObservedObject var store: FietspasStore
    let pas: Fietspas
    var onTerug: () -> Void
    /// Toont de pas groot, om te laten scannen; met het frame van de miniatuur.
    var onToonPas: (CGRect) -> Void
    @State private var miniFrame: CGRect = .zero

    @State private var bewerkBijnaam = false
    @State private var nieuweBijnaam = ""
    @State private var toonKwijt = false

    private var safeTop: CGFloat { AppDesign.safeAreaTop }

    /// Zonder eigen bijnaam heet de pas naar het type: "Mijn fiets".
    private var bijnaam: String {
        pas.bijnaam.isEmpty ? FietspasGevondenView.standaardBijnaam(pas.type, lang) : pas.bijnaam
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            AppColors.warmGrijs.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    Color.clear.frame(height: safeTop + 58)

                    pasBlok
                    gegevens
                    favoriet

                    Button { toonKwijt = true } label: {
                        FietspasRij(titel: lang.t("fp_kwijt_title"), sub: lang.t("fp_kwijt_sub"))
                    }
                    .buttonStyle(.plain)

                    Spacer().frame(height: 130)
                }
                .padding(.horizontal, AppDesign.horizontalPadding)
            }

            // Kop: terug-knop en titel (de bijnaam).
            HStack(spacing: 12) {
                FietspasRondeKnop(icoon: "fp-terug", grootte: 22, action: onTerug)
                Text(bijnaam)
                    .font(AppFont.theMix(size: 24, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
            }
            .padding(.leading, AppDesign.horizontalPadding)
            .padding(.top, safeTop + 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.warmGrijs.frame(height: safeTop + 60).offset(y: -8), alignment: .top)
        }
        .ignoresSafeArea(edges: .top)
        .alert(lang.t("fp_bijnaam"), isPresented: $bewerkBijnaam) {
            TextField(lang.t("fp_bijnaam"), text: $nieuweBijnaam)
            Button(lang.t("cancel"), role: .cancel) { }
            Button(lang.t("fp_opslaan")) {
                var aangepast = pas
                aangepast.bijnaam = nieuweBijnaam.trimmingCharacters(in: .whitespacesAndNewlines)
                store.werkBij(aangepast)
            }
        }
        .alert(lang.t("fp_kwijt_title"), isPresented: $toonKwijt) {
            Button(lang.t("fp_ok"), role: .cancel) { }
        } message: {
            Text(lang.t("fp_kwijt_volgt"))
        }
    }

    private var pasBlok: some View {
        HStack(spacing: 16) {
            FietspasKaartView(pas: pas, schaal: 0.36)
                .background(GeometryReader { g in
                    Color.clear.onAppear { miniFrame = g.frame(in: .global) }
                })
                .onTapGesture { onToonPas(miniFrame) }
            VStack(alignment: .leading, spacing: 6) {
                FietspasLabel(pas: pas)
                Text("\(lang.t(pas.type.naamKey)) · \(lang.t(pas.type.kleurBijvoeglijkKey)) \(lang.t("fp_pas"))")
                    .font(AppFont.theSans(size: 16, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                Text(lang.t("fp_tik_scannen"))
                    .font(AppFont.theSans(size: 14, weight: .plain))
                    .foregroundColor(FietspasKleur.tekstZacht)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.leading, 12)
        .padding(.trailing, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var gegevens: some View {
        VStack(spacing: 0) {
            Button {
                nieuweBijnaam = bijnaam
                bewerkBijnaam = true
            } label: {
                gegevenRij(lang.t("fp_bijnaam"), bijnaam, chevron: true)
            }
            .buttonStyle(.plain)
            FietspasKleur.vlak.frame(height: 1)
            gegevenRij(lang.t("fp_type_pas"), "\(lang.t(pas.type.naamKey)) (\(lang.t(pas.type.kleurKey)))")
            FietspasKleur.vlak.frame(height: 1)
            gegevenRij(lang.t("fp_code"), pas.code)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func gegevenRij(_ label: String, _ waarde: String, chevron: Bool = false) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(AppFont.theSans(size: 16, weight: .plain))
                .foregroundColor(FietspasKleur.tekstZacht)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(waarde)
                .font(AppFont.theSans(size: 16, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(1)
            if chevron {
                Image("fp-chevron")
                    .resizable()
                    .frame(width: 20, height: 20)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    private var favoriet: some View {
        HStack(spacing: 12) {
            Image(pas.favoriet ? "fp-ster-aan" : "fp-ster-uit")
                .resizable()
                .frame(width: 24, height: 24)
            Text(lang.t("fp_favoriet"))
                .font(AppFont.theSans(size: 16, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            // De hele rij schakelt; de schakelaar laat alleen de stand zien.
            Toggle("", isOn: .constant(pas.favoriet))
                .labelsHidden()
                .tint(AppColors.groen3)
                .allowsHitTesting(false)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                store.zetFavoriet(pas.id, !pas.favoriet)
            }
        }
    }
}
