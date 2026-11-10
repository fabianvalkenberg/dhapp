import SwiftUI

/// Pasdetail (Figma fietsen, flow 02 scherm 8 en 8b): de pas, naam wijzigen,
/// code, Wallet-status, pas blokkeren (volgt in HKW 05) en verwijderen.
/// Tik op de pas om hem groot te laten scannen.
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
    @State private var toonVerwijder = false

    private var safeTop: CGFloat { AppDesign.safeAreaTop }

    /// Zonder eigen bijnaam heet de pas naar het type: "Mijn fiets".
    private var bijnaam: String {
        pas.bijnaam.isEmpty ? pas.type.standaardBijnaam(lang) : pas.bijnaam
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                FpKop(titel: bijnaam, terug: true, onSluit: onTerug)
                    .padding(.top, safeTop)
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        FietspasKaartView(pas: pas, schaal: 0.62)
                            .background(GeometryReader { g in
                                Color.clear.onAppear { miniFrame = g.frame(in: .global) }
                            })
                            .onTapGesture { onToonPas(miniFrame) }
                            .padding(.bottom, 12)

                        Button {
                            nieuweBijnaam = bijnaam
                            bewerkBijnaam = true
                        } label: { rij(lang.t("fp2_naam"), bijnaam) }
                        .buttonStyle(.plain)

                        // De code kun je niet wijzigen: geen pijl.
                        rij(lang.t("fp_code"),
                            "\(pas.code) · \(lang.t(pas.type.kleurBijvoeglijkKey)) \(lang.t("fp_pas"))",
                            pijl: false)

                        Button {
                            store.zetInWallet(pas.code, !store.inWallet(pas.code))
                        } label: {
                            rij(lang.t("fp2_wallet"), lang.t(store.inWallet(pas.code) ? "fp2_wallet_ja" : "fp2_wallet_nee"))
                        }
                        .buttonStyle(.plain)

                        Button { toonKwijt = true } label: {
                            rij(lang.t("fp2_kwijt"), lang.t("fp2_kwijt_sub"))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, AppDesign.horizontalPadding)
                    .padding(.bottom, 24)
                }

                VStack(spacing: 0) {
                    Divider()
                    FietspasOmlijndeKnop(titel: lang.t("fp2_verwijder_knop")) { toonVerwijder = true }
                        .padding(.horizontal, AppDesign.horizontalPadding)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .alert(lang.t("fp2_naam"), isPresented: $bewerkBijnaam) {
            TextField(lang.t("fp2_naam"), text: $nieuweBijnaam)
            Button(lang.t("cancel"), role: .cancel) { }
            Button(lang.t("fp_opslaan")) {
                var aangepast = pas
                aangepast.bijnaam = nieuweBijnaam.trimmingCharacters(in: .whitespacesAndNewlines)
                store.werkBij(aangepast)
            }
        }
        .alert(lang.t("fp2_kwijt"), isPresented: $toonKwijt) {
            Button(lang.t("fp_ok"), role: .cancel) { }
        } message: {
            Text(lang.t("fp_kwijt_volgt"))
        }
        .sheet(isPresented: $toonVerwijder) {
            verwijderSheet
                .presentationDetents([.height(300)])
                .presentationCornerRadius(24)
        }
        .onAppear { AnalyticsService.screen("fietspas_detail") }
    }

    /// Figma: lichtgrijze rij met titel, onderregel en (meestal) een pijl.
    private func rij(_ titel: String, _ sub: String, pijl: Bool = true) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(titel)
                    .font(AppFont.theSans(size: 16, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                Text(sub)
                    .font(AppFont.theSans(size: 14, weight: .plain))
                    .foregroundColor(FietspasKleur.tekstZacht)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if pijl {
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(hex: "F4F3F0"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
    }

    /// 8b: bevestigen, omdat het niet in één tik terug te draaien is.
    private var verwijderSheet: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(lang.t("fp2_verwijder_kop"))
                .font(AppFont.theMix(size: 22, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            Text(lang.t("fp2_verwijder_tekst"))
                .font(AppFont.theSans(size: 17, weight: .plain))
                .foregroundColor(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)
            Spacer(minLength: 16)
            FietspasHoofdknop(titel: lang.t("fp2_ja_verwijderen")) {
                toonVerwijder = false
                AnalyticsService.track("fietspas_verwijderd", ["type": pas.type.rawValue])
                let id = pas.id
                onTerug()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { store.verwijder(id) }
            }
            Button { toonVerwijder = false } label: {
                Text(lang.t("fp2_nee_terug"))
                    .font(AppFont.theSans(size: 16, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(.horizontal, AppDesign.horizontalPadding)
        .padding(.top, 28)
        .padding(.bottom, 8)
    }
}
