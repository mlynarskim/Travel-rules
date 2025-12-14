//
//  AiConversation.swift
//
import Foundation

struct AiConversation: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var messages: [AiMessage]
}

extension AiConversation {
    /// Tytuł na podstawie pierwszej wiadomości
    static func makeTitle(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Nowa rozmowa" }

        if trimmed.count <= 40 {
            return trimmed
        } else {
            let prefix = trimmed.prefix(40)
            return prefix + "…"
        }
    }
}
