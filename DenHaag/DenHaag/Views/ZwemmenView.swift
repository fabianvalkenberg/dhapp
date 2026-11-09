import SwiftUI

// MARK: - Zwemmen Landing Page

struct ZwemmenView: View {
    @Binding var isPresented: Bool

    // Header animation states
    @State private var swimmerOffset: CGFloat = 100
    @State private var swimmerOpacity: Double = 0
    @State private var swimmerRotation: Double = 5
    @State private var splashScale: CGFloat = 0
    @State private var headerAppeared = false

    // Cloud animations
    @State private var cloud1X: CGFloat = 0
    @State private var cloud2X: CGFloat = 0
    @State private var cloud3X: CGFloat = 0
    @State private var cloud4X: CGFloat = 0

    // Active reservering
    @State private var hasReservering = true

    private var safeTop: CGFloat { AppDesign.safeAreaTop }


    var body: some View {
        ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // MARK: - Header (blue zone, illustration inside, curve as overlay on top)
                    ZStack {
                        Color(hex: "DAEBFA")

                        // Clouds
                        Group {
                            Image("wolk01")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100)
                                .offset(x: -80 + cloud1X, y: -40)

                            Image("wolk02")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 70)
                                .offset(x: 100 + cloud2X, y: -55)

                            Image("wolk01")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60)
                                .opacity(0.7)
                                .offset(x: 30 + cloud3X, y: -10)

                            Image("wolk02")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50)
                                .opacity(0.5)
                                .offset(x: -130 + cloud4X, y: 5)
                        }

                        VStack(spacing: 0) {
                            // Paginatitel scrollt mee; alleen de back-knop is sticky.
                            HStack {
                                Spacer().frame(width: 52)
                                Text("Zwemmen")
                                    .font(AppFont.theMix(size: 26, weight: .bold))
                                    .foregroundColor(AppColors.textPrimary)
                                Spacer()
                            }
                            .padding(.horizontal, AppDesign.horizontalPadding)
                            .padding(.top, safeTop + 14)

                            Spacer().frame(height: 40)

                            if hasReservering {
                                reserveringCard
                                    .padding(.horizontal, AppDesign.horizontalPadding)
                                    .transition(.asymmetric(
                                        insertion: .scale.combined(with: .opacity),
                                        removal: .move(edge: .top).combined(with: .opacity)
                                    ))
                            }

                            Spacer().frame(height: 20)

                            // Illustration — curve overlay covers bottom ~40px
                            ZStack(alignment: .bottom) {
                                Ellipse()
                                    .fill(Color(hex: "C8D8E8"))
                                    .frame(width: 280, height: 30)

                                ZStack {
                                    Image("zwemmer")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 160)
                                        .rotationEffect(.degrees(swimmerRotation))
                                        .offset(x: swimmerOffset)
                                        .opacity(swimmerOpacity)

                                    Circle()
                                        .fill(Color.white.opacity(0.3))
                                        .frame(width: 40, height: 40)
                                        .scaleEffect(splashScale)
                                        .offset(x: -20, y: 20)
                                        .opacity(splashScale > 0 ? 1 - Double(splashScale / 3) : 0)
                                }
                                .padding(.bottom, 10)
                            }
                            .frame(height: 120)
                            .padding(.bottom, 10)
                        }
                    }
                    .animation(.easeInOut(duration: 0.4), value: hasReservering)
                    .overlay(alignment: .bottom) {
                        HeaderCurveShape()
                            .fill(AppColors.background)
                            .frame(height: 75)
                    }

                    // MARK: - Content below header
                    VStack(alignment: .leading, spacing: 24) {
                        // MARK: - Jouw Zwempas
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Jouw zwempas")
                                .font(AppFont.theMix(size: 20, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)

                            if let zwemPas = Pas.allPassen.first(where: { $0.id == "zwempas" }) {
                                PasCardView(pas: zwemPas)
                            }
                        }

                        // MARK: - Jouw Zwembad
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Jouw zwembad")
                                    .font(AppFont.theMix(size: 20, weight: .bold))
                                    .foregroundColor(AppColors.textPrimary)
                                Spacer()
                                Button {
                                    // Aanpassen action
                                } label: {
                                    Text("aanpassen")
                                        .font(AppFont.theSans(size: 14, weight: .semiBold))
                                        .foregroundColor(AppColors.groen3)
                                }
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                Text("De Blinkerd")
                                    .font(AppFont.theMix(size: 18, weight: .bold))
                                    .foregroundColor(AppColors.textPrimary)

                                HStack(spacing: 12) {
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(AppColors.groen3)
                                            .frame(width: 8, height: 8)
                                        Text("NU GEOPEND")
                                            .font(AppFont.theSans(size: 11, weight: .bold))
                                            .foregroundColor(AppColors.groen3)
                                            .tracking(0.5)
                                    }

                                    HStack(spacing: 4) {
                                        Image(systemName: "clock")
                                            .font(.system(size: 12))
                                        Text("08:00 - 21:00")
                                            .font(AppFont.theSans(size: 14, weight: .plain))
                                    }
                                    .foregroundColor(AppColors.textSecondary)
                                }

                                VStack(spacing: 0) {
                                    menuItem(icon: "icon-coin-euro", label: "Kaartje kopen")
                                    divider
                                    menuItem(icon: "calendar", label: "Zwemles")
                                    divider
                                    menuItem(icon: "phone", label: "Contact")
                                    divider
                                    menuItem(icon: "calendar", label: "Openingstijden")
                                }
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(AppColors.grijs2, lineWidth: 1)
                                )
                            }
                        }

                        // MARK: - Alles over zwemmen
                        externalLinkButton(title: "Alles over zwemmen")

                        Spacer().frame(height: 100)
                    }
                    .padding(.horizontal, AppDesign.horizontalPadding)
                    .padding(.top, 24)
                }
            }

            // Floating nav bar: alleen de back-knop is sticky (titel scrollt mee).
            HStack(alignment: .center, spacing: 12) {
                BackCircleButton { isPresented = false }
                Spacer()
            }
            .padding(.horizontal, AppDesign.horizontalPadding)
            .padding(.top, safeTop + 8)
        }
        .background(AppColors.background)
        .ignoresSafeArea(edges: .top)
        .onAppear {
            startHeaderAnimation()
            startCloudAnimation()
        }
    }

    // MARK: - Header Animation

    private func startHeaderAnimation() {
        guard !headerAppeared else { return }
        headerAppeared = true

        withAnimation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.2)) {
            swimmerOffset = 0
            swimmerOpacity = 1
            swimmerRotation = 0
        }

        withAnimation(.easeOut(duration: 0.4).delay(0.6)) {
            splashScale = 2.5
        }
    }

    private func startCloudAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 18).repeatForever(autoreverses: true)) {
                cloud1X = 50
            }
            withAnimation(.easeInOut(duration: 22).repeatForever(autoreverses: true)) {
                cloud2X = -40
            }
            withAnimation(.easeInOut(duration: 15).repeatForever(autoreverses: true)) {
                cloud3X = -35
            }
            withAnimation(.easeInOut(duration: 20).repeatForever(autoreverses: true)) {
                cloud4X = 45
            }
        }
    }

    // MARK: - Reservering Card

    private var reserveringCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.groen3)
                Text("GERESERVEERD")
                    .font(AppFont.theSans(size: 11, weight: .bold))
                    .foregroundColor(AppColors.groen3)
                    .tracking(0.5)

                Rectangle()
                    .fill(AppColors.grijs2)
                    .frame(width: 1, height: 16)

                Image(systemName: "clock")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)
                Text("morgen 13:00")
                    .font(AppFont.theSans(size: 14, weight: .plain))
                    .foregroundColor(AppColors.textSecondary)
            }

            Text("Aquajoggen")
                .font(AppFont.theMix(size: 20, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            Button { } label: {
                HStack(spacing: 6) {
                    Text("ticket")
                        .font(AppFont.theSans(size: 16, weight: .bold))
                    Spacer()
                    Image("arrow-right")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(AppColors.groen3)
                .cornerRadius(AppDesign.cornerRadius)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(AppDesign.cornerRadius)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }

    // MARK: - Shared Components

    private var divider: some View {
        Rectangle()
            .fill(AppColors.grijs2)
            .frame(height: 1)
    }

    private func menuItem(icon: String, label: String) -> some View {
        Button { } label: {
            HStack(spacing: 12) {
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(AppColors.textSecondary)

                Text(label)
                    .font(AppFont.theSans(size: 18, weight: .plain))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)

                Spacer()

                Image("arrow-right")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
        }
        .buttonStyle(.plain)
    }

    private func externalLinkButton(title: String) -> some View {
        Button { } label: {
            HStack(spacing: 6) {
                Text(title)
                    .font(AppFont.theSans(size: 16, weight: .semiBold))
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(AppColors.groen3)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.white)
            .cornerRadius(AppDesign.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppDesign.cornerRadius)
                    .stroke(AppColors.groen3, lineWidth: 1)
            )
        }
    }
}
