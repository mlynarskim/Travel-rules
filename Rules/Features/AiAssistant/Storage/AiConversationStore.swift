
import Foundation

final class AiConversationStore {

    private(set) var conversations: [AiConversation] = []

    private let fileURL: URL

    // MARK: - Init

    init() {
        let fm = FileManager.default

        // Prefer Application Support (not visible in Files app, better for app data)
        let appSupportDir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let bundleId = Bundle.main.bundleIdentifier ?? "TravelRules"
        let containerDir = appSupportDir.appendingPathComponent(bundleId, isDirectory: true)

        // Ensure directory exists
        if !fm.fileExists(atPath: containerDir.path) {
            try? fm.createDirectory(at: containerDir, withIntermediateDirectories: true)
        }

        let newURL = containerDir.appendingPathComponent("ai_conversations.json")
        self.fileURL = newURL

        // Migrate from old Documents location if needed
        migrateIfNeeded(from: fm)

        load()
    }

    // MARK: - Public API

    func lastConversation() -> AiConversation? {
        conversations.max(by: { $0.updatedAt < $1.updatedAt })
    }

    func conversation(with id: UUID) -> AiConversation? {
        conversations.first(where: { $0.id == id })
    }

    @discardableResult
    func createConversation(firstMessage: AiMessage) -> AiConversation {
        let now = Date()
        let conversation = AiConversation(
            id: UUID(),
            title: AiConversation.makeTitle(from: firstMessage.text),
            createdAt: now,
            updatedAt: now,
            messages: [firstMessage]
        )

        conversations.append(conversation)
        save()

        return conversation
    }

    func append(message: AiMessage, to conversationId: UUID) {
        guard let index = conversations.firstIndex(where: { $0.id == conversationId }) else { return }

        conversations[index].messages.append(message)
        conversations[index].updatedAt = Date()

        // Opcjonalnie: odśwież tytuł, jeśli rozmowa ma 1 wiadomość i pierwsza była krótka
        if conversations[index].messages.count == 1 {
            conversations[index].title = AiConversation.makeTitle(from: message.text)
        }

        save()
    }

    /// Usuń pojedynczą rozmowę i zapisz na dysku.
    func deleteConversation(id: UUID) {
        conversations.removeAll { $0.id == id }
        save()
    }

    /// Wyczyść wszystkie rozmowy i zapisz na dysku.
    func clearAll() {
        conversations.removeAll()
        // Usuń plik, żeby oszczędzić miejsce i uniknąć starych danych
        try? FileManager.default.removeItem(at: fileURL)
    }

    /// Wymuś przeładowanie z dysku (jeśli kiedyś będzie potrzebne).
    func reload() {
        load()
    }

    /// Publiczne `save()` – potrzebne, gdy UI modyfikuje `conversations` bezpośrednio.
    func save() {
        do {
            let encoder = JSONEncoder()
            // Stabilniejsze diffs i łatwiejszy debug (opcjonalnie)
            // encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(conversations)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            print("AiConversationStore: save error:", error)
        }
    }

    // MARK: - Persistence

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([AiConversation].self, from: data)
            self.conversations = decoded
        } catch {
            print("AiConversationStore: load error:", error)
        }
    }

    private func migrateIfNeeded(from fm: FileManager) {
        // Old location: Documents/ai_conversations.json
        let oldDir = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let oldURL = oldDir.appendingPathComponent("ai_conversations.json")

        guard fm.fileExists(atPath: oldURL.path) else { return }
        guard !fm.fileExists(atPath: fileURL.path) else {
            // Jeśli nowy plik już istnieje, usuń stary żeby nie dublować danych
            try? fm.removeItem(at: oldURL)
            return
        }

        do {
            try fm.moveItem(at: oldURL, to: fileURL)
        } catch {
            // Jeśli move się nie uda, spróbuj skopiować
            do {
                try fm.copyItem(at: oldURL, to: fileURL)
                try? fm.removeItem(at: oldURL)
            } catch {
                print("AiConversationStore: migrate error:", error)
            }
        }
    }
}
