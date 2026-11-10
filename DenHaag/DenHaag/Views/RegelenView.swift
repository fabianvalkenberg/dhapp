import SwiftUI

// MARK: - Regelen AI Mode

enum RegelenPhase {
    case idle, loading, followUp, result, error
}

// Een tegel-suggestie onderaan het Regelen-scherm
struct SuggestionTile: Hashable {
    let title: String
    let illustration: String
}

// A single message in the conversation
struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool // true = user bubble, false = AI response
    let actions: [RegelenAction] // only for AI result messages
    let isFollowUp: Bool

    init(text: String, isUser: Bool, actions: [RegelenAction] = [], isFollowUp: Bool = false) {
        self.text = text
        self.isUser = isUser
        self.actions = actions
        self.isFollowUp = isFollowUp
    }
}

struct RegelenView: View {
    @EnvironmentObject var lang: LanguageManager
    /// Of de Regelen-tab momenteel actief is; zo niet, pauzeert de tegel-marquee.
    var isActive: Bool = true
    @State private var phase: RegelenPhase = .idle
    @State private var inputText = ""
    @State private var messages: [ChatMessage] = []
    @State private var errorMessage: String?
    @FocusState private var isInputFocused: Bool
    @StateObject private var speech = SpeechService()

    @State private var keyboardHeight: CGFloat = 0
    @State private var keyboardObservers: [NSObjectProtocol] = []
    @State private var greetingShown = false
    @State private var conversationHistory: [[String: String]] = []

    private let validIcons: Set<String> = [
        "calendar", "location-pin", "phone", "user", "truck", "bin",
        "done", "feedback", "bell", "chat", "preferences", "help",
        "megaphone", "arrow-right", "home", "cross", "plus", "question"
    ]

    private let suggestionTiles: [SuggestionTile] = [
        SuggestionTile(title: "Auto fout geparkeerd", illustration: "ill-melding"),
        SuggestionTile(title: "Grofvuil laten ophalen", illustration: "ill-grofvuil"),
        SuggestionTile(title: "Paspoort verlengen", illustration: "ill-id"),
        SuggestionTile(title: "Parkeer-vergunning", illustration: "ill-parkeerbezoek"),
        SuggestionTile(title: "Afval laten ophalen", illustration: "ill-afvalzak"),
        SuggestionTile(title: "Verhuizing doorgeven", illustration: "ill-buurt"),
        SuggestionTile(title: "Rijbewijs verlengen", illustration: "ill-id"),
        SuggestionTile(title: "Ooievaarspas aanvragen", illustration: "ill-ooievaarspas"),
        SuggestionTile(title: "Boom of groen melden", illustration: "ill-melding"),
        SuggestionTile(title: "Vraag over belasting", illustration: "ill-afspraak"),
    ]

    private var safeTop: CGFloat { AppDesign.safeAreaTop }

    /// Afstand van de inputbalk tot de fysieke onderkant: boven het toetsenbord
    /// als dat open is, anders boven de tab bar. Eén bron van waarheid, geen magie.
    private var bottomInset: CGFloat {
        keyboardHeight > 0 ? keyboardHeight + 10 : 136
    }

    private var chipsVisible: Bool {
        phase == .idle && keyboardHeight == 0
    }

    /// Hoogte van de onderbalk (input + eventueel de tegels).
    private var bottomBarHeight: CGFloat {
        56 + (chipsVisible ? 166 : 0) // input(56) + tegels(150) + toppadding(16)
    }

    var body: some View {
        GeometryReader { _ in
            ZStack(alignment: .bottom) {
                AppColors.background.ignoresSafeArea()

                // Bovenste content (wisselt per fase)
                if phase == .idle {
                    idleGreeting
                        .transition(.opacity)
                } else {
                    chatScroll
                }

                // Persistente onderbalk: de input zit ALTIJD in de tree, de tegels
                // alleen in idle. Begroeting en input delen `bottomInset` en
                // schuiven zo netjes samen mee met het toetsenbord.
                bottomBar

                // Nieuwe-chat-knop (alleen tijdens een gesprek), rechtsboven.
                if phase != .idle {
                    newChatButton
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(.trailing, AppDesign.horizontalPadding)
                        .padding(.top, safeTop + 10)
                        .transition(.opacity)
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .onAppear {
            setupKeyboardObservers()
        }
        .onDisappear {
            removeKeyboardObservers()
        }
    }

    // MARK: - Onderbalk (altijd aanwezig)

    private var bottomBar: some View {
        VStack(spacing: 0) {
            inputBar
                .padding(.horizontal, AppDesign.horizontalPadding)

            if chipsVisible {
                tickerTapeChips
                    .frame(height: 150)
                    .padding(.top, 16)
                    .transition(.opacity)
            }
        }
        .padding(.bottom, bottomInset)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0), Color.white],
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 0.4)
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)
        )
        .animation(.easeOut(duration: 0.25), value: keyboardHeight)
    }

    // MARK: - Idle: begroeting boven de onderbalk

    private var idleGreeting: some View {
        VStack(spacing: 0) {
            Spacer(minLength: safeTop + 24)

            greetingBlock
                .padding(.horizontal, AppDesign.horizontalPadding)

            // Ruimte onder de begroeting = onderbalk + 28pt tussenruimte.
            Spacer().frame(height: bottomBarHeight + 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, bottomInset)
    }

    // MARK: - Nieuwe-chat-knop

    private var newChatButton: some View {
        Button { startNewChat() } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .bold))
                Text("Nieuwe vraag")
                    .font(AppFont.theSans(size: 14, weight: .semiBold))
            }
            .foregroundColor(AppColors.groen3)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Color.white)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(AppColors.grijs2, lineWidth: 1))
            .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Chat: scrollende berichten

    private var chatScroll: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Color.clear.frame(height: safeTop + 56)

                    ForEach(messages) { message in
                        if message.isUser {
                            chatBubble(text: message.text)
                                .padding(.horizontal, AppDesign.horizontalPadding)
                                .padding(.bottom, 16)
                                .id(message.id)
                        } else {
                            VStack(alignment: .leading, spacing: 0) {
                                boldFormattedText(message.text)
                                    .padding(.horizontal, AppDesign.horizontalPadding)
                                    .padding(.top, 8)

                                if !message.actions.isEmpty {
                                    actionsList(message.actions)
                                        .padding(.horizontal, AppDesign.horizontalPadding)
                                        .padding(.top, 16)
                                }
                            }
                            .padding(.bottom, 16)
                            .id(message.id)
                        }
                    }

                    if phase == .loading {
                        PlayfulPulsingDots()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, AppDesign.horizontalPadding)
                            .padding(.top, 8)
                            .padding(.bottom, 16)
                            .id("loading")
                    }

                    if phase == .error, let error = errorMessage {
                        errorBlock(message: error)
                            .padding(.horizontal, AppDesign.horizontalPadding)
                            .padding(.top, 20)
                    }

                    Color.clear
                        .frame(height: 16)
                        .id("chatBottom")
                }
            }
            // De scroll eindigt boven de inputbalk (+ toetsenbord), zodat het
            // invoerveld nooit over de antwoordtekst valt — ook niet bij een kort
            // antwoord dat niet kan scrollen.
            .padding(.bottom, 56 + bottomInset + 8)
            .animation(.easeOut(duration: 0.25), value: keyboardHeight)
            // Sleep omlaag in de chat om het toetsenbord weg te halen.
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: messages.count) { _, _ in scrollToBottom(proxy) }
            .onChange(of: phase) { _, _ in scrollToBottom(proxy) }
            .onChange(of: keyboardHeight) { _, _ in scrollToBottom(proxy) }
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo("chatBottom", anchor: .bottom)
            }
        }
    }

    // MARK: - Greeting

    /// Naam uit de onboarding (zelfde bron als de home-greeting); valt terug op "Anne".
    private var greetingName: String {
        let n = (UserDefaults.standard.string(forKey: "userName") ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return n.isEmpty ? "Anne" : n
    }

    private var greetingBlock: some View {
        VStack(spacing: 4) {
            Text("Hi \(greetingName),")
                .font(AppFont.theMix(size: 26, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            Text(lang.t("what_to_arrange"))
                .font(AppFont.theMix(size: 26, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, alignment: .center)
        // Rustige openingsanimatie: fade + lichte slide omhoog.
        .opacity(greetingShown ? 1 : 0)
        .offset(y: greetingShown ? 0 : 14)
        .onAppear {
            withAnimation(.easeOut(duration: 0.55).delay(0.15)) {
                greetingShown = true
            }
        }
    }

    // MARK: - Chat Bubble (user message, top-right corner sharp)

    private func chatBubble(text: String) -> some View {
        HStack {
            Spacer()
            Text(text)
                .font(AppFont.theSans(size: 16, weight: .plain))
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color(hex: "EEF5E6"))
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 20,
                        bottomLeadingRadius: 20,
                        bottomTrailingRadius: 20,
                        topTrailingRadius: 0 // sharp top-right
                    )
                )
        }
    }

    // MARK: - Bold Formatted Text (parses **bold**)

    private func boldFormattedText(_ text: String) -> some View {
        let parts = parseBoldText(text)
        return parts.reduce(Text("")) { result, part in
            if part.isBold {
                return result + Text(part.text)
                    .font(AppFont.theSans(size: 18, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
            } else {
                return result + Text(part.text)
                    .font(AppFont.theSans(size: 18, weight: .plain))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .lineSpacing(5)
        .fixedSize(horizontal: false, vertical: true)
    }

    private struct TextPart {
        let text: String
        let isBold: Bool
    }

    private func parseBoldText(_ input: String) -> [TextPart] {
        var parts: [TextPart] = []
        var remaining = input

        while let startRange = remaining.range(of: "**") {
            let before = String(remaining[remaining.startIndex..<startRange.lowerBound])
            if !before.isEmpty {
                parts.append(TextPart(text: before, isBold: false))
            }
            remaining = String(remaining[startRange.upperBound...])
            if let endRange = remaining.range(of: "**") {
                let boldText = String(remaining[remaining.startIndex..<endRange.lowerBound])
                parts.append(TextPart(text: boldText, isBold: true))
                remaining = String(remaining[endRange.upperBound...])
            } else {
                parts.append(TextPart(text: remaining, isBold: false))
                remaining = ""
            }
        }
        if !remaining.isEmpty {
            parts.append(TextPart(text: remaining, isBold: false))
        }
        return parts
    }

    // MARK: - Input Bar (taller, text top, buttons bottom-right)

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField(lang.t("tell_what_arrange"), text: $inputText)
                .font(AppFont.theSans(size: 18, weight: .plain))
                .foregroundColor(AppColors.textPrimary)
                .focused($isInputFocused)
                .submitLabel(.send)
                .onSubmit {
                    if !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        submitQuery()
                    }
                }
                .onChange(of: speech.transcript) { _, newValue in
                    if speech.isListening && !newValue.isEmpty {
                        inputText = newValue
                    }
                }
                .toolbar {
                    // "Klaar"-knop boven het toetsenbord om het te sluiten. Alleen bij
                    // dít veld: de tab blijft in leven, anders verschijnt de knop ook
                    // boven tekstvelden elders in de app (waar hij niets doet).
                    if isInputFocused {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Klaar") { isInputFocused = false }
                                .font(AppFont.theSans(size: 17, weight: .bold))
                                .foregroundColor(AppColors.groen3)
                        }
                    }
                }

            micButton

            if !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                sendButton
            }
        }
        .padding(.leading, 20)
        .padding(.trailing, 8)
        .frame(minHeight: 56)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: AppDesign.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppDesign.cornerRadius)
                .stroke(
                    speech.isListening ? AppColors.rood : AppColors.grijs2,
                    lineWidth: speech.isListening ? 2 : 1
                )
        )
    }

    // MARK: - Mic Button

    private var micButton: some View {
        Button {
            if speech.isListening {
                speech.stopListening()
            } else {
                speech.requestPermission { granted in
                    if granted {
                        inputText = ""
                        speech.transcript = ""
                        speech.startListening()
                    }
                }
            }
        } label: {
            ZStack {
                if speech.isListening {
                    Circle()
                        .stroke(AppColors.rood.opacity(0.3), lineWidth: 2)
                        .frame(width: 36 + speech.audioLevel * 12, height: 36 + speech.audioLevel * 12)
                        .animation(.easeOut(duration: 0.1), value: speech.audioLevel)
                }

                Image(systemName: speech.isListening ? "waveform" : "mic")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(speech.isListening ? .white : AppColors.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(speech.isListening ? AppColors.rood : Color.clear)
                    .clipShape(Circle())
                    .scaleEffect(speech.isListening ? 1.0 + speech.audioLevel * 0.15 : 1.0)
                    .animation(.easeOut(duration: 0.1), value: speech.audioLevel)
            }
        }
    }

    // MARK: - Send Button

    private var sendButton: some View {
        Button {
            submitQuery()
        } label: {
            Image(systemName: "arrow.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(AppColors.groen3)
                .clipShape(Circle())
        }
        .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .opacity(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1.0)
    }

    // MARK: - Ticker Tape Suggestion Chips

    private var tickerTapeChips: some View {
        // Tegels schuiven kalm van rechts naar links (UIKit-marquee, buiten
        // SwiftUI's render-loop). Tikken stelt de vraag direct.
        MarqueeTilesView(
            tiles: suggestionTiles,
            paused: !isActive,
            onTap: { tile in
                AnalyticsService.track("chat_suggestion", ["title": tile.title])
                inputText = tile.title
                submitQuery()
            }
        )
        .frame(height: 150)
    }

    // MARK: - Actions List

    private func actionsList(_ actions: [RegelenAction]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(actions.enumerated()), id: \.element.id) { index, action in
                Button { } label: {
                    HStack(spacing: 12) {
                        safeIcon(name: action.icon)
                            .frame(width: 24, height: 24)
                            .foregroundColor(AppColors.textSecondary)

                        Text(action.title)
                            .font(AppFont.theSans(size: 18, weight: .plain))
                            .foregroundColor(AppColors.textSecondary)
                            .lineSpacing(18 * 0.3)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Image("arrow-right")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(16)
                }
                .buttonStyle(.plain)

                if index < actions.count - 1 {
                    Rectangle()
                        .fill(AppColors.grijs2)
                        .frame(height: 1)
                        .padding(.leading, 52)
                }
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppColors.grijs2, lineWidth: 1)
        )
    }

    // MARK: - Error

    private func errorBlock(message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(lang.t("something_went_wrong"))
                .font(AppFont.headingLarge())
                .foregroundColor(AppColors.textPrimary)

            Text(message)
                .font(AppFont.bodyRegular())
                .foregroundColor(AppColors.textSecondary)
                .lineSpacing(4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.warmGrijs)
        .cornerRadius(8)
    }

    // MARK: - Safe Icon

    @ViewBuilder
    private func safeIcon(name: String) -> some View {
        if validIcons.contains(name) {
            Image(name)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: "arrow.right.circle")
                .resizable()
                .scaledToFit()
        }
    }

    // MARK: - Actions

    private func submitQuery() {
        let query = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        // Add user message to chat
        messages.append(ChatMessage(text: query, isUser: true))
        AnalyticsService.track("chat_user", ["text": query])

        // Build conversation history for API
        conversationHistory.append(["role": "user", "content": query])

        inputText = ""
        isInputFocused = false
        speech.stopListening()

        phase = .loading

        let history = conversationHistory
        Task {
            do {
                let response = try await ClaudeService.shared.ask(
                    question: history.last?["content"] ?? query,
                    conversationHistory: Array(history.dropLast())
                )
                try await Task.sleep(nanoseconds: 500_000_000)

                await MainActor.run {
                    // Add AI response to conversation history
                    conversationHistory.append(["role": "assistant", "content": response.summary])

                    // Add AI message to chat
                    messages.append(ChatMessage(
                        text: response.summary,
                        isUser: false,
                        actions: response.actions,
                        isFollowUp: response.isFollowUp
                    ))

                    errorMessage = nil
                    AnalyticsService.track("chat_ai", [
                        "text": response.summary,
                        "isFollowUp": response.isFollowUp
                    ])
                    if response.isFollowUp {
                        phase = .followUp
                    } else {
                        phase = .result
                    }
                }
            } catch {
                await MainActor.run {
                    // Geen ruwe API-fout tonen in de demo; een vriendelijke melding.
                    errorMessage = "Er ging even iets mis. Probeer het zo nog eens."
                    phase = .error
                }
            }
        }
    }


    /// Begint een nieuwe chat: wist de berichten en keert terug naar de begroeting.
    private func startNewChat() {
        isInputFocused = false
        speech.stopListening()
        inputText = ""
        messages = []
        conversationHistory = []
        errorMessage = nil
        withAnimation(.easeInOut(duration: 0.3)) {
            phase = .idle
        }
    }

    // MARK: - Keyboard

    private func setupKeyboardObservers() {
        // Voorkom dubbele registratie bij heropenen van het scherm.
        removeKeyboardObservers()

        let show = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil, queue: .main
        ) { notification in
            if let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeOut(duration: 0.28)) {
                    keyboardHeight = frame.height
                }
            }
        }
        let hide = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil, queue: .main
        ) { _ in
            withAnimation(.easeOut(duration: 0.25)) {
                keyboardHeight = 0
            }
        }
        keyboardObservers = [show, hide]
    }

    private func removeKeyboardObservers() {
        // De closure-API geeft tokens terug; die moeten we verwijderen (niet `self`).
        keyboardObservers.forEach { NotificationCenter.default.removeObserver($0) }
        keyboardObservers = []
    }
}

// MARK: - Playful Pulsing Dots

struct PlayfulPulsingDots: View {
    @State private var yellowPosition = 0
    @State private var bounceOffsets: [CGFloat] = [0, 0, 0]
    private let timer = Timer.publish(every: 0.6, on: .main, in: .common).autoconnect()

    private let greenColor = AppColors.groen3
    private let yellowColor = AppColors.geel3

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(index == yellowPosition ? yellowColor : greenColor)
                    .frame(width: 12, height: 12)
                    .scaleEffect(index == yellowPosition ? 1.3 : 1.0)
                    .offset(y: bounceOffsets[index])
                    .animation(
                        .interpolatingSpring(stiffness: 180, damping: 8),
                        value: yellowPosition
                    )
                    .animation(
                        .interpolatingSpring(stiffness: 250, damping: 6),
                        value: bounceOffsets[index]
                    )
            }
        }
        .onReceive(timer) { _ in
            yellowPosition = (yellowPosition + 1) % 3

            // Bounce the yellow dot up
            withAnimation(.interpolatingSpring(stiffness: 300, damping: 5)) {
                bounceOffsets[yellowPosition] = -12
            }
            // Bring it back down
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.interpolatingSpring(stiffness: 200, damping: 7)) {
                    bounceOffsets[yellowPosition] = 0
                }
            }
        }
    }
}
