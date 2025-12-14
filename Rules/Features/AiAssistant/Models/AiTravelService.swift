import Foundation
import NaturalLanguage

// MARK: - Service responsible for communicating with Gemini API
actor AiTravelService {
    static let shared = AiTravelService()

    
    private let apiKey: String = {
        let raw = (Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String) ?? ""
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        // Protect against empty value or not-expanded xcconfig placeholder
        if value.isEmpty { return "" }
        if value.contains("$(") { return "" }

        return value
    }()
    // Gemini Developer API - generateContent endpoint (model: gemini-2.5-flash)
    private let endpoint = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent")!

    func send(prompt: String, history: [AiMessage]) async throws -> String {
        print("🔑 Gemini API key loaded:", apiKey.isEmpty ? "❌ EMPTY" : "✅ OK")
        guard !apiKey.isEmpty else {
            throw AiError.invalid
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // Language detection based on user's prompt
        let detectedLanguage: String = {
            if #available(iOS 12.0, *) {
                let recognizer = NLLanguageRecognizer()
                recognizer.processString(prompt)
                if let lang = recognizer.dominantLanguage {
                    return lang.rawValue   // e.g. "pl", "en", "es"
                }
            }
            return "en" // fallback
        }()

        // System prompt — AI wie, jak się zachowywać
        let systemContent = """
        You are SAM, an AI travel assistant inside a mobile app called Travel Rules.
        Your expertise is strictly limited to travel-related topics.

        You MUST focus only on topics related to transportation, trip planning, accommodation, safety, logistics and outdoor travel activities.
        DO NOT answer questions outside the travel domain.

        Allowed topics include (but are not limited to):
        - vanlife, campervans, RVs
        - motorhomes, caravans, camping trailers
        - tents, wild camping, campgrounds, parking spots
        - travel by: car, camper, motorcycle, bicycle, train, airplane, bus, ferry, hitchhiking, on foot
        - routes, itineraries, road conditions, distances, planning multi‑day trips
        - border crossings, toll roads, vignette systems, fuel planning
        - packing lists, checklists, essential gear, equipment maintenance
        - safety, weather preparation, emergency kits, first aid items
        - navigation apps, offline maps, GPS usage
        - budget travel, cost estimation, saving tips
        - accommodations: hotels, hostels, Airbnb, guesthouses, Booking, campgrounds, glamping
        - cooking while traveling, portable stoves, food storage
        - travel with pets
        - eco‑travel, sustainable solutions
        - ferries, cruises, island hopping
        - travel documentation, insurance, visas
        - photography while traveling, travel journaling
        - travel tips specific to European countries

        Absolutely forbidden topics:
        - politics, religion, finance, medicine, legal advice unrelated to travel
        - technology unrelated to travel
        - relationships or psychology
        - programming, math, science unrelated to travel
        - general chit‑chat outside travel context

        Your personality:
        - You are SAM: friendly, practical and highly knowledgeable.
        - Your answers must always be clear, structured and easy to read on a smartphone screen.
        - Always use headings, bullet points and step-by-step sections when helpful.
        - Use emojis sparingly to highlight main themes (e.g., ✈️ 🚐 🏕️ 🏨 🌍 ⚠️), but never overuse them.
        - When planning a trip, always provide:
          • structured daily itinerary
          • transportation tips
          • recommended accommodations (with direct links to Booking / Airbnb)
          • top-rated attractions with short descriptions
          • practical safety and budgeting advice
        - When asked about accommodation in a specific location:
          • provide 3–5 top-rated hotels or stays
          • include direct URLs (Booking or Airbnb)
          • mention why each option is recommended
        - When the user needs travel help (vanlife, car, train, plane, bus, ferry, hiking):
          • give concrete steps
          • include checklists
          • highlight important warnings or preparations
        - Avoid long paragraphs, complex jargon or filler text.
        - Your goal is to deliver quick, actionable, pleasant-to-read travel guidance.

        The user message language code is "\(detectedLanguage)".
        ALWAYS answer strictly in the same language as the user's message.
        If the user writes in Polish — answer in Polish.
        If the user writes in English — answer in English.
        If the user writes in Spanish — answer in Spanish.
        Do NOT translate unless the user explicitly asks.

        Be practical, concise and helpful.
        """

        // Historia czatu w formacie Gemini: role: user/model, parts: [ { text: ... } ]
        let historyContents: [[String: Any]] = history.map { msg in
            [
                "role": msg.isUser ? "user" : "model",
                "parts": [
                    ["text": msg.text]
                ]
            ]
        }

        let userContent: [String: Any] = [
            "role": "user",
            "parts": [
                ["text": prompt]
            ]
        ]

        let body: [String: Any] = [
            "systemInstruction": [
                "role": "system",
                "parts": [
                    ["text": systemContent]
                ]
            ],
            "contents": historyContents + [userContent],
            "generationConfig": [
                "temperature": 0.7
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpRes = response as? HTTPURLResponse else {
            throw AiError.invalid
        }

        // DEBUG (opcjonalnie):
        // print("Gemini status: \\(httpRes.statusCode)")
        // print(String(data: data, encoding: .utf8) ?? "no body")

        guard (200..<300).contains(httpRes.statusCode) else {
            throw AiError.httpError(httpRes.statusCode)
        }

        let decoded = try JSONDecoder().decode(GeminiGenerateContentResponse.self, from: data)

        guard
            let firstCandidate = decoded.candidates.first,
            let firstPart = firstCandidate.content.parts.first,
            let text = firstPart.text,
            !text.isEmpty
        else {
            throw AiError.empty
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Gemini response models

struct GeminiGenerateContentResponse: Decodable {
    struct Candidate: Decodable {
        struct Content: Decodable {
            struct Part: Decodable {
                let text: String?
            }
            let parts: [Part]
        }
        let content: Content
    }
    let candidates: [Candidate]
}

// MARK: - Error types

enum AiError: Error {
    case invalid
    case httpError(Int)
    case empty
}
