import SwiftUI

/// Korte feedback-vragenlijst (via Instellingen → "Wat vond je hiervan?"),
/// als stapsgewijze flow: één vraag per stap. Scores en open antwoord gaan naar
/// het sessie-document in Firestore (`sessions/{id}.feedback`).
struct FeedbackView: View {
    @Binding var isPresented: Bool

    @State private var step = 0
    @State private var ratings: [String: Int] = [:]
    @State private var wouldUse: String? = nil
    @State private var improve: String = ""
    @State private var submitted = false
    @FocusState private var improveFocused: Bool
    /// MainTabView negeert de keyboard-safe-area, dus vangen we de hoogte zelf op
    /// (zodat de Versturen-knop boven het toetsenbord blijft).
    @State private var keyboardHeight: CGFloat = 0

    private var safeTop: CGFloat { AppDesign.safeAreaTop }

    /// 1–5 schaalvragen, met de betekenis van de uitersten (1 en 5).
    private let questions: [(key: String, text: String, low: String, high: String)] = [
        ("ease",        "Hoe makkelijk was de app te gebruiken?", "Heel moeilijk",      "Heel makkelijk"),
        ("findability", "Vond je snel wat je zocht?",             "Helemaal niet",      "Meteen gevonden"),
        ("clarity",     "Hoe duidelijk was de taal?",             "Zeer onduidelijk",   "Heel duidelijk"),
        ("looks",       "Hoe aantrekkelijk vind je de app?",      "Niet aantrekkelijk", "Heel aantrekkelijk"),
    ]
    private let useOptions = ["Ja", "Misschien", "Nee"]

    /// 4 schaalvragen + "zou je gebruiken" + open antwoord.
    private var totalSteps: Int { questions.count + 2 }
    private var useStepIndex: Int { questions.count }       // 4
    private var improveStepIndex: Int { questions.count + 1 } // 5

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Terug-knop bovenin
                HStack {
                    BackCircleButton { back() }
                    Spacer()
                }
                // Horizontale marge komt van de VStack eromheen.
                // Dit scherm staat al onder de statusbalk: alleen de 8 pt erbij.
                .padding(.top, AppDesign.terugknopTop)

                // Stap-inhoud
                ZStack {
                    stepContent
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .id(step)

                controls
            }
            .padding(.horizontal, AppDesign.horizontalPadding)
            .padding(.bottom, keyboardHeight)

            if submitted { bedanktOverlay }
        }
        .animation(.easeInOut(duration: 0.3), value: step)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { note in
            if let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeOut(duration: 0.25)) { keyboardHeight = frame.height }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.25)) { keyboardHeight = 0 }
        }
    }

    // MARK: - Stappen

    @ViewBuilder
    private var stepContent: some View {
        if step < questions.count {
            ratingStep(questions[step])
        } else if step == useStepIndex {
            useStep
        } else {
            improveStep
        }
    }

    private func ratingStep(_ q: (key: String, text: String, low: String, high: String)) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Text(q.text)
                .font(AppFont.theMix(size: 26, weight: .bold))
                .foregroundColor(AppColors.darkGrey)
                .multilineTextAlignment(.center)

            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    ForEach(1...5, id: \.self) { n in
                        let isSel = ratings[q.key] == n
                        Button {
                            ratings[q.key] = n
                            advance()
                        } label: {
                            Text("\(n)")
                                .font(AppFont.theSans(size: 18, weight: .bold))
                                .foregroundColor(isSel ? .white : AppColors.grijs4)
                                .frame(width: 54, height: 54)
                                .background(isSel ? AppColors.groen3 : Color.white)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(isSel ? AppColors.groen3 : AppColors.grijs2, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Betekenis van de uitersten (1 en 5), zodat de score te plaatsen is.
                HStack(alignment: .top) {
                    scaleLabel("1", q.low, alignment: .leading)
                    Spacer()
                    scaleLabel("5", q.high, alignment: .trailing)
                }
                .frame(width: 318)
            }
            Spacer()
            Spacer()
        }
    }

    private func scaleLabel(_ cijfer: String, _ tekst: String, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 1) {
            Text(cijfer)
                .font(AppFont.theSans(size: 13, weight: .bold))
                .foregroundColor(AppColors.textSecondary)
            Text(tekst)
                .font(AppFont.theSans(size: 13, weight: .plain))
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(width: 110, alignment: alignment == .leading ? .leading : .trailing)
        .multilineTextAlignment(alignment == .leading ? .leading : .trailing)
    }

    private var useStep: some View {
        VStack(spacing: 28) {
            Spacer()
            Text("Zou je deze app gebruiken?")
                .font(AppFont.theMix(size: 26, weight: .bold))
                .foregroundColor(AppColors.darkGrey)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                ForEach(useOptions, id: \.self) { opt in
                    Button {
                        wouldUse = opt
                        advance()
                    } label: {
                        Text(opt)
                            .font(AppFont.theSans(size: 17, weight: wouldUse == opt ? .bold : .plain))
                            .foregroundColor(wouldUse == opt ? AppColors.groen4 : AppColors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(wouldUse == opt ? AppColors.groen1 : Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: AppDesign.cornerRadius))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppDesign.cornerRadius)
                                    .stroke(wouldUse == opt ? AppColors.groen3 : AppColors.grijs2, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            Spacer()
            Spacer()
        }
    }

    private var improveStep: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("Wat zou je verbeteren?")
                .font(AppFont.theMix(size: 26, weight: .bold))
                .foregroundColor(AppColors.darkGrey)
                .multilineTextAlignment(.center)

            TextField("Jouw antwoord (optioneel)", text: $improve, axis: .vertical)
                .font(AppFont.theSans(size: 16, weight: .plain))
                .lineLimit(3...6)
                .padding(14)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: AppDesign.cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: AppDesign.cornerRadius)
                        .stroke(AppColors.grijs2, lineWidth: 1)
                )
                .focused($improveFocused)

            Spacer()
        }
    }

    // MARK: - Controls (knop + paginadots) — onderaan, dus boven het toetsenbord

    private var controls: some View {
        VStack(spacing: 16) {
            if step == improveStepIndex {
                Button(action: submit) {
                    Text("Versturen")
                        .font(AppFont.theSans(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppColors.groen3)
                        .clipShape(RoundedRectangle(cornerRadius: AppDesign.cornerRadius))
                }
            }

            HStack(spacing: 8) {
                ForEach(0..<totalSteps, id: \.self) { i in
                    Capsule()
                        .fill(i == step ? AppColors.groen3 : AppColors.grijs2)
                        .frame(width: i == step ? 24 : 8, height: 8)
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: step)
        }
        .padding(.bottom, 20)
    }

    // MARK: - Navigatie

    private func advance() {
        // Korte vertraging zodat de keuze even zichtbaar is voor we doorgaan.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            if step < totalSteps - 1 {
                withAnimation(.easeInOut(duration: 0.3)) { step += 1 }
            }
        }
    }

    private func back() {
        if step > 0 {
            improveFocused = false
            withAnimation(.easeInOut(duration: 0.3)) { step -= 1 }
        } else {
            isPresented = false
        }
    }

    private var bedanktOverlay: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(AppColors.groen3)
                Text("Bedankt voor je feedback!")
                    .font(AppFont.theMix(size: 22, weight: .bold))
                    .foregroundColor(AppColors.darkGrey)
            }
        }
        .transition(.opacity)
    }

    private func submit() {
        improveFocused = false
        var fb: [String: Any] = ratings
        if let w = wouldUse { fb["wouldUse"] = w }
        let imp = improve.trimmingCharacters(in: .whitespacesAndNewlines)
        if !imp.isEmpty { fb["improve"] = imp }

        AnalyticsService.setSession(["feedback": fb])
        AnalyticsService.track("feedback_submit", fb)

        withAnimation { submitted = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            isPresented = false
        }
    }
}
