import SwiftUI

// MARK: - Form Data

struct GrofvuilFormData {
    var selectedCategory: String? = nil
    var customDescription: String = ""
    var photoCount: Int = 0
    var condition: String? = nil  // "kapot" or "bruikbaar"
    var address: String = "De Perponcherstraat 77, Den Haag"
    var selectedDate: Date? = nil
    var selectedTimeSlot: String? = nil
}

// MARK: - Category Model

struct GrofvuilCategory: Identifiable {
    let id: String
    let label: String
    let icon: String // SF Symbol

    static let all: [GrofvuilCategory] = [
        GrofvuilCategory(id: "fiets", label: "Fiets", icon: "bicycle"),
        GrofvuilCategory(id: "bank", label: "Bank", icon: "sofa.fill"),
        GrofvuilCategory(id: "tuinafval", label: "Tuinafval", icon: "leaf.fill"),
        GrofvuilCategory(id: "matras", label: "Matras", icon: "bed.double.fill"),
        GrofvuilCategory(id: "grofvuil", label: "Grofvuil", icon: "trash.fill"),
        GrofvuilCategory(id: "metaal", label: "Metaal", icon: "wrench.and.screwdriver.fill"),
    ]
}

// MARK: - Main Sheet

struct GrofvuilOphalenSheet: View {
    @Environment(\.dismiss) var dismiss
    var onAfspraakCreated: ((GrofvuilFormData) -> Void)? = nil

    @State private var currentStep: Int = 0 // 0=intro, 1-6=steps, 7=confirmation
    @State private var formData = GrofvuilFormData()
    /// Bepaalt de richting van de schuif-transitie tussen stappen.
    @State private var slideForward = true

    var body: some View {
        Group {
            switch currentStep {
            case 0:
                introView
            case 7:
                confirmationView
            default:
                stepView
            }
        }
        .background(Color.white)
        .animation(.easeInOut(duration: 0.25), value: currentStep)
    }

    // MARK: - Intro

    private var introView: some View {
        VStack(spacing: 0) {
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
            .padding(.horizontal, AppDesign.horizontalPadding)
            .padding(.top, 20)

            Spacer()

            VStack(spacing: 20) {
                Text("Laat uw grofvuil\nophalen")
                    .font(AppFont.theMix(size: 28, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Maak een afspraak om\nuw grofvuil te laten ophalen.")
                    .font(AppFont.theSans(size: 16, weight: .plain))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            // Start button
            Button {
                withAnimation { currentStep = 1 }
            } label: {
                HStack(spacing: 8) {
                    Text("Afspraak maken")
                        .font(AppFont.theSans(size: 18, weight: .bold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(AppColors.geel3)
                .cornerRadius(AppDesign.cornerRadius)
            }
            .padding(.horizontal, AppDesign.horizontalPadding)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Step View (1-6)

    private var stepView: some View {
        VStack(spacing: 0) {
            // Top bar (stappen-balk) — blijft staan tijdens het schuiven.
            stepTopBar

            // Schuivende content per stap: indicator + titel + keuzes.
            VStack(spacing: 0) {
                Text("\(currentStep) / 6")
                    .font(AppFont.theSans(size: 14, weight: .plain))
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.top, 8)

                Text(stepTitle)
                    .font(AppFont.theMix(size: 22, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppDesign.horizontalPadding)
                    .padding(.top, 8)
                    .padding(.bottom, 24)

                ScrollView(showsIndicators: false) {
                    stepContent
                        .padding(.horizontal, AppDesign.horizontalPadding)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .id(currentStep)
            .transition(.asymmetric(
                insertion: .move(edge: slideForward ? .trailing : .leading),
                removal: .move(edge: slideForward ? .leading : .trailing)
            ))

            // Volgende-stap knop: geen disabled state. Onzichtbaar tot je verder
            // kunt, en schuift dan van onder netjes op z'n plek.
            if canProceed {
                nextButton
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .clipped()
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: canProceed)
    }

    private var nextButton: some View {
        Button {
            slideForward = true
            withAnimation(.easeInOut(duration: 0.3)) {
                if currentStep == 6 {
                    currentStep = 7
                    onAfspraakCreated?(formData)
                } else {
                    currentStep += 1
                }
            }
        } label: {
            HStack(spacing: 8) {
                Text(currentStep == 6 ? "Bevestigen" : "Volgende stap")
                    .font(AppFont.theSans(size: 18, weight: .bold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(AppColors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(AppColors.geel3)
            .cornerRadius(AppDesign.cornerRadius)
        }
        .padding(.horizontal, AppDesign.horizontalPadding)
        .padding(.bottom, 40)
    }

    // MARK: - Top Bar

    private var stepTopBar: some View {
        HStack(spacing: 12) {
            // Back
            Button {
                slideForward = false
                withAnimation(.easeInOut(duration: 0.3)) {
                    if currentStep > 1 {
                        currentStep -= 1
                    } else {
                        currentStep = 0
                    }
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .frame(width: 32, height: 32)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppColors.grijs2)
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppColors.geel3)
                        .frame(width: geo.size.width * CGFloat(currentStep) / 6.0, height: 4)
                }
            }
            .frame(height: 4)

            // Close
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 32, height: 32)
            }
        }
        .padding(.horizontal, AppDesign.horizontalPadding)
        .padding(.top, 16)
    }

    // MARK: - Step Title

    private var stepTitle: String {
        switch currentStep {
        case 1: return "Wat wil je laten ophalen?"
        case 2: return "Voeg foto's toe"
        case 3: return "Wat is de staat van je \(formData.selectedCategory ?? "item")?"
        case 4: return "Waar wil je het laten ophalen?"
        case 5: return "Kies het moment van ophalen"
        case 6: return "Klopt dit allemaal?"
        default: return ""
        }
    }

    // MARK: - Can Proceed

    private var canProceed: Bool {
        switch currentStep {
        case 1: return formData.selectedCategory != nil
        case 2: return true // foto's zijn optioneel
        case 3: return formData.condition != nil
        case 4: return !formData.address.isEmpty
        case 5: return formData.selectedDate != nil && formData.selectedTimeSlot != nil
        case 6: return true
        default: return true
        }
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 1: stepCategorySelection
        case 2: stepPhotoUpload
        case 3: stepCondition
        case 4: stepAddress
        case 5: stepDateTime
        case 6: stepSummary
        default: EmptyView()
        }
    }

    // MARK: - Step 1: Category Selection

    private var stepCategorySelection: some View {
        VStack(spacing: 16) {
            // Text input
            HStack {
                TextField("Vertel", text: $formData.customDescription)
                    .font(AppFont.theSans(size: 16, weight: .plain))

                Image(systemName: "mic.fill")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppColors.grijs2, lineWidth: 1)
            )

            // "Of kies een van de onderwerpen"
            Text("Of kies een van de onderwerpen")
                .font(AppFont.theSans(size: 14, weight: .plain))
                .foregroundColor(AppColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Category grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(GrofvuilCategory.all) { cat in
                    Button {
                        formData.selectedCategory = cat.label
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: cat.icon)
                                .font(.system(size: 28))
                                .foregroundColor(formData.selectedCategory == cat.label ? .white : AppColors.groen3)

                            Text(cat.label)
                                .font(AppFont.theSans(size: 14, weight: .semiBold))
                                .foregroundColor(formData.selectedCategory == cat.label ? .white : AppColors.textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(formData.selectedCategory == cat.label ? AppColors.groen3 : AppColors.warmGrijs)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(formData.selectedCategory == cat.label ? Color.clear : AppColors.tegelBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Step 2: Photo Upload

    private var stepPhotoUpload: some View {
        VStack(spacing: 16) {
            if formData.photoCount > 0 {
                // Show placeholder thumbnails
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<formData.photoCount, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AppColors.warmGrijs)
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Image(systemName: "photo.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(AppColors.textSecondary)
                                )
                        }

                        // Add more button
                        Button {
                            formData.photoCount += 1
                        } label: {
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                                .foregroundColor(AppColors.grijs2)
                                .frame(width: 100, height: 100)
                                .overlay(
                                    VStack(spacing: 4) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(AppColors.groen3)
                                        Text("Foto")
                                            .font(AppFont.theSans(size: 14, weight: .plain))
                                            .foregroundColor(AppColors.textPrimary)
                                    }
                                )
                        }
                    }
                }
            } else {
                // Empty state: dashed upload area
                Button {
                    formData.photoCount += 1
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(AppColors.groen3)
                        Text("Foto")
                            .font(AppFont.theSans(size: 16, weight: .plain))
                            .foregroundColor(AppColors.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                            .foregroundColor(AppColors.grijs2)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Step 3: Condition

    private var stepCondition: some View {
        VStack(spacing: 12) {
            conditionButton(label: "Kapot", value: "kapot")
            conditionButton(label: "Nog te gebruiken", value: "bruikbaar")
        }
        .padding(.top, 12)
    }

    private func conditionButton(label: String, value: String) -> some View {
        Button {
            formData.condition = value
        } label: {
            Text(label)
                .font(AppFont.theSans(size: 18, weight: .bold))
                .foregroundColor(formData.condition == value ? .white : AppColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .background(formData.condition == value ? AppColors.groen3 : AppColors.warmGrijs)
                .cornerRadius(AppDesign.cornerRadius)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Step 4: Address

    private var stepAddress: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Je ophaladres")
                .font(AppFont.theSans(size: 14, weight: .semiBold))
                .foregroundColor(AppColors.textSecondary)

            HStack(spacing: 12) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.groen3)

                TextField("Adres", text: $formData.address)
                    .font(AppFont.theSans(size: 16, weight: .plain))
                    .foregroundColor(AppColors.textPrimary)
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppColors.grijs2, lineWidth: 1)
            )

            Text("Dit adres is uit je profiel. Je kan het aanpassen.")
                .font(AppFont.theSans(size: 13, weight: .plain))
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.top, 12)
    }

    // MARK: - Step 5: Date + Time

    // Generate time slots based on selected date
    private var availableTimeSlots: [(label: String, value: String)] {
        guard let date = formData.selectedDate else { return [] }
        let weekday = Calendar.current.component(.weekday, from: date) // 1=Sun, 2=Mon, ...
        let day = Calendar.current.component(.day, from: date)

        // Vary slots by weekday for realism
        switch weekday {
        case 2, 4: // Maandag, Woensdag — ochtend + middag
            return [
                ("Tussen 08:00 en 10:00", "08:00-10:00"),
                ("Tussen 12:00 en 14:00", "12:00-14:00"),
                ("Tussen 16:00 en 18:00", "16:00-18:00"),
            ]
        case 3, 5: // Dinsdag, Donderdag — middag
            return [
                ("Tussen 10:00 en 12:00", "10:00-12:00"),
                ("Tussen 14:00 en 16:00", "14:00-16:00"),
            ]
        case 6: // Vrijdag — alleen ochtend
            return [
                ("Tussen 08:00 en 10:00", "08:00-10:00"),
                ("Tussen 10:00 en 12:00", "10:00-12:00"),
            ]
        case 7: // Zaterdag — beperkt
            return day % 2 == 0 ?
                [("Tussen 09:00 en 11:00", "09:00-11:00")] :
                [("Tussen 10:00 en 12:00", "10:00-12:00")]
        default: // Zondag — niet beschikbaar
            return []
        }
    }

    private var stepDateTime: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Calendar
            GrofvuilCalendarView(selectedDate: Binding(
                get: { formData.selectedDate },
                set: { newDate in
                    formData.selectedDate = newDate
                    // Reset time slot when date changes
                    formData.selectedTimeSlot = nil
                }
            ))

            // Time slots (only shown when a date is selected)
            if formData.selectedDate != nil {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Kies een tijdslot")
                        .font(AppFont.theMix(size: 18, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)

                    if availableTimeSlots.isEmpty {
                        Text("Op deze dag is er geen ophaalservice beschikbaar. Kies een andere dag.")
                            .font(AppFont.theSans(size: 15, weight: .plain))
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.vertical, 12)
                    } else {
                        ForEach(availableTimeSlots, id: \.value) { slot in
                            timeSlotButton(label: slot.label, value: slot.value)
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: formData.selectedDate)
            }
        }
    }

    private func timeSlotButton(label: String, value: String) -> some View {
        Button {
            formData.selectedTimeSlot = value
        } label: {
            Text(label)
                .font(AppFont.theSans(size: 16, weight: .bold))
                .foregroundColor(formData.selectedTimeSlot == value ? .white : AppColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
                .background(formData.selectedTimeSlot == value ? AppColors.groen3 : Color.white)
                .cornerRadius(AppDesign.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: AppDesign.cornerRadius)
                        .stroke(formData.selectedTimeSlot == value ? AppColors.groen3 : AppColors.grijs2, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Step 6: Summary

    private var stepSummary: some View {
        VStack(spacing: 0) {
            summaryRow(label: "Wat wil je laten ophalen", value: formData.selectedCategory ?? "-", editStep: 1)
            summaryDivider
            summaryRow(label: "Foto's", value: formData.photoCount > 0 ? "\(formData.photoCount) foto('s)" : "Geen foto's toegevoegd", editStep: 2)
            summaryDivider
            summaryRow(label: "Staat", value: formData.condition == "kapot" ? "Kapot" : "Nog te gebruiken", editStep: 3)
            summaryDivider
            summaryRow(label: "Locatie", value: formData.address, editStep: 4)
            summaryDivider
            summaryRow(label: "Datum & tijd", value: formattedDateTime, editStep: 5)
        }
    }

    private func summaryRow(label: String, value: String, editStep: Int) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(AppFont.theSans(size: 13, weight: .semiBold))
                    .foregroundColor(AppColors.textSecondary)
                Text(value)
                    .font(AppFont.theSans(size: 16, weight: .plain))
                    .foregroundColor(AppColors.textPrimary)
            }
            Spacer()
            Button {
                withAnimation { currentStep = editStep }
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 32, height: 32)
            }
        }
        .padding(.vertical, 16)
    }

    private var summaryDivider: some View {
        Rectangle()
            .fill(AppColors.grijs2)
            .frame(height: 1)
    }

    private var formattedDateTime: String {
        guard let date = formData.selectedDate else { return "-" }
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "nl_NL")
        fmt.dateFormat = "d MMMM yyyy"
        let dateStr = fmt.string(from: date)
        let timeStr = formData.selectedTimeSlot ?? ""
        return "\(dateStr), \(timeStr)"
    }

    // MARK: - Confirmation

    private var confirmationView: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundColor(AppColors.groen3)
                .padding(.bottom, 20)

            Text("Afspraak ingepland")
                .font(AppFont.theMix(size: 28, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .padding(.bottom, 8)

            Text("Je grofvuil wordt opgehaald")
                .font(AppFont.theSans(size: 16, weight: .plain))
                .foregroundColor(AppColors.textSecondary)
                .padding(.bottom, 32)

            // Timeline
            VStack(alignment: .leading, spacing: 0) {
                timelineItem(text: "Je afspraak is bevestigd", isFirst: true, isLast: false)
                timelineItem(text: "Zet je grofvuil klaar op de afgesproken dag", isFirst: false, isLast: false)
                timelineItem(text: "Ons team komt het ophalen op het gekozen tijdslot", isFirst: false, isLast: false)
                timelineItem(text: "Je ontvangt een bevestiging per e-mail", isFirst: false, isLast: true)
            }
            .padding(.horizontal, AppDesign.horizontalPadding + 8)

            Spacer()

            // Close button
            Button {
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Text("Sluiten")
                        .font(AppFont.theSans(size: 18, weight: .bold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(AppColors.geel3)
                .cornerRadius(AppDesign.cornerRadius)
            }
            .padding(.horizontal, AppDesign.horizontalPadding)
            .padding(.bottom, 40)
        }
    }

    private func timelineItem(text: String, isFirst: Bool, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 0) {
                Circle()
                    .fill(isFirst ? AppColors.groen3 : AppColors.grijs2)
                    .frame(width: 10, height: 10)

                if !isLast {
                    Rectangle()
                        .fill(AppColors.grijs2)
                        .frame(width: 2, height: 40)
                }
            }

            Text(text)
                .font(AppFont.theSans(size: 15, weight: isFirst ? .semiBold : .plain))
                .foregroundColor(AppColors.textPrimary)
                .padding(.top, -4)
        }
    }
}

// MARK: - Custom Calendar View

struct GrofvuilCalendarView: View {
    @Binding var selectedDate: Date?
    @State private var displayedMonth = Date()

    private let calendar = Calendar(identifier: .gregorian)
    private let weekdays = ["Ma", "Di", "Wo", "Do", "Vr", "Za", "Zo"]

    private var monthTitle: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "nl_NL")
        fmt.dateFormat = "MMMM yyyy"
        return fmt.string(from: displayedMonth).capitalized
    }

    private var daysInMonth: [Date?] {
        var comps = calendar.dateComponents([.year, .month], from: displayedMonth)
        comps.day = 1
        guard let firstDay = calendar.date(from: comps) else { return [] }

        // Weekday offset (Monday = 1 in our grid)
        var weekday = calendar.component(.weekday, from: firstDay) - 2 // Sunday=0->-1, Monday=0
        if weekday < 0 { weekday += 7 }

        let range = calendar.range(of: .day, in: .month, for: firstDay)!
        var days: [Date?] = Array(repeating: nil, count: weekday)

        for day in range {
            comps.day = day
            days.append(calendar.date(from: comps))
        }

        return days
    }

    private func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    private func isSelected(_ date: Date) -> Bool {
        guard let sel = selectedDate else { return false }
        return calendar.isDate(date, inSameDayAs: sel)
    }

    private func isPast(_ date: Date) -> Bool {
        date < calendar.startOfDay(for: Date())
    }

    var body: some View {
        VStack(spacing: 16) {
            // Month navigation
            HStack {
                Button {
                    displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                }

                Spacer()

                Text(monthTitle)
                    .font(AppFont.theMix(size: 18, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)

                Spacer()

                Button {
                    displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                }
            }

            // Weekday headers
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(AppFont.theSans(size: 13, weight: .semiBold))
                        .foregroundColor(AppColors.textSecondary)
                        .frame(height: 32)
                }

                // Days
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, date in
                    if let date = date {
                        Button {
                            if !isPast(date) {
                                selectedDate = date
                            }
                        } label: {
                            Text("\(calendar.component(.day, from: date))")
                                .font(AppFont.theSans(size: 16, weight: isSelected(date) || isToday(date) ? .bold : .plain))
                                .foregroundColor(dayColor(date))
                                .frame(width: 36, height: 36)
                                .background(isSelected(date) ? AppColors.groen3 : Color.clear)
                                .clipShape(Circle())
                        }
                        .disabled(isPast(date))
                    } else {
                        Text("")
                            .frame(width: 36, height: 36)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppColors.grijs2, lineWidth: 1)
        )
    }

    private func dayColor(_ date: Date) -> Color {
        if isSelected(date) { return .white }        // wit op groen achtergrond
        if isPast(date)     { return AppColors.grijs2 }  // niet beschikbaar (grijs 2)
        if isToday(date)    { return AppColors.groen3 }  // vandaag (groen 3)
        return AppColors.grijs4                           // beschikbare dagen (grijs 4)
    }
}

// MARK: - Grofvuil Afspraak Detail View

struct GrofvuilAfspraakDetailView: View {
    @Environment(\.dismiss) var dismiss
    let formData: GrofvuilFormData

    private var safeTop: CGFloat { AppDesign.safeAreaTop }

    private var formattedDate: String {
        guard let date = formData.selectedDate else { return "Binnenkort" }
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "nl_NL")
        fmt.dateFormat = "EEEE d MMMM yyyy"
        return fmt.string(from: date).capitalized
    }

    var body: some View {
        ZStack(alignment: .top) {
            AppColors.background
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Green header
                    ZStack(alignment: .bottomLeading) {
                        AppColors.groen3
                            .frame(height: safeTop + 140)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Grofvuil ophalen")
                                .font(AppFont.theMix(size: 26, weight: .bold))
                                .foregroundColor(.white)

                            Text(formData.selectedCategory ?? "Grofvuil")
                                .font(AppFont.theSans(size: 18, weight: .plain))
                                .foregroundColor(.white.opacity(0.85))
                        }
                        .padding(.horizontal, AppDesign.horizontalPadding)
                        .padding(.bottom, 24)
                    }

                    VStack(alignment: .leading, spacing: AppDesign.sectionSpacing) {
                        // Info card
                        VStack(spacing: 0) {
                            detailInfoRow(icon: "calendar", label: "Datum", value: formattedDate)
                            detailDivider
                            detailInfoRow(icon: "clock", label: "Tijdslot", value: formData.selectedTimeSlot ?? "-", useSFSymbol: true)
                            detailDivider
                            detailInfoRow(icon: "location-pin", label: "Adres", value: formData.address)
                            if formData.condition != nil {
                                detailDivider
                                detailInfoRow(icon: "tag", label: "Staat", value: formData.condition == "kapot" ? "Kapot" : "Nog te gebruiken", useSFSymbol: true)
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(AppColors.grijs2, lineWidth: 1)
                        )
                        .padding(.top, 24)

                        // Instructions
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Zo bied je het aan")
                                .font(AppFont.theMix(size: 22, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)

                            Text("Volg onderstaande instructies zodat ons team je grofvuil makkelijk kan meenemen.")
                                .font(AppFont.theSans(size: 15, weight: .plain))
                                .foregroundColor(AppColors.textSecondary)
                                .lineSpacing(4)

                            VStack(alignment: .leading, spacing: 12) {
                                instructionRow(text: "Zet het grofvuil vóór 7:00 aan de weg")
                                instructionRow(text: "Plaats het op de stoep bij je voordeur")
                                instructionRow(text: "Zorg dat het goed zichtbaar en bereikbaar is")
                                instructionRow(text: "Bundel losse spullen zoveel mogelijk")
                                instructionRow(text: "Zet het niet naast ondergrondse containers")
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppColors.warmGrijs)
                            .cornerRadius(8)
                        }

                        // Action buttons
                        VStack(spacing: 12) {
                            Button { } label: {
                                HStack(spacing: 6) {
                                    Text("Afspraak verzetten")
                                        .font(AppFont.theSans(size: 16, weight: .semiBold))
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

                            Button { } label: {
                                HStack(spacing: 6) {
                                    Text("Afspraak annuleren")
                                        .font(AppFont.theSans(size: 16, weight: .semiBold))
                                    Spacer()
                                    Image("arrow-right")
                                        .renderingMode(.template)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 16, height: 16)
                                }
                                .foregroundColor(AppColors.rood)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity)
                                .background(Color.white)
                                .cornerRadius(AppDesign.cornerRadius)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppDesign.cornerRadius)
                                        .stroke(AppColors.rood.opacity(0.3), lineWidth: 1)
                                )
                            }

                            Button { } label: {
                                HStack(spacing: 6) {
                                    Text("Vraag stellen")
                                        .font(AppFont.theSans(size: 16, weight: .semiBold))
                                    Spacer()
                                    Image("arrow-right")
                                        .renderingMode(.template)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 16, height: 16)
                                }
                                .foregroundColor(AppColors.textSecondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity)
                                .background(Color.white)
                                .cornerRadius(AppDesign.cornerRadius)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppDesign.cornerRadius)
                                        .stroke(AppColors.grijs2, lineWidth: 1)
                                )
                            }
                        }

                        Spacer().frame(height: 60)
                    }
                    .padding(.horizontal, AppDesign.horizontalPadding)
                }
            }
            .ignoresSafeArea(edges: .top)

            // Close button
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, AppDesign.horizontalPadding)
            .padding(.top, safeTop + 8)
        }
    }

    private var detailDivider: some View {
        Divider().background(AppColors.grijs2).padding(.horizontal, 16)
    }

    private func detailInfoRow(icon: String, label: String, value: String, useSFSymbol: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 12) {
            if useSFSymbol {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 24, height: 24)
            } else {
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 24, height: 24)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(AppFont.theSans(size: 14, weight: .plain))
                    .foregroundColor(AppColors.textSecondary)
                Text(value)
                    .font(AppFont.theSans(size: 16, weight: .semiBold))
                    .foregroundColor(AppColors.textPrimary)
            }

            Spacer()
        }
        .padding(16)
    }

    private func instructionRow(text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(AppColors.groen3)
                .frame(width: 6, height: 6)
                .padding(.top, 8)

            Text(text)
                .font(AppFont.theSans(size: 16, weight: .plain))
                .foregroundColor(AppColors.textSecondary)
                .lineSpacing(4)
        }
    }
}
