import Foundation

// MARK: - Response Model

struct RegelenAIResponse {
    let summary: String
    let actions: [RegelenAction]
    let isFollowUp: Bool // true when AI needs more info
}

struct RegelenAction: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
}

// MARK: - Claude API Service

class ClaudeService {
    static let shared = ClaudeService()

    private let apiKey = APIConfig.claudeAPIKey
    private let endpoint = "https://api.anthropic.com/v1/messages"

    func ask(question: String, conversationHistory: [[String: String]] = []) async throws -> RegelenAIResponse {
        let systemPrompt = """
        Je bent een behulpzame assistent van de gemeente Den Haag. \
        Je helpt inwoners met gemeentelijke zaken zoals parkeren, afval, paspoorten, belastingen, verhuizen, etc.

        BELANGRIJK: Als de vraag van de inwoner onduidelijk, vaag of onvolledig is, stel dan eerst een \
        verduidelijkende vraag. Gebruik daarvoor dit JSON-formaat:
        {
          "vervolgvraag": true,
          "samenvatting": "Je verduidelijkende vraag hier. Gebruik **bold** voor het belangrijkste deel."
        }

        Als de vraag WEL duidelijk is, antwoord dan in dit JSON-formaat:
        {
          "vervolgvraag": false,
          "samenvatting": "Een duidelijke uitleg van 2-3 zinnen. Gebruik **bold** voor het allerbelangrijkste dat de inwoner moet weten.",
          "acties": [
            {"icon": "icoon_naam", "titel": "Actie titel"}
          ]
        }

        Beschikbare iconen: calendar, location-pin, phone, user, truck, bin, done, feedback, bell, chat, preferences, help, megaphone.

        Geef maximaal 3 acties. Houd de samenvatting beknopt en praktisch. \
        Schrijf in begrijpelijk Nederlands (B1 niveau). Gebruik "u" als aanspreekvorm.
        """

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 30

        var messages: [[String: String]] = conversationHistory
        messages.append(["role": "user", "content": question])

        let body: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 500,
            "system": systemPrompt,
            "messages": messages
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            let responseBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ClaudeError.apiError(statusCode: statusCode, message: responseBody)
        }

        return try parseResponse(data: data)
    }

    private func parseResponse(data: Data) throws -> RegelenAIResponse {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstBlock = content.first,
              let text = firstBlock["text"] as? String else {
            throw ClaudeError.parseError
        }

        // Extract JSON from the response text (Claude might wrap it in markdown)
        let jsonText = extractJSON(from: text)

        guard let jsonData = jsonText.data(using: .utf8),
              let parsed = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let samenvatting = parsed["samenvatting"] as? String else {
            throw ClaudeError.parseError
        }

        let isFollowUp = parsed["vervolgvraag"] as? Bool ?? false

        var actions: [RegelenAction] = []
        if !isFollowUp, let acties = parsed["acties"] as? [[String: Any]] {
            for actie in acties {
                if let titel = actie["titel"] as? String {
                    let icon = actie["icon"] as? String ?? "arrow-right"
                    actions.append(RegelenAction(icon: icon, title: titel))
                }
            }
        }

        return RegelenAIResponse(summary: samenvatting, actions: actions, isFollowUp: isFollowUp)
    }

    private func extractJSON(from text: String) -> String {
        // Try to find JSON block
        guard let startIndex = text.firstIndex(of: "{"),
              let endIndex = text.lastIndex(of: "}") else {
            return text
        }
        guard startIndex <= endIndex else { return text }
        return String(text[startIndex...endIndex])
    }
}

// MARK: - Errors

enum ClaudeError: LocalizedError {
    case apiError(statusCode: Int, message: String)
    case parseError

    var errorDescription: String? {
        switch self {
        case .apiError(let code, let message):
            return "API fout (\(code)): \(message)"
        case .parseError:
            return "Kon het antwoord niet verwerken"
        }
    }
}
