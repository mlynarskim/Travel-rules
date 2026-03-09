import Foundation
import NaturalLanguage

// MARK: - Service responsible for communicating with Gemini API
actor AiTravelService {
    static let shared = AiTravelService()

    private let apiKey: String = {
        let raw = (Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String) ?? ""
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        if value.isEmpty { return "" }
        if value.contains("$(") { return "" }

        return value
    }()

    private let endpoint = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent")!

    static let demoModeKey = "ai_demo_mode"

    static var isDemoMode: Bool {
        get { UserDefaults.standard.bool(forKey: demoModeKey) }
        set { UserDefaults.standard.set(newValue, forKey: demoModeKey) }
    }

    private func demoResponse(languageCode: String, prompt: String) -> String {
        // Długi, markdownowy tekst do testowania: nagłówki, listy, linki, akapity.
        // Ważne: celowo zawiera sekcje + listy, żeby łatwo sprawdzić formatowanie i animacje.
        switch languageCode {
        case "pl":
            return """
            ## Plan (DEMO)

            Oto przykładowa odpowiedź testowa (bez API). Poniżej masz strukturę z akapitami, listami i linkami.

            ### 1) Szybkie pytania

            - **Kierunek:** gdzie jedziesz?
            - **Terminy:** kiedy start i ile dni?
            - **Styl:** budżet / komfort / mix

            ### 2) Propozycja wstępna

            1. Dzień 1: dojazd + lekki spacer
            2. Dzień 2: główna trasa (wcześnie rano)
            3. Dzień 3: plan B na złą pogodę

            ### 3) Checklista

            - Dokumenty
            - Woda + przekąski
            - Powerbank
            - Kurtka przeciwdeszczowa

            ### 4) Linki (test)

            - [Google Maps](https://www.google.com/maps)
            - [Booking](https://www.booking.com)
            - [Airbnb](https://www.airbnb.com)

            ---

            **Twoje zapytanie (DEMO):** \(prompt)
            """
        case "es":
            return """
            ## Plan (DEMO)

            Esta es una respuesta de prueba (sin API). Incluye párrafos, listas y enlaces.

            ### 1) Preguntas rápidas

            - **Destino:** ¿a dónde vas?
            - **Fechas:** ¿cuándo y cuántos días?
            - **Estilo:** presupuesto / comodidad / mixto

            ### 2) Propuesta inicial

            1. Día 1: llegada + paseo corto
            2. Día 2: ruta principal (temprano)
            3. Día 3: plan B si llueve

            ### 3) Checklist

            - Documentos
            - Agua + snacks
            - Power bank
            - Chaqueta impermeable

            ### 4) Enlaces (test)

            - [Google Maps](https://www.google.com/maps)
            - [Booking](https://www.booking.com)
            - [Airbnb](https://www.airbnb.com)

            ---

            **Tu mensaje (DEMO):** \(prompt)
            """
        default:
            return """
            ## 3-Day Spain City Break 

            Here’s a clean, easy plan you can follow without overthinking — perfect for a short trip.

            ### Day 1 — Arrival + Old Town
            1. Check-in and drop bags
            2. Walk the historic center (easy pace)
            3. Sunset viewpoint + dinner

            ### Day 2 — Highlights + Local Food
            1. Main sights in the morning (avoid crowds)
            2. Lunch in a local market
            3. Relaxing afternoon: park / beach / museum
            4. Evening: tapas route (2–3 spots)

            ### Day 3 — Slow Morning + Departure
            1. Coffee + quick souvenir stop
            2. Short walk (30–60 min)
            3. Head to the airport with buffer time

            ## Transport
            - Use public transport for the center (fast + cheap)
            - If renting a car: check parking rules and toll roads
            - Keep offline maps in case of poor signal

            ## Stays (examples)
            - Central hotel (walk everywhere)
            - Quiet apartment (better sleep)
            - Budget hostel (great for short stays)

            ## Quick Checklist
            - Passport/ID + travel insurance
            - Power bank + charging cable
            - Light rain jacket (weather changes fast)
            - Small daypack + reusable water bottle

            ## Next step
            Tell me your city (Barcelona / Valencia / Málaga / Madrid) and your budget — I’ll tailor the exact routes and timing.

            **Your prompt (DEMO):** \(prompt)
            """
        }
    }

    func send(prompt: String, history: [AiMessage]) async throws -> String {
        let detectedLanguage: String = {
            let recognizer = NLLanguageRecognizer()
            recognizer.processString(prompt)
            return recognizer.dominantLanguage?.rawValue ?? "en"
        }()

        if Self.isDemoMode {
            return normalizeAssistantText(demoResponse(languageCode: detectedLanguage, prompt: prompt))
        }

        guard !apiKey.isEmpty else {
            throw AiError.invalid
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let systemContent = """
        You are SAM, a travel assistant in the Travel Rules mobile app.
        ONLY answer travel-related questions (trips, accommodation, transport, packing, camping, vanlife, border crossings, visas, budget, routes).
        Refuse anything off-topic with: "I can only help with travel topics."

        RESPONSE LENGTH — CRITICAL:
        - Keep answers SHORT and SCANNABLE on a phone screen.
        - Max ~250 words total. If more is needed, summarise and offer to expand.
        - Use at most 2-3 sections per answer.
        - Never repeat yourself.

        FORMATTING:
        - Markdown only: ## headings, - bullets, 1. numbered, **bold** key terms.
        - Blank line before/after every heading and list.
        - Links: [Label](https://url) — one per line. Use real, working booking/maps links where possible.
        - End sentences with proper punctuation.

        FOR TRIP PLANNING use this structure (max 3 sections):

        ## Plan
        Day-by-day or step-by-step (brief).

        ## Stay & Transport
        2-3 accommodation links + main transport tip.

        ## Tips
        Top 3 practical points only.

        FOR SIMPLE QUESTIONS (one topic):
        Answer directly in 3-6 bullet points or 2-3 short paragraphs. No sections needed.

        Language: detect from user message and reply in the SAME language (Polish/English/Spanish/other).
        User language code: "\(detectedLanguage)".
        """

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
                "temperature": 0.7,
                "maxOutputTokens": 600
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpRes = response as? HTTPURLResponse else {
            throw AiError.invalid
        }

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

        let normalized = normalizeAssistantText(text)

        return normalized
    }

    private func normalizeAssistantText(_ input: String) -> String {
        var text = input.replacingOccurrences(of: "\r\n", with: "\n")
        
        // 1. Naprawa sklejonych zdań: "Spain?For" -> "Spain? For"
        if let regex = try? NSRegularExpression(pattern: "([.!?])([A-ZŁŚĆŻŹĄĘŃ])", options: []) {
            let range = NSRange(text.startIndex..., in: text)
            text = regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "$1 $2")
        }
        
        // 2. Usuń nadmiarowe puste linie (max 2 nowe linie z rzędu)
        while text.contains("\n\n\n") {
            text = text.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }
        
        // 3. Upewnij się, że nagłówki mają pustą linię przed sobą (jeśli jej nie ma)
        if let regex = try? NSRegularExpression(pattern: "([^\n])(\n)(#{1,3} )", options: []) {
            let range = NSRange(text.startIndex..., in: text)
            text = regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "$1\n\n$3")
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
