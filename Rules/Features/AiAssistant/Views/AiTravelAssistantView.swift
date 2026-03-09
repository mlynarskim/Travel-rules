//AiTravelAssistantView.swift

import Foundation
import SwiftUI
import UIKit
import AVFoundation
import Speech
import Combine

struct AiMessage: Identifiable, Hashable, Codable {
    let id: UUID
    let text: String
    let isUser: Bool

    init(id: UUID = UUID(), text: String, isUser: Bool) {
        self.id = id
        self.text = text
        self.isUser = isUser
    }
}

#Preview {
    NavigationStack {
        AiTravelAssistantView()
    }
}

struct AiTravelAssistantView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedTheme") private var selectedTheme = ThemeStyle.classic.rawValue
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("ai_sam_welcome_shown") private var hasShownSamWelcome = false
    @AppStorage("selectedLanguage") private var selectedLanguage = "pl"
    @FocusState private var isInputFocused: Bool
    @State private var keyboardInset: CGFloat = 0

    @State private var welcomeText: String? = nil
    @State private var isWelcomeLoading: Bool = false

    @State private var userInput: String = ""
    @State private var messages: [AiMessage] = []
    @State private var isLoading: Bool = false
    @State private var promptHistory: [String] = []
    @State private var isHistoryVisible: Bool = false
    @State private var conversationsSnapshot: [AiConversation] = []

    @State private var showClearAllHistoryAlert: Bool = false
    @State private var deleteHistoryTarget: HistoryDeleteTarget?
    @State private var historySheetDragOffset: CGFloat = 0

    // Scroll helpers (żeby ostatnia wiadomość nie chowała się pod input barem)
    private let bottomSpacerId: String = "bottom-spacer"
    @State private var inputBarHeight: CGFloat = 0

    private enum ScrollRequest: Equatable {
        case bottom
        case messageTop(UUID)
    }
    @State private var scrollRequest: ScrollRequest? = nil

    // Rotacja przykładowych pytań (pokazujemy tylko 3 i zmieniamy co 10s)
    @State private var exampleRotationIndex: Int = 0
    private let exampleRotationTimer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()

    // Zapamiętaj ostatnie powitanie, żeby nie powtarzać tego samego pod rząd
    @AppStorage("ai_last_welcome_key") private var lastWelcomeKey: String = ""

    private let promptHistoryKey = "aiPromptHistory"
    private let examplePromptKeys: [String] = [
        "ai_example_plan_spain",
        "ai_example_checklist_mountains",
        "ai_example_free_spots_europe",
        "ai_example_plan_spain",
        "ai_example_checklist_mountains",
        "ai_example_free_spots_europe",
        "ai_example_mountain_trip",
        "ai_example_plane_packing",
        "ai_example_cheapest_flights",
        "ai_example_pretrip_checklist",
        "ai_example_weekend_trip",
        "ai_example_roadtrip_plan",
        "ai_example_camper_sleep_spots",
        "ai_example_budget_travel",
        "ai_example_documents_check",
    ]

    private var uniqueExamplePromptKeys: [String] {
        var seen = Set<String>()
        var result: [String] = []
        for k in examplePromptKeys {
            if seen.insert(k).inserted {
                result.append(k)
            }
        }
        return result
    }

    private var visibleExamplePromptKeys: [String] {
        let keys = uniqueExamplePromptKeys
        guard !keys.isEmpty else { return [] }
        let count = min(3, keys.count)
        return (0..<count).map { i in
            keys[(exampleRotationIndex + i) % keys.count]
        }
    }

    private var exampleQuestionsTitle: String {
        switch selectedLanguage {
        case "pl": return "Przykładowe pytania"
        case "es": return "Preguntas de ejemplo"
        default: return "Example questions"
        }
    }

    private let welcomeMessageKeys: [String] = [
        "ai_sam_welcome_1",
        "ai_sam_welcome_2",
        "ai_sam_welcome_3",
        "ai_sam_welcome_4",
        "ai_sam_welcome_5",
        "ai_sam_welcome_6"
    ]

    /// Store rozmów – lokalna historia
    private let conversationStore = AiConversationStore()
    @State private var currentConversationId: UUID?

    // Animacja „pisania” odpowiedzi AI (treść pojawia się stopniowo)
    @State private var animatedAssistantText: [UUID: String] = [:]
    @State private var typingTasks: [UUID: Task<Void, Never>] = [:]

    private var themeColors: ThemeColors {
        switch ThemeStyle(rawValue: selectedTheme) ?? .classic {
        case .classic:  return ThemeColors.classicTheme
        case .mountain: return ThemeColors.mountainTheme
        case .beach:    return ThemeColors.beachTheme
        case .desert:   return ThemeColors.desertTheme
        case .forest:   return ThemeColors.forestTheme
        case .autumn:   return ThemeColors.autumnTheme
        case .winter:   return ThemeColors.winterTheme
        case .spring:   return ThemeColors.springTheme
        case .summer:   return ThemeColors.summerTheme
        }
    }

    private var isSmallPhone: Bool {
        UIScreen.main.bounds.width < 360
    }

    private var localizedWelcomeMessages: Set<String> {
        Set(welcomeMessageKeys.map { $0.appLocalized })
    }

    private var firstWelcomeText: String? {
        guard let first = messages.first, first.isUser == false else { return nil }
        return localizedWelcomeMessages.contains(first.text) ? first.text : nil
    }

    private var displayedMessages: [AiMessage] {
        if firstWelcomeText != nil {
            return Array(messages.dropFirst())
        }
        return messages
    }

    @MainActor
    private func requestScrollToBottom() {
        scrollRequest = .bottom
    }

    var body: some View {
        ZStack {
            Image(isDarkMode ? themeColors.darkBackground : themeColors.background)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                chatList
            }
        }
        .navigationTitle(Text("ai_travel_title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    startNewConversation()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                }
                .accessibilityLabel(Text("ai_new_conversation".appLocalized))
            }
        }
        .gesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                .onEnded { value in
                    if value.startLocation.x < 24 && value.translation.width > 90 && abs(value.translation.height) < 60 {
                        dismiss()
                    }
                }
        )
        .safeAreaInset(edge: .bottom, spacing: 0) {
            inputBar
                .padding(.bottom, keyboardInset)
                .animation(.easeOut(duration: 0.22), value: keyboardInset)
        }
        .onAppear {
            loadPromptHistory()
            loadLastConversation()
            conversationsSnapshot = conversationStore.conversations
            showWelcomeIfNeeded()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                Task { @MainActor in
                    requestScrollToBottom()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { note in
            guard let endFrame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            updateKeyboardInset(endFrame)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.22)) {
                keyboardInset = 0
            }
        }
        .onChange(of: keyboardInset) { _, newValue in
            guard newValue > 0, isInputFocused else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                Task { @MainActor in
                    requestScrollToBottom()
                }
            }
        }
        .overlay {
            if isHistoryVisible {
                historyPanel
                    .transition(.move(edge: .bottom))
            }
        }
        .animation(.interactiveSpring(response: 0.38, dampingFraction: 0.86, blendDuration: 0.15), value: isHistoryVisible)
        .onReceive(exampleRotationTimer) { _ in
            rotateExamplePromptsIfNeeded()
        }
        .onDisappear {
            Task { @MainActor in
                cancelAllTypingTasks()
            }
        }
        .id(selectedLanguage)
    }

    // MARK: - Historia (alerty)
    private enum HistoryDeleteTarget: Identifiable {
        case conversation(AiConversation)
        case prompt(String)

        var id: String {
            switch self {
            case .conversation(let conv):
                return "conv-\(conv.id.uuidString)"
            case .prompt(let prompt):
                return "prompt-\(prompt)"
            }
        }

        var titleKey: String {
            switch self {
            case .conversation:
                return "ai_history_delete_conversation_title"
            case .prompt:
                return "ai_history_delete_prompt_title"
            }
        }

        var messageKey: String {
            return "ai_history_delete_irreversible"
        }
    }

    private func updateKeyboardInset(_ endFrame: CGRect) {
        let screenHeight = UIScreen.main.bounds.height
        let overlap = max(0, screenHeight - endFrame.minY)
        let bottomSafe = UIApplication.shared.trKeyWindow?.safeAreaInsets.bottom ?? 0
        let inset = max(0, overlap - bottomSafe)

        withAnimation(.easeOut(duration: 0.22)) {
            keyboardInset = inset
        }
    }

    // MARK: - Lista wiadomości

    private var chatList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    if firstWelcomeText != nil {
                        welcomeBanner
                    }

                    ForEach(displayedMessages) { message in
                        messageRow(message)
                            .id(message.id)
                    }

                    if isLoading {
                        typingIndicator
                            .id("typing-indicator")
                    }

                    if messages.isEmpty {
                        welcomeBanner
                    }

                    Color.clear
                        .frame(height: max(16, inputBarHeight + keyboardInset + 16))
                        .id(bottomSpacerId)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 16)
            }
            .onChange(of: scrollRequest) { _, _ in
                guard let req = scrollRequest else { return }

                switch req {
                case .bottom:
                    withAnimation(.easeOut(duration: 0.18)) {
                        proxy.scrollTo(bottomSpacerId, anchor: .bottom)
                    }
                case .messageTop(let id):
                    withAnimation(.easeInOut(duration: 0.28)) {
                        proxy.scrollTo(id, anchor: .top)
                    }
                }

                DispatchQueue.main.async {
                    scrollRequest = nil
                }
            }
        }
        .onTapGesture {
            isInputFocused = false
        }
    }

    private var welcomeBanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isWelcomeLoading {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("ai_travel_title")
                        .font(.subheadline)
                        .foregroundColor(themeColors.primaryText)
                }
            }

            if let text = firstWelcomeText ?? welcomeText {
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(themeColors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text((welcomeMessageKeys.first ?? "ai_sam_welcome_1").appLocalized)
                    .font(.subheadline)
                    .foregroundColor(themeColors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(exampleQuestionsTitle)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(themeColors.primaryText)

            ForEach(visibleExamplePromptKeys, id: \.self) { key in
                Button {
                    userInput = key.appLocalized
                    isInputFocused = true
                } label: {
                    Text(key.appLocalized)
                        .font(.subheadline)
                        .foregroundColor(themeColors.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(themeColors.cardBackground.opacity(0.92))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(themeColors.cardShadow.opacity(0.22), lineWidth: 1)
                        )
                        .transition(.opacity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 14)
        .background(themeColors.cardBackground.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: themeColors.cardShadow.opacity(0.35), radius: 8, x: 0, y: 4)
        .padding(.top, 4)
    }

    // MARK: - History panel (bez zmian)
    private var historyPanel: some View {
        GeometryReader { geo in
            let sheetHeight = min(geo.size.height * 0.86, 760)
            let isWidePhone = geo.size.width >= 390
            let sheetWidth: CGFloat = isWidePhone ? min(geo.size.width - 28, 380) : geo.size.width
            let sidePadding: CGFloat = 22

            ZStack(alignment: .bottom) {
                Color.black.opacity(0.22)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.interactiveSpring(response: 0.38, dampingFraction: 0.86, blendDuration: 0.15)) {
                            isHistoryVisible = false
                            historySheetDragOffset = 0
                        }
                    }

                VStack(alignment: .leading, spacing: 0) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.35))
                        .frame(width: 44, height: 5)
                        .padding(.top, 10)
                        .padding(.bottom, 10)
                        .frame(maxWidth: .infinity)

                    HStack(spacing: 12) {
                        Text("ai_history_title".appLocalized)
                            .font(.headline)

                        Spacer()

                        // Demo / API toggle
                        Button {
                            AiTravelService.isDemoMode.toggle()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: AiTravelService.isDemoMode ? "flask.fill" : "network")
                                    .font(.system(size: 12, weight: .semibold))
                                Text(AiTravelService.isDemoMode ? "DEMO" : "API")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundColor(AiTravelService.isDemoMode ? .orange : themeColors.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                (AiTravelService.isDemoMode ? Color.orange : themeColors.primary).opacity(0.12)
                            )
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        Button {
                            showClearAllHistoryAlert = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .buttonStyle(.plain)

                        Button {
                            isHistoryVisible = false
                            historySheetDragOffset = 0
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, sidePadding)
                    .padding(.bottom, 10)

                    Divider()

                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            if conversationsSnapshot.isEmpty && promptHistory.isEmpty {
                                Text("ai_history_empty".appLocalized)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 24)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }

                            if !conversationsSnapshot.isEmpty {
                                Text("ai_history_conversations".appLocalized)
                                    .font(.subheadline.weight(.semibold))
                                    .padding(.top, 8)

                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(conversationsSnapshot.sorted(by: { $0.updatedAt > $1.updatedAt })) { conv in
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(conv.title)
                                                .font(.body)
                                                .lineLimit(2)

                                            Text(conv.updatedAt, style: .date)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 14)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(themeColors.cardBackground.opacity(0.96))
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .stroke(themeColors.cardShadow.opacity(0.18), lineWidth: 1)
                                        )
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            currentConversationId = conv.id
                                            messages = conv.messages
                                            isHistoryVisible = false
                                            historySheetDragOffset = 0

                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                                                Task { @MainActor in
                                                    requestScrollToBottom()
                                                }
                                            }
                                        }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                deleteHistoryTarget = .conversation(conv)
                                            } label: {
                                                Label("ai_delete".appLocalized, systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                            }

                            if !promptHistory.isEmpty {
                                Text("ai_history_recent_prompts".appLocalized)
                                    .font(.subheadline.weight(.semibold))
                                    .padding(.top, 8)

                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(promptHistory, id: \.self) { item in
                                        Text(item)
                                            .font(.subheadline)
                                            .lineLimit(3)
                                            .padding(.vertical, 12)
                                            .padding(.horizontal, 14)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(themeColors.cardBackground.opacity(0.96))
                                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                    .stroke(themeColors.cardShadow.opacity(0.18), lineWidth: 1)
                                            )
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                userInput = item
                                                isInputFocused = true
                                                isHistoryVisible = false
                                                historySheetDragOffset = 0
                                            }
                                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                                Button(role: .destructive) {
                                                    deleteHistoryTarget = .prompt(item)
                                                } label: {
                                                    Label("ai_delete".appLocalized, systemImage: "trash")
                                                }
                                            }
                                    }
                                }
                            }

                            Spacer(minLength: 28)
                        }
                        .padding(.horizontal, sidePadding)
                        .padding(.bottom, max(geo.safeAreaInsets.bottom, 16))
                        .padding(.top, 12)
                    }
                }
                .frame(width: sheetWidth)
                .frame(height: sheetHeight)
                .background(themeColors.cardBackground.opacity(0.98))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: Color.black.opacity(0.18), radius: 18, x: 0, y: -6)
                .offset(y: max(0, historySheetDragOffset))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.height > 0 {
                                historySheetDragOffset = value.translation.height
                            }
                        }
                        .onEnded { value in
                            if value.translation.height > 120 {
                                withAnimation(.interactiveSpring(response: 0.38, dampingFraction: 0.86, blendDuration: 0.15)) {
                                    isHistoryVisible = false
                                    historySheetDragOffset = 0
                                }
                            } else {
                                withAnimation(.interactiveSpring(response: 0.38, dampingFraction: 0.86, blendDuration: 0.15)) {
                                    historySheetDragOffset = 0
                                }
                            }
                        }
                )
                .alert("ai_history_clear_all_title".appLocalized, isPresented: $showClearAllHistoryAlert) {
                    Button("ai_cancel".appLocalized, role: .cancel) {}
                    Button("ai_clear".appLocalized, role: .destructive) {
                        clearAllHistory()
                        isHistoryVisible = false
                        historySheetDragOffset = 0
                    }
                } message: {
                    Text("ai_history_clear_all_message".appLocalized)
                }
                .alert(item: $deleteHistoryTarget) { target in
                    Alert(
                        title: Text(target.titleKey.appLocalized),
                        message: Text(target.messageKey.appLocalized),
                        primaryButton: .destructive(Text("ai_delete".appLocalized)) {
                            switch target {
                            case .conversation(let conv):
                                deleteConversation(conv)
                            case .prompt(let prompt):
                                deletePrompt(prompt)
                            }
                        },
                        secondaryButton: .cancel(Text("ai_cancel".appLocalized))
                    )
                }
            }
        }
    }

    @State private var dot1 = false
    @State private var dot2 = false
    @State private var dot3 = false
    private var typingIndicator: some View {
        HStack(alignment: .top, spacing: 0) {
            HStack(spacing: 6) {
                Circle()
                    .frame(width: 8, height: 8)
                    .foregroundColor(themeColors.primary)
                    .scaleEffect(dot1 ? 1 : 0.4)
                    .animation(.easeInOut(duration: 0.6).repeatForever(), value: dot1)

                Circle()
                    .frame(width: 8, height: 8)
                    .foregroundColor(themeColors.primary)
                    .scaleEffect(dot2 ? 1 : 0.4)
                    .animation(.easeInOut(duration: 0.6).repeatForever().delay(0.2), value: dot2)

                Circle()
                    .frame(width: 8, height: 8)
                    .foregroundColor(themeColors.primary)
                    .scaleEffect(dot3 ? 1 : 0.4)
                    .animation(.easeInOut(duration: 0.6).repeatForever().delay(0.4), value: dot3)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(themeColors.cardBackground.opacity(0.95))
            .cornerRadius(16)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .onAppear {
            dot1 = true
            dot2 = true
            dot3 = true
        }
        .transition(.opacity)
    }

    // MARK: - Markdown rendering (UPROSZCZONE)

    private func markdownText(_ text: String) -> Text {
        if #available(iOS 15.0, *) {
            if let attributed = try? AttributedString(
                markdown: text,
                options: AttributedString.MarkdownParsingOptions(
                    interpretedSyntax: .inlineOnlyPreservingWhitespace
                )
            ) {
                return Text(attributed)
            }
        }
        return Text(text)
    }

    private func messageRow(_ msg: AiMessage) -> some View {
        HStack(alignment: .top, spacing: 0) {
            if msg.isUser {
                Spacer(minLength: 0)
                bubble(for: msg)
            } else {
                bubble(for: msg)
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 12)
    }

    private func bubble(for msg: AiMessage) -> some View {
        let isAnimatingAssistant = (!msg.isUser) && (animatedAssistantText[msg.id] != nil)

        return Group {
            if isAnimatingAssistant, let partial = animatedAssistantText[msg.id] {
                Text(partial)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                markdownText(msg.text)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            msg.isUser
            ? themeColors.primary
            : themeColors.cardBackground.opacity(0.97)
        )
        .foregroundColor(msg.isUser ? themeColors.lightText : themeColors.primaryText)
        .textSelection(.enabled)
        .tint(themeColors.secondary)
        .cornerRadius(18)
        .shadow(color: themeColors.cardShadow, radius: 4, x: 0, y: 2)
        .frame(
            maxWidth: UIScreen.main.bounds.width * (msg.isUser ? 0.78 : 0.92),
            alignment: msg.isUser ? .trailing : .leading
        )
    }

    // MARK: - Input bar (bez przycisku przewijania)

    private var inputBar: some View {
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                Button {
                    historySheetDragOffset = 0
                    isHistoryVisible.toggle()
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(themeColors.primaryText)
                        .frame(width: 34, height: 34)
                        .background(themeColors.cardBackground.opacity(0.92))
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(themeColors.cardShadow.opacity(0.20), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                Button {
                    toggleSpeechRecognition()
                } label: {
                    Image(systemName: isRecording ? "mic.fill" : "mic")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isRecording ? .red : themeColors.primaryText)
                        .frame(width: 34, height: 34)
                        .background(themeColors.cardBackground.opacity(0.92))
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(themeColors.cardShadow.opacity(0.20), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(themeColors.cardBackground.opacity(0.92))
                        .frame(height: 46)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(themeColors.cardShadow.opacity(0.18), lineWidth: 1)
                        )

                    HStack(spacing: 0) {
                        TextField(String(localized: "ai_travel_placeholder", table: "Localizable"), text: $userInput)
                            .padding(.leading, 14)
                            .padding(.trailing, 4)
                            .foregroundColor(themeColors.primaryText)
                            .focused($isInputFocused)
                            .submitLabel(.send)
                            .tint(themeColors.secondary)
                            .onSubmit { Task { await sendMessage() } }

                        Button {
                            Task { await sendMessage() }
                        } label: {
                            Image(systemName: userInput.trimmingCharacters(in: .whitespaces).isEmpty ? "arrow.up.circle" : "arrow.up.circle.fill")
                                .font(.system(size: 26))
                                .foregroundColor(userInput.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? themeColors.primaryText.opacity(0.3)
                                    : themeColors.primary)
                                .padding(.trailing, 8)
                        }
                        .buttonStyle(.plain)
                        .disabled(userInput.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, isSmallPhone ? 12 : 20)
            .padding(.top, 10)
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity)
            .background(
                themeColors.cardBackground
                    .opacity(isDarkMode ? 0.88 : 0.94)
                    .ignoresSafeArea(edges: .bottom)
            )
        }
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { inputBarHeight = geo.size.height }
                    .onChange(of: geo.size.height) { _, newValue in
                        inputBarHeight = newValue
                    }
            }
        )
    }

    // MARK: - Wysyłanie wiadomości + rozmowy

    @MainActor
    private func sendMessage() async {
        let prompt = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }

        addToHistory(prompt)
        userInput = ""
        appendMessage(prompt, isUser: true)
        isLoading = true

        do {
            let response = try await AiTravelService.shared.send(
                prompt: prompt,
                history: messages
            )
            appendMessage(response, isUser: false)
        } catch {
            appendMessage(
                String(localized: "ai_travel_error", table: "Localizable"),
                isUser: false
            )
        }

        isLoading = false
        isInputFocused = false
    }

    @MainActor
    private func appendMessage(_ text: String, isUser: Bool) {
        let message = AiMessage(text: text, isUser: isUser)
        withAnimation(.easeOut(duration: 0.18)) {
            messages.append(message)
        }

        if let id = currentConversationId {
            conversationStore.append(message: message, to: id)
        } else {

            if isUser {
                let conversation = conversationStore.createConversation(firstMessage: message)
                currentConversationId = conversation.id
            }
        }

        conversationsSnapshot = conversationStore.conversations

        if isUser {
            requestScrollToBottom()
        } else {

            startAssistantTypewriterIfNeeded(for: message)
            DispatchQueue.main.async {
                scrollRequest = .messageTop(message.id)
            }
        }
    }

    @MainActor
    private func loadLastConversation() {
        if let last = conversationStore.lastConversation() {
            currentConversationId = last.id
            messages = last.messages
        }
    }

    @MainActor
    private func showWelcomeIfNeeded() {
        guard !hasShownSamWelcome else { return }

        if !messages.isEmpty {
            hasShownSamWelcome = true
            return
        }
        
        let welcome = makeRandomWelcomeMessage()
        messages = [welcome]
        currentConversationId = nil
        conversationsSnapshot = conversationStore.conversations

        hasShownSamWelcome = true
    }

    @MainActor
    private func makeRandomWelcomeMessage() -> AiMessage {
        let keys = welcomeMessageKeys
        guard !keys.isEmpty else {
            return AiMessage(text: "ai_sam_welcome_1".appLocalized, isUser: false)
        }

        var key = keys.randomElement() ?? "ai_sam_welcome_1"
        if keys.count > 1 {
            var attempts = 0
            while key == lastWelcomeKey && attempts < 8 {
                key = keys.randomElement() ?? key
                attempts += 1
            }
        }

        lastWelcomeKey = key
        return AiMessage(text: key.appLocalized, isUser: false)
    }

    @MainActor
    private func rotateExamplePromptsIfNeeded() {
        guard displayedMessages.isEmpty else { return }

        let keys = uniqueExamplePromptKeys
        guard keys.count > 3 else { return }
        withAnimation(.easeInOut(duration: 0.35)) {
            exampleRotationIndex = (exampleRotationIndex + 1) % keys.count
        }
    }

    private func startNewConversation() {
        currentConversationId = nil
        messages = []
        userInput = ""
        conversationsSnapshot = conversationStore.conversations

        Task { @MainActor in
            cancelAllTypingTasks()
            let welcome = makeRandomWelcomeMessage()
            messages = [welcome]
            currentConversationId = nil
            conversationsSnapshot = conversationStore.conversations
            requestScrollToBottom()
        }
    }

    // MARK: - Usuwanie historii

    private func deleteConversation(_ conv: AiConversation) {
        conversationStore.deleteConversation(id: conv.id)
        conversationsSnapshot = conversationStore.conversations

        if currentConversationId == conv.id {
            currentConversationId = nil
            messages = []
        }
    }

    private func deletePrompt(_ prompt: String) {
        if let index = promptHistory.firstIndex(of: prompt) {
            promptHistory.remove(at: index)
            savePromptHistory()
        }
    }

    private func clearAllHistory() {
        conversationStore.clearAll()
        conversationsSnapshot.removeAll()
        currentConversationId = nil
        messages = []

        promptHistory.removeAll()
        savePromptHistory()
    }

    // MARK: - Historia promptów

    private func loadPromptHistory() {
        if let data = UserDefaults.standard.data(forKey: promptHistoryKey),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            promptHistory = decoded
        }
    }

    private func savePromptHistory() {
        if let data = try? JSONEncoder().encode(promptHistory) {
            UserDefaults.standard.set(data, forKey: promptHistoryKey)
        }
    }

    private func addToHistory(_ prompt: String) {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let index = promptHistory.firstIndex(of: trimmed) {
            promptHistory.remove(at: index)
        }

        promptHistory.insert(trimmed, at: 0)

        if promptHistory.count > 10 {
            promptHistory = Array(promptHistory.prefix(10))
        }

        savePromptHistory()
    }

    // MARK: - Typewriter (animacja treści odpowiedzi AI)

    @MainActor
    private func startAssistantTypewriterIfNeeded(for message: AiMessage) {
        guard !message.isUser else { return }

        let displayText = plainTextForTypewriter(from: message.text)

        // Dla bardzo krótkich odpowiedzi – pomiń animację
        guard displayText.count >= 30 else {
            animatedAssistantText.removeValue(forKey: message.id)
            return
        }

        typingTasks[message.id]?.cancel()
        typingTasks.removeValue(forKey: message.id)

        animatedAssistantText[message.id] = ""

        let id = message.id
        let chars = Array(displayText)
        let total = chars.count

        let step = total > 1200 ? 6 : (total > 600 ? 4 : 2)
        let delayNs: UInt64 = 18_000_000 // ~18ms

        let task = Task {
            var i = 0
            while i < total {
                if Task.isCancelled { break }
                let next = min(total, i + step)
                let partial = String(chars[0..<next])

                await MainActor.run {
                    animatedAssistantText[id] = partial
                }

                i = next
                try? await Task.sleep(nanoseconds: delayNs)
            }

            await MainActor.run {
                animatedAssistantText.removeValue(forKey: id)
                typingTasks.removeValue(forKey: id)
            }
        }

        typingTasks[id] = task
    }

    @MainActor
    private func cancelAllTypingTasks() {
        for (_, t) in typingTasks {
            t.cancel()
        }
        typingTasks.removeAll()
        animatedAssistantText.removeAll()
    }

    private func plainTextForTypewriter(from markdown: String) -> String {
        var s = markdown.replacingOccurrences(of: "\r\n", with: "\n")

        // Usuń nagłówki markdown (### ) na początku linii
        if let re = try? NSRegularExpression(pattern: "(?m)^(#{1,6})\\s+", options: []) {
            let range = NSRange(s.startIndex..<s.endIndex, in: s)
            s = re.stringByReplacingMatches(in: s, options: [], range: range, withTemplate: "")
        }

        s = s.replacingOccurrences(of: "**", with: "")
        s = s.replacingOccurrences(of: "__", with: "")
        s = s.replacingOccurrences(of: "`", with: "")

        if let re = try? NSRegularExpression(pattern: "\\[([^\\]]+)\\]\\((https?:\\/\\/[^\\)]+)\\)", options: []) {
            let range = NSRange(s.startIndex..<s.endIndex, in: s)
            s = re.stringByReplacingMatches(in: s, options: [], range: range, withTemplate: "$1 ($2)")
        }

        s = s.replacingOccurrences(of: "```", with: "")

        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Mowa (mikrofon)

    @State private var isRecording = false
    @State private var speechRecognizer = SFSpeechRecognizer()
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    private func toggleSpeechRecognition() {
        if isRecording {
            stopRecording()
            isRecording = false
            return
        }

        isRecording = true
        startRecording()
    }

    private func startRecording() {
        SFSpeechRecognizer.requestAuthorization { _ in }

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .allowBluetoothHFP, .defaultToSpeaker])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            stopRecording()
            isRecording = false
            return
        }

        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)

        let inputFormat = inputNode.inputFormat(forBus: 0)
        guard inputFormat.sampleRate > 0, inputFormat.channelCount > 0 else {
            stopRecording()
            isRecording = false
            return
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            stopRecording()
            isRecording = false
            return
        }

        recognitionTask = speechRecognizer?.recognitionTask(with: request) { result, error in
            if let res = result {
                DispatchQueue.main.async {
                    userInput = res.bestTranscription.formattedString
                }
            }

            if error != nil || (result?.isFinal ?? false) {
                DispatchQueue.main.async {
                    stopRecording()
                    isRecording = false
                }
            }
        }
    }

    private func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)

        recognitionRequest?.endAudio()
        recognitionRequest = nil

        recognitionTask?.cancel()
        recognitionTask = nil

        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch { }
    }
}

private extension UIApplication {
    var trKeyWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}
