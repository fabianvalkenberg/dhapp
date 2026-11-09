import SwiftUI

// MARK: - Afval Landing Page

struct AfvalView: View {
    @Binding var isPresented: Bool

    // Header animation states
    @State private var trashBagOffset: CGFloat = 80
    @State private var trashBagOpacity: Double = 0
    @State private var containerOffset: CGFloat = 60
    @State private var containerOpacity: Double = 0
    @State private var headerAppeared = false

    // Cloud animations
    @State private var cloud1X: CGFloat = 0
    @State private var cloud2X: CGFloat = 0
    @State private var cloud3X: CGFloat = 0
    @State private var cloud4X: CGFloat = 0

    // Active afspraak
    @State private var hasActiveAfspraak = false
    @State private var afspraakData: GrofvuilFormData? = nil
    @State private var showAfspraakDetail = false
    @State private var showGrofvuilSheet = false

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
                            // Paginatitel scrollt mee met de content; alleen de
                            // back-knop blijft sticky (naast de titel-startpositie).
                            HStack {
                                Spacer().frame(width: 52)
                                Text("Afval")
                                    .font(AppFont.theMix(size: 26, weight: .bold))
                                    .foregroundColor(AppColors.textPrimary)
                                Spacer()
                            }
                            .padding(.horizontal, AppDesign.horizontalPadding)
                            .padding(.top, safeTop + 14)

                            Spacer().frame(height: 40)

                            if hasActiveAfspraak {
                                afspraakCard
                                    .padding(.horizontal, AppDesign.horizontalPadding)
                                    .transition(.asymmetric(
                                        insertion: .scale.combined(with: .opacity),
                                        removal: .move(edge: .top).combined(with: .opacity)
                                    ))
                            }

                            Spacer().frame(height: 20)

                            // Illustration — curve overlay will cover bottom ~40px
                            ZStack(alignment: .bottom) {
                                Ellipse()
                                    .fill(Color(hex: "C8D8E8"))
                                    .frame(width: 300, height: 45)
                                    .offset(y: 10)

                                ZStack {
                                    Image("illu-trash")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 91)
                                        .offset(x: 25, y: containerOffset)
                                        .opacity(containerOpacity)

                                    Image("afvalbak")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 72)
                                        .offset(x: -20, y: trashBagOffset)
                                        .opacity(trashBagOpacity)
                                }
                                .offset(y: -15)
                                .padding(.bottom, 8)
                            }
                            .frame(height: 100)
                            .padding(.bottom, 30)
                        }
                    }
                    .animation(.easeInOut(duration: 0.4), value: hasActiveAfspraak)
                    // White curve rendered ON TOP of the blue ZStack — covers illustration bottom
                    .overlay(alignment: .bottom) {
                        HeaderCurveShape()
                            .fill(AppColors.background)
                            .frame(height: 75)
                    }

                    // MARK: - Content below header
                    VStack(alignment: .leading, spacing: 36) {
                        // MARK: - Snel Regelen
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Snel regelen")
                                .font(AppFont.theMix(size: 20, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)

                            VStack(spacing: 0) {
                                menuItem(icon: "calendar", label: "Afvalkalender")
                                divider
                                menuItemAction(icon: "truck", label: "Grofvuil laten ophalen") {
                                    showGrofvuilSheet = true
                                }
                                divider
                                menuItem(icon: "icon-coin-euro", label: "Transacties")
                            }
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(AppColors.grijs2, lineWidth: 1)
                            )
                        }

                        // MARK: - Jouw Afvalpas
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Jouw afvalpas")
                                .font(AppFont.theMix(size: 20, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)

                            if let afvalPas = Pas.allPassen.first(where: { $0.id == "afvalpas" }) {
                                PasCardView(pas: afvalPas)
                            }
                        }

                        // MARK: - Jouw Milieupark
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Jouw milieupark")
                                .font(AppFont.theMix(size: 20, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)

                            VStack(alignment: .leading, spacing: 12) {
                                Text("Avalex Zuid")
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
                                    menuItem(icon: "calendar", label: "Openingstijden")
                                    divider
                                    menuItem(icon: "phone", label: "Contact")
                                    divider
                                    menuItemExternal(icon: "location-pin", label: "Route")
                                }
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(AppColors.grijs2, lineWidth: 1)
                                )
                            }
                        }

                        // MARK: - Alles over afval
                        externalLinkButton(title: "Alles over afval")

                        Spacer().frame(height: 100)
                    }
                    .padding(.horizontal, AppDesign.horizontalPadding)
                    .padding(.top, 24)
                }
            }

            // Floating nav bar: back button + title
            navBar
        }
        .background(AppColors.background)
        .ignoresSafeArea(edges: .top)
        .onAppear {
            startHeaderAnimation()
            startCloudAnimation()
        }
        .sheet(isPresented: $showGrofvuilSheet) {
            GrofvuilOphalenSheet(onAfspraakCreated: { formData in
                afspraakData = formData
                hasActiveAfspraak = true
            })
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showAfspraakDetail) {
            GrofvuilAfspraakDetailView(formData: afspraakData ?? GrofvuilFormData())
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
    }

    // MARK: - Nav Bar (floating)

    private var navBar: some View {
        HStack(alignment: .center, spacing: 12) {
            BackCircleButton { isPresented = false }
            Spacer()
        }
        .padding(.horizontal, AppDesign.horizontalPadding)
        .padding(.top, safeTop + 8)
    }

    // MARK: - Header Animation

    private func startHeaderAnimation() {
        guard !headerAppeared else { return }
        headerAppeared = true

        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
            containerOffset = 0
            containerOpacity = 1
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.5).delay(0.3)) {
            trashBagOffset = 0
            trashBagOpacity = 1
        }
    }

    // MARK: - Cloud Animation

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

    // MARK: - Afspraak Card

    private var afspraakCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)

                if let data = afspraakData, let date = data.selectedDate {
                    let fmt: DateFormatter = {
                        let f = DateFormatter()
                        f.locale = Locale(identifier: "nl_NL")
                        f.dateFormat = "EEEE d MMMM"
                        return f
                    }()
                    Text("\(fmt.string(from: date)), \(data.selectedTimeSlot ?? "")")
                        .font(AppFont.theSans(size: 14, weight: .plain))
                        .foregroundColor(AppColors.textSecondary)
                } else {
                    Text("Binnenkort")
                        .font(AppFont.theSans(size: 14, weight: .plain))
                        .foregroundColor(AppColors.textSecondary)
                }

                Rectangle()
                    .fill(AppColors.grijs2)
                    .frame(width: 1, height: 16)

                Image(systemName: "mappin")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)
                Text(afspraakData?.address ?? "Den Haag")
                    .font(AppFont.theSans(size: 14, weight: .plain))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
            }

            Text("Grofvuil ophalen: \(afspraakData?.selectedCategory ?? "Grofvuil")")
                .font(AppFont.theMix(size: 20, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            Button {
                showAfspraakDetail = true
            } label: {
                HStack(spacing: 6) {
                    Text("Bekijk afspraak")
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

    private func menuItemAction(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
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

    private func menuItemExternal(icon: String, label: String) -> some View {
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

                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 16))
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

// Reuse HeaderCurveShape from ParkeerView (already defined there)
