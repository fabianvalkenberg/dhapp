import SwiftUI

// MARK: - Saved License Plate

struct SavedKenteken: Identifiable, Equatable {
    let id = UUID()
    var kenteken: String
    var name: String

    static let sampleData: [SavedKenteken] = [
        SavedKenteken(kenteken: "32-HYT-3", name: "Richard"),
        SavedKenteken(kenteken: "NB-456-XR", name: "Mama"),
        SavedKenteken(kenteken: "KJ-812-TN", name: "Buurman Jan"),
    ]
}

// MARK: - Active Parking Session

struct ParkeerSessie: Identifiable {
    let id = UUID()
    let kenteken: String
    let name: String
    let startTime: String
    let endTime: String
}

// MARK: - Concave curve shape for header-to-content transition
// Creates a white area with a concave (upward) curve at the top

struct HeaderCurveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Start at bottom-left
        path.move(to: CGPoint(x: 0, y: rect.height))
        // Line up to where the curve starts (left side)
        path.addLine(to: CGPoint(x: 0, y: 0))
        // Concave curve across the top (bows upward into the blue area)
        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: 0),
            control: CGPoint(x: rect.width / 2, y: rect.height * 0.8)
        )
        // Line down to bottom-right
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.closeSubpath()
        return path
    }
}

// MARK: - Parkeren Full Page (Scherm 1)

struct ParkeerPageView: View {
    @Binding var isPresented: Bool
    @State private var showAanmeldenSheet = false
    @State private var showKentekensSheet = false
    @State private var savedKentekens = SavedKenteken.sampleData
    @State private var activeSessions: [ParkeerSessie] = [
        ParkeerSessie(kenteken: "32-HYT-3", name: "Richard", startTime: "13:00", endTime: "23:00")
    ]

    // Cloud animations
    @State private var cloud1X: CGFloat = 0
    @State private var cloud2X: CGFloat = 0
    @State private var cloud3X: CGFloat = 0
    @State private var cloud4X: CGFloat = 0

    // Car drive-in animation
    @State private var carOffsetX: CGFloat = -300
    @State private var carRotation: Double = 0
    @State private var carAppeared = false

    // P-bord pop-in animation
    @State private var bordOffsetY: CGFloat = 80
    @State private var bordOpacity: Double = 0


    private var safeTop: CGFloat { AppDesign.safeAreaTop }

    private var contentWidth: CGFloat {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let screenWidth = windowScene?.windows.first?.frame.width ?? UIScreen.main.bounds.width
        return screenWidth - 2 * AppDesign.horizontalPadding
    }

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // MARK: - Header (blue zone, illustration inside, curve as overlay on top)
                    ZStack {
                        Color(hex: "DAEBFA")

                        // Wolken — in de ZStack vóór de content, zodat de kaart eroverheen ligt
                        VStack {
                            ZStack {
                                // Boven (hemelzone)
                                Image("wolk01")
                                    .resizable().scaledToFit().frame(width: 100)
                                    .offset(x: -80 + cloud1X, y: 0)
                                Image("wolk02")
                                    .resizable().scaledToFit().frame(width: 70)
                                    .offset(x: 110 + cloud2X, y: -15)
                                Image("wolk01")
                                    .resizable().scaledToFit().frame(width: 60)
                                    .opacity(0.7)
                                    .offset(x: 30 + cloud3X, y: 30)
                                Image("wolk02")
                                    .resizable().scaledToFit().frame(width: 50)
                                    .opacity(0.5)
                                    .offset(x: -120 + cloud4X, y: 20)
                                // Lager — vlak bij de auto
                                Image("wolk02")
                                    .resizable().scaledToFit().frame(width: 55)
                                    .opacity(0.45)
                                    .offset(x: 100 + cloud3X, y: 140)
                                Image("wolk01")
                                    .resizable().scaledToFit().frame(width: 45)
                                    .opacity(0.35)
                                    .offset(x: -90 + cloud1X, y: 160)
                            }
                            .padding(.top, safeTop + 55)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .allowsHitTesting(false)

                        VStack(spacing: 0) {
                            // Paginatitel scrollt mee, netjes gecentreerd; de back-knop
                            // is sticky en zweeft links erover.
                            Text("Parkeren")
                                .font(AppFont.theMix(size: 26, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.horizontal, AppDesign.horizontalPadding)
                                .padding(.top, safeTop + 18)

                            Spacer().frame(height: 40)

                            VStack(spacing: 12) {
                                ForEach(activeSessions) { session in
                                    sessionCard(session: session)
                                }
                            }
                            .frame(width: contentWidth)

                            Spacer().frame(height: 20)

                            // Illustration — curve overlay covers bottom ~40px
                            ZStack(alignment: .bottom) {
                                ZStack {
                                    Image("parkeer-bord")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 144)
                                        .offset(x: -50, y: bordOffsetY)
                                        .opacity(bordOpacity)

                                    Image("parkeer-auto")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 216)
                                        .rotationEffect(.degrees(carRotation), anchor: .bottom)
                                        .offset(x: 20 + carOffsetX, y: 10)
                                }
                                .padding(.bottom, 10)
                            }
                            // De ellips is breder dan het scherm. Als achtergrond telt hij
                            // niet mee voor de breedte; als gewoon kind duwde hij de hele
                            // kop (en het sessiekaartje) 9 pt naar rechts (design review).
                            .frame(maxWidth: .infinity)
                            .background(alignment: .bottom) {
                                Ellipse()
                                    .fill(Color(hex: "C8D8E8"))
                                    .frame(width: 420, height: 45)
                            }
                            .frame(height: 168)
                            .padding(.bottom, 30)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .animation(.easeInOut(duration: 0.5), value: activeSessions.isEmpty)
                    .overlay(alignment: .bottom) {
                        HeaderCurveShape()
                            .fill(AppColors.background)
                            .frame(height: 75)
                    }

                    // MARK: - Content below header
                    VStack(alignment: .leading, spacing: 24) {
                        // Snel regelen
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Snel regelen")
                                .font(AppFont.theMix(size: 20, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)

                            VStack(spacing: 0) {
                                menuItemCustom(icon: "icon-parking", label: "Bezoeker aanmelden") {
                                    showAanmeldenSheet = true
                                }
                                Rectangle()
                                    .fill(AppColors.grijs2)
                                    .frame(height: 1)
                                menuItemCustom(icon: "icon-contactbook", label: "Bewaarde kentekens") {
                                    showKentekensSheet = true
                                }
                                Rectangle()
                                    .fill(AppColors.grijs2)
                                    .frame(height: 1)
                                menuItemCustom(icon: "icon-coin-euro", label: "Transacties") { }
                            }
                            .frame(width: contentWidth)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(AppColors.grijs2, lineWidth: 1)
                            )
                        }

                        // Alles over parkeren link
                        Button {
                            // External link
                        } label: {
                            HStack(spacing: 6) {
                                Text("Alles over parkeren")
                                    .font(AppFont.theSans(size: 16, weight: .semiBold))
                                Image(systemName: "arrow.up.right.square")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(AppColors.groen3)
                            .frame(width: contentWidth)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .cornerRadius(AppDesign.cornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppDesign.cornerRadius)
                                    .stroke(AppColors.groen3, lineWidth: 1)
                            )
                        }

                        Spacer().frame(height: 100)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppDesign.horizontalPadding)
                    .padding(.top, 24)
                }
                .frame(maxWidth: .infinity)
            }
            .bovenVervaging()

            // Floating nav bar: alleen de back-knop is sticky (titel scrollt mee).
            HStack(alignment: .center, spacing: 12) {
                BackCircleButton(stijl: .kleur) { isPresented = false }
                Spacer()
            }
            .padding(.horizontal, AppDesign.horizontalPadding)
            .padding(.top, safeTop + 8)
        }
        .background(AppColors.background)
        .ignoresSafeArea(edges: .top)
        .onAppear {
            startCloudAnimation()
            startCarAnimation()
        }
        .sheet(isPresented: $showAanmeldenSheet) {
            ParkeerAanmeldenSheet(
                savedKentekens: $savedKentekens,
                onSessionStarted: { kenteken, name, startTime, endTime in
                    let newSession = ParkeerSessie(kenteken: kenteken, name: name, startTime: startTime, endTime: endTime)
                    withAnimation {
                        activeSessions.append(newSession)
                    }
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showKentekensSheet) {
            SavedKentekensSheet(savedKentekens: $savedKentekens)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
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

    // MARK: - Car Drive-In Animation

    private func startCarAnimation() {
        guard !carAppeared else { return }
        carAppeared = true

        // 1. Car drives in — snel met harde rem aan het eind (agressieve ease-out)
        withAnimation(.timingCurve(0.0, 0.0, 0.05, 1.0, duration: 0.7).delay(0.2)) {
            carOffsetX = 0
        }

        // 2. Achterkant omhoog bij remmen
        withAnimation(.easeOut(duration: 0.18).delay(0.75)) {
            carRotation = 6
        }

        // 3. Terug bouncen met veer
        withAnimation(.spring(response: 0.45, dampingFraction: 0.35).delay(0.93)) {
            carRotation = 0
        }

        // 4. P-bord poppt omhoog vanuit de onderkant met bounce
        withAnimation(.spring(response: 0.5, dampingFraction: 0.45).delay(0.35)) {
            bordOffsetY = 0
            bordOpacity = 1
        }
    }

    // MARK: - Session Card

    private func sessionCard(session: ParkeerSessie) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Status row
            HStack(spacing: 8) {
                ParkeerMeterIndicator()

                Text("ACTIEF")
                    .font(AppFont.theSans(size: 12, weight: .bold))
                    .foregroundColor(AppColors.rood)
                    .tracking(1)

                Rectangle()
                    .fill(AppColors.grijs2)
                    .frame(width: 1, height: 16)

                Image(systemName: "clock")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)
                Text("\(session.startTime) – \(session.endTime)")
                    .font(AppFont.theSans(size: 14, weight: .plain))
                    .foregroundColor(AppColors.textSecondary)
            }

            // Title with name
            Text("\(session.name) is geparkeerd")
                .font(AppFont.theMix(size: 20, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            // Stop button
            Button {
                withAnimation {
                    activeSessions.removeAll { $0.id == session.id }
                }
            } label: {
                HStack(spacing: 6) {
                    Text("Stoppen")
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
                .background(AppColors.rood)
                .cornerRadius(AppDesign.cornerRadius)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.white)
        .cornerRadius(AppDesign.cornerRadius)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }

    // MARK: - Menu Item (custom icon from asset catalog)

    private func menuItemCustom(icon: String, label: String, action: @escaping () -> Void) -> some View {
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
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Parking Meter Spinning Indicator

private struct ParkeerMeterIndicator: View {
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(AppColors.rood.opacity(0.25), lineWidth: 2)
                .frame(width: 16, height: 16)

            // Spinning arc
            Circle()
                .trim(from: 0, to: 0.3)
                .stroke(AppColors.rood, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: 16, height: 16)
                .rotationEffect(.degrees(rotation))

            // Center dot
            Circle()
                .fill(AppColors.rood)
                .frame(width: 4, height: 4)
        }
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - Parkeerbezoek Aanmelden Sheet (Scherm 2 - Drawer)

struct ParkeerAanmeldenSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var savedKentekens: [SavedKenteken]
    var onSessionStarted: ((String, String, String, String) -> Void)? = nil

    @State private var kenteken = ""
    @State private var selectedContact: SavedKenteken?
    @State private var showKentekenPicker = false
    @State private var showAddName = false
    @State private var newContactName = ""
    @State private var selectedDuration: Int? = nil // hours: 1, 2, 3, 4
    @State private var useNow = true
    @State private var startDate = Date()
    @State private var endDate: Date = {
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day], from: Date())
        comps.hour = 23
        comps.minute = 0
        return cal.date(from: comps) ?? Date()
    }()
    @FocusState private var kentekenFocused: Bool
    @FocusState private var nameFocused: Bool

    private var isValidKenteken: Bool {
        kenteken.filter({ $0.isLetter || $0.isNumber }).count >= 6
    }

    private var safeBottom: CGFloat {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        return windowScene?.windows.first?.safeAreaInsets.bottom ?? 34
    }

    private var resolvedName: String {
        if let contact = selectedContact {
            return contact.name
        }
        return kenteken
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                // Close button
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppColors.textSecondary)
                            .frame(width: 36, height: 36)
                            .background(AppColors.warmGrijs)
                            .clipShape(Circle())
                    }
                }
                .padding(.top, 16)

                // Title
                Text("Parkeerbezoek\naanmelden")
                    .font(AppFont.theMix(size: 28, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                // MARK: Kenteken + Time (same width wrapper)
                VStack(spacing: 0) {
                    // Kenteken Section
                    VStack(spacing: 12) {
                        Text("Vul het kenteken in")
                            .font(AppFont.theSans(size: 16, weight: .semiBold))
                            .foregroundColor(AppColors.textSecondary)
                            .frame(maxWidth: .infinity)

                        kentekenInput

                        contactSection
                    }

                    Spacer().frame(height: 52)

                    // Time Section
                    VStack(spacing: 16) {
                        Text("Kies tijd en duur")
                            .font(AppFont.theMix(size: 18, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)

                        timePicker
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "F5F5F5"))
                    .cornerRadius(12)

                    // Duration chips
                    Spacer().frame(height: 16)

                    HStack(spacing: 5) {
                        ForEach([1, 2, 3, 4], id: \.self) { hours in
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedDuration = hours
                                    // Calculate end time based on start
                                    let baseDate = useNow ? Date() : startDate
                                    if let newEnd = Calendar.current.date(byAdding: .hour, value: hours, to: baseDate) {
                                        endDate = newEnd
                                    }
                                }
                            } label: {
                                Text("\(hours) uur")
                                    .font(AppFont.theSans(size: 15, weight: selectedDuration == hours ? .semiBold : .plain))
                                    .foregroundColor(selectedDuration == hours ? .white : .black)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .background(selectedDuration == hours ? AppColors.groen3 : AppColors.warmGrijs)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(selectedDuration == hours ? AppColors.groen3 : Color(hex: "DEDEDE"), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 40) // both kenteken and time get same width

                Spacer().frame(height: 52 - 28) // 52px between grey block and button

                // MARK: Start Button
                Button {
                    let tf = DateFormatter()
                    tf.dateFormat = "HH:mm"
                    let startStr = useNow ? tf.string(from: Date()) : tf.string(from: startDate)
                    let endStr = tf.string(from: endDate)
                    onSessionStarted?(kenteken, resolvedName, startStr, endStr)
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Text("Starten")
                            .font(AppFont.theSans(size: 18, weight: .bold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(isValidKenteken ? AppColors.groen3 : AppColors.grijs2)
                    .cornerRadius(AppDesign.cornerRadius)
                }
                .disabled(!isValidKenteken)

                Spacer().frame(height: safeBottom > 0 ? safeBottom : 16)
            }
            .padding(.horizontal, AppDesign.horizontalPadding)
        }
        .background(Color.white)
        .sheet(isPresented: $showKentekenPicker) {
            kentekenPickerSheet
        }
    }

    // MARK: - Kenteken Input (NL License Plate Style)

    private var kentekenInput: some View {
        HStack(spacing: 0) {
            // Blue NL/EU strip
            VStack(spacing: 1) {
                Circle()
                    .strokeBorder(Color(hex: "FFD700").opacity(0.6), lineWidth: 0.5)
                    .frame(width: 10, height: 10)
                    .overlay(
                        ForEach(0..<12, id: \.self) { i in
                            Circle()
                                .fill(Color(hex: "FFD700").opacity(0.7))
                                .frame(width: 1, height: 1)
                                .offset(y: -4)
                                .rotationEffect(.degrees(Double(i) * 30))
                        }
                    )
            }
            .frame(width: 30)
            .frame(maxHeight: .infinity)
            .background(Color(hex: "003DA5"))

            TextField(kenteken.isEmpty ? "  -     -  " : "", text: $kenteken)
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundColor(Color(hex: "1A1A1A"))
                .textCase(.uppercase)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.characters)
                .focused($kentekenFocused)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
                .onChange(of: kenteken) { _, newValue in
                    kenteken = formatKenteken(newValue)
                    let clean = kenteken.lowercased().replacingOccurrences(of: "-", with: "")
                    selectedContact = savedKentekens.first {
                        $0.kenteken.lowercased().replacingOccurrences(of: "-", with: "") == clean
                    }
                    if selectedContact != nil {
                        showAddName = false
                    }
                }
        }
        .frame(height: 60)
        .background(Color(hex: "F7C100"))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(hex: "1A1A1A"), lineWidth: 1.5)
        )
    }

    // MARK: - Contact Section

    @ViewBuilder
    private var contactSection: some View {
        if let contact = selectedContact {
            HStack(spacing: 6) {
                Text("Auto van")
                    .font(AppFont.theSans(size: 15, weight: .plain))
                    .foregroundColor(AppColors.textSecondary)
                Text(contact.name)
                    .font(AppFont.theSans(size: 15, weight: .bold))
                    .foregroundColor(AppColors.groen3)

                Button {
                    selectedContact = nil
                    kenteken = ""
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AppColors.groen3)
                        .frame(width: 18, height: 18)
                        .background(AppColors.groen3.opacity(0.15))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color(hex: "E8F5E9"))
            .cornerRadius(20)
        } else if isValidKenteken && !showAddName {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showAddName = true
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                    Text("voeg toe aan contacten")
                        .font(AppFont.theSans(size: 15, weight: .semiBold))
                }
                .foregroundColor(AppColors.blauw3)
            }
        } else if showAddName {
            VStack(spacing: 8) {
                Text("Naam voor dit kenteken")
                    .font(AppFont.theSans(size: 14, weight: .semiBold))
                    .foregroundColor(AppColors.textSecondary)

                HStack(spacing: 8) {
                    TextField("Bijv. Leo", text: $newContactName)
                        .font(AppFont.theSans(size: 16, weight: .plain))
                        .focused($nameFocused)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(AppColors.grijs2, lineWidth: 1)
                        )

                    Button {
                        let newEntry = SavedKenteken(kenteken: kenteken, name: newContactName)
                        savedKentekens.append(newEntry)
                        selectedContact = newEntry
                        showAddName = false
                        newContactName = ""
                        nameFocused = false
                    } label: {
                        Text("Opslaan")
                            .font(AppFont.theSans(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(newContactName.isEmpty ? AppColors.grijs2 : AppColors.groen3)
                            .cornerRadius(6)
                    }
                    .disabled(newContactName.isEmpty)
                }
            }
        } else if kenteken.isEmpty {
            Button {
                showKentekenPicker = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "text.book.closed")
                        .font(.system(size: 14, weight: .medium))
                    Text("Kenteken kiezen")
                        .font(AppFont.theSans(size: 15, weight: .semiBold))
                }
                .foregroundColor(AppColors.blauw3)
            }
        }
    }

    // MARK: - Time Picker (Native DatePicker)

    private var timePicker: some View {
        HStack(spacing: 12) {
            VStack(spacing: 6) {
                Text("vanaf")
                    .font(AppFont.theSans(size: 14, weight: .plain))
                    .foregroundColor(AppColors.textSecondary)

                if useNow {
                    Button {
                        useNow = false
                        startDate = Date()
                    } label: {
                        Text("Nu")
                            .font(AppFont.theSans(size: 17, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(AppColors.grijs2, lineWidth: 1)
                            )
                    }
                } else {
                    DatePicker("", selection: $startDate, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .environment(\.locale, Locale(identifier: "nl_NL"))
                }
            }

            VStack(spacing: 6) {
                Text("tot")
                    .font(AppFont.theSans(size: 14, weight: .plain))
                    .foregroundColor(AppColors.textSecondary)

                DatePicker("", selection: $endDate, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .environment(\.locale, Locale(identifier: "nl_NL"))
            }
        }
    }

    // MARK: - Kenteken Picker Sheet

    private var kentekenPickerSheet: some View {
        NavigationStack {
            List(savedKentekens) { saved in
                Button {
                    kenteken = saved.kenteken
                    selectedContact = saved
                    showKentekenPicker = false
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "person.circle")
                            .font(.system(size: 28))
                            .foregroundColor(AppColors.textSecondary)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(saved.name)
                                .font(AppFont.theSans(size: 18, weight: .semiBold))
                                .foregroundColor(AppColors.textPrimary)
                            Text(saved.kenteken)
                                .font(.system(size: 16, weight: .medium, design: .monospaced))
                                .foregroundColor(AppColors.textSecondary)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Kies kenteken")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Klaar") { showKentekenPicker = false }
                }
            }
        }
    }

    // MARK: - Format

    private func formatKenteken(_ input: String) -> String {
        // Strip to only letters and numbers
        let clean = input.uppercased().filter { $0.isLetter || $0.isNumber }
        let trimmed = String(clean.prefix(6))
        return formatWithDashes(trimmed)
    }

    private func formatWithDashes(_ clean: String) -> String {
        // Dutch license plates: always format as XX-XX-XX (groups of 2)
        guard !clean.isEmpty else { return "" }
        var result = ""
        for (i, char) in clean.enumerated() {
            if i > 0 && i % 2 == 0 {
                result += "-"
            }
            result += String(char)
        }
        return result
    }
}

// MARK: - Saved Kentekens Sheet

struct SavedKentekensSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var savedKentekens: [SavedKenteken]

    var body: some View {
        NavigationStack {
            Group {
                if savedKentekens.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "text.book.closed")
                            .font(.system(size: 40))
                            .foregroundColor(AppColors.textSecondary)
                        Text("Geen bewaarde kentekens")
                            .font(AppFont.theSans(size: 18, weight: .plain))
                            .foregroundColor(AppColors.textSecondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    List {
                        ForEach(savedKentekens) { saved in
                            HStack(spacing: 12) {
                                Image(systemName: "person.circle")
                                    .font(.system(size: 28))
                                    .foregroundColor(AppColors.textSecondary)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(saved.name)
                                        .font(AppFont.theSans(size: 18, weight: .semiBold))
                                        .foregroundColor(AppColors.textPrimary)
                                    Text(saved.kenteken)
                                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                                        .foregroundColor(AppColors.textSecondary)
                                }

                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete { offsets in
                            withAnimation {
                                savedKentekens.remove(atOffsets: offsets)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Bewaarde kentekens")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Klaar") { dismiss() }
                        .foregroundColor(AppColors.groen3)
                }
            }
        }
    }
}

// MARK: - Corner Radius Helper

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }
}

struct RoundedCornerShape: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
