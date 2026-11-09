import SwiftUI

// MARK: - Pas Model

struct Pas: Identifiable {
    let id: String
    let name: String
    let imageName: String          // card thumbnail image
    let backgroundColor: Color
    let barcodeNumber: String
    let illustrationName: String?  // large illustration for detail view

    /// Snelle toegang vanuit de home-tegel "Ooievaarspas tonen".
    static var ooievaarspas: Pas { allPassen.first { $0.id == "ooievaarspas" }! }

    static let allPassen: [Pas] = [
        Pas(
            id: "ooievaarspas",
            name: "Ooievaarspas",
            imageName: "ooievaarspas",
            backgroundColor: AppColors.geel3,
            barcodeNumber: "6 038432 019482",
            illustrationName: "illu-ooievaarspas"
        ),
        Pas(
            id: "zwempas",
            name: "Zwempas",
            imageName: "zwempas",
            backgroundColor: Color(hex: "2B6CB0"),
            barcodeNumber: "6 038432 027891",
            illustrationName: "illu-zwempas"
        ),
        Pas(
            id: "afvalpas",
            name: "Afvalpas",
            imageName: "afvalpas",
            backgroundColor: Color(hex: "248641"),
            barcodeNumber: "6 038432 034567",
            illustrationName: "illu-afvalpas"
        ),
    ]
}

// MARK: - Passen Section (Horizontal Scroll on Home)

struct PassenSection: View {
    let passen: [Pas]
    @State private var selectedPas: Pas? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Je passen")
                    .font(AppFont.theMix(size: 20, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)

                Spacer()
            }
            .padding(.horizontal, AppDesign.horizontalPadding)

            // Horizontal scrolling passes
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(passen) { pas in
                        Button {
                            selectedPas = pas
                        } label: {
                            Image(pas.imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 180)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppDesign.horizontalPadding)
            }
        }
        .fullScreenCover(item: $selectedPas) { pas in
            PasDetailView(pas: pas)
        }
    }
}

// MARK: - Pas Detail View (Full Screen with Barcode)

struct PasDetailView: View {
    let pas: Pas
    @Environment(\.dismiss) var dismiss
    @State private var brightness: CGFloat = UIScreen.main.brightness
    @State private var appearAnimation = false

    private var safeTop: CGFloat { AppDesign.safeAreaTop }

    var body: some View {
        ZStack {
            // Background
            pas.backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button {
                        // Restore brightness
                        UIScreen.main.brightness = brightness
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.8))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, AppDesign.horizontalPadding)
                .padding(.top, safeTop + 8)

                Spacer()

                // Pas title
                Text(pas.name)
                    .font(AppFont.theMix(size: 32, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .opacity(appearAnimation ? 1 : 0)
                    .offset(y: appearAnimation ? 0 : 20)

                Spacer().frame(height: 24)

                // Het pasje groot in beeld
                Image(pas.imageName)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(14)
                    .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 6)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 32)
                    .opacity(appearAnimation ? 1 : 0)
                    .scaleEffect(appearAnimation ? 1 : 0.92)

                Spacer().frame(height: 28)

                // Barcode area
                VStack(spacing: 20) {
                    // Barcode image (simulated with stripes)
                    BarcodeView(number: pas.barcodeNumber)
                        .frame(height: 120)
                        .padding(.horizontal, 16)

                    // Barcode number
                    Text(pas.barcodeNumber)
                        .font(.system(size: 18, weight: .medium, design: .monospaced))
                        .foregroundColor(AppColors.textPrimary)
                        .tracking(3)
                }
                .padding(.vertical, 28)
                .padding(.horizontal, 20)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                .padding(.horizontal, 20)
                .opacity(appearAnimation ? 1 : 0)
                .scaleEffect(appearAnimation ? 1 : 0.9)

                Spacer().frame(height: 24)

                // Hint
                Text("Gebruik deze pas bij de scanner")
                    .font(AppFont.theSans(size: 14, weight: .plain))
                    .foregroundColor(AppColors.textPrimary.opacity(0.6))
                    .opacity(appearAnimation ? 1 : 0)

                Spacer()

                Spacer().frame(height: 20)
            }
        }
        .onAppear {
            // Increase screen brightness for scanning
            brightness = UIScreen.main.brightness
            UIScreen.main.brightness = 1.0

            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appearAnimation = true
            }
        }
        .onDisappear {
            UIScreen.main.brightness = brightness
        }
    }
}

// MARK: - Barcode View (Simulated)

struct BarcodeView: View {
    let number: String

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                ForEach(0..<60, id: \.self) { i in
                    let isThick = barPattern(index: i)
                    Rectangle()
                        .fill(isThick ? Color.black : Color.clear)
                        .frame(width: isThick ? (i % 7 == 0 ? 3 : 1.5) : 1)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func barPattern(index: Int) -> Bool {
        // Generate a pseudo-random but deterministic pattern based on the number
        let seed = number.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return (index * seed + index * 7) % 3 != 0
    }
}

// MARK: - Single Pas Card (for use in AfvalView / ZwemmenView)

struct PasCardView: View {
    let pas: Pas
    @State private var showDetail = false

    var body: some View {
        Button {
            showDetail = true
        } label: {
            Image(pas.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 200)
                .cornerRadius(10)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .fullScreenCover(isPresented: $showDetail) {
            PasDetailView(pas: pas)
        }
    }
}
