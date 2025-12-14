import SwiftUI
import UIKit
import AVFoundation
import Speech

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
    @FocusState private var isInputFocused: Bool

    @State private var userInput: String = ""
    @State private var messages: [AiMessage] = []
    @State private var isLoading: Bool = false
    @State private var promptHistory: [String] = []
    @State private var isHistoryVisible: Bool = false
    @State private var conversationsSnapshot: [AiConversation] = []

    // Alerty i akcje historii
    @State private var showClearAllHistoryAlert: Bool = false
    @State private var deleteHistoryTarget: HistoryDeleteTarget?
    @State private var historySheetDragOffset: CGFloat = 0

    // Keyboard fallback inset (when automatic avoidance is disabled by a parent)
    @State private var keyboardInset: CGFloat = 0

    private let promptHistoryKey = "aiPromptHistory"
    private let examplePromptKeys: [String] = [
        "ai_example_plan_spain",
        "ai_example_checklist_mountains",
        "ai_example_free_spots_europe"
    ]

    /// Store rozmów – lokalna historia
    private let conversationStore = AiConversationStore()
    @State private var currentConversationId: UUID?

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
                .accessibilityLabel(Text("Nowa rozmowa"))
            }
        }
        .gesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                .onEnded { value in
                    // Edge-swipe back: start near left edge and drag right
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
        .overlay {
            if isHistoryVisible {
                historyPanel
                    .transition(.move(edge: .bottom))
            }
        }
        .animation(.interactiveSpring(response: 0.38, dampingFraction: 0.86, blendDuration: 0.15), value: isHistoryVisible)
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

        var title: String {
            switch self {
            case .conversation:
                return "Usunąć rozmowę?"
            case .prompt:
                return "Usunąć wpis?"
            }
        }

        var message: String {
            "Ta operacja jest nieodwracalna."
        }
    }

    private func updateKeyboardInset(_ endFrame: CGRect) {
        // Amount of keyboard overlapping the screen
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
                    ForEach(messages) { message in
                        messageRow(message)
                            .id(message.id)
                    }

                    if isLoading {
                        typingIndicator
                            .id("typing-indicator")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 16)
            }
            .onChange(of: messages) { _, newMessages in
                if let last = newMessages.last?.id {
                    withAnimation {
                        proxy.scrollTo(last, anchor: .bottom)
                    }
                }
            }
        }
        .onTapGesture {
            isInputFocused = false
        }
    }

    private var historyPanel: some View {
        GeometryReader { geo in
            let sheetHeight = min(geo.size.height * 0.86, 760)

            // ✅ Zwężamy CAŁY sheet tylko na szerszych telefonach (iPhone 13 Pro = 390pt)
            let isWidePhone = geo.size.width >= 390
            let sheetWidth: CGFloat = isWidePhone ? min(geo.size.width - 28, 380) : geo.size.width

            // Wpisy/układ w środku zostają bez zmian
            let sidePadding: CGFloat = 22

            ZStack(alignment: .bottom) {

                // Background dim (tap closes)
                Color.black.opacity(0.22)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.interactiveSpring(response: 0.38, dampingFraction: 0.86, blendDuration: 0.15)) {
                            isHistoryVisible = false
                            historySheetDragOffset = 0
                        }
                    }

                // Bottom-docked history screen
                VStack(alignment: .leading, spacing: 0) {

                    // Grabber
                    Capsule()
                        .fill(Color.secondary.opacity(0.35))
                        .frame(width: 44, height: 5)
                        .padding(.top, 10)
                        .padding(.bottom, 10)
                        .frame(maxWidth: .infinity)

                    // Header row
                    HStack(spacing: 12) {
                        Text("Historia")
                            .font(.headline)

                        Spacer()

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

                    // Scroll
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {

                            if conversationsSnapshot.isEmpty && promptHistory.isEmpty {
                                Text("Brak historii")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 24)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }

                            // Conversations
                            if !conversationsSnapshot.isEmpty {
                                Text("Rozmowy")
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
                                        .background(Color(.secondarySystemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .stroke(Color.black.opacity(0.04), lineWidth: 1)
                                        )
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            currentConversationId = conv.id
                                            messages = conv.messages
                                            isHistoryVisible = false
                                            historySheetDragOffset = 0
                                        }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                deleteHistoryTarget = .conversation(conv)
                                            } label: {
                                                Label("Usuń", systemImage: "trash")
                                            }
                                        }
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                deleteHistoryTarget = .conversation(conv)
                                            } label: {
                                                Label("Usuń", systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                            }

                            // Prompt history
                            if !promptHistory.isEmpty {
                                Text("Ostatnie zapytania")
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
                                            .background(Color(.secondarySystemBackground))
                                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                    .stroke(Color.black.opacity(0.04), lineWidth: 1)
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
                                                    Label("Usuń", systemImage: "trash")
                                                }
                                            }
                                            .contextMenu {
                                                Button(role: .destructive) {
                                                    deleteHistoryTarget = .prompt(item)
                                                } label: {
                                                    Label("Usuń", systemImage: "trash")
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
                // ✅ tu zwężamy CAŁE okno
                .frame(width: sheetWidth)
                .frame(height: sheetHeight)
                .background(Color(.systemBackground).opacity(0.98))
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
                .alert("Wyczyścić historię?", isPresented: $showClearAllHistoryAlert) {
                    Button("Anuluj", role: .cancel) {}
                    Button("Wyczyść", role: .destructive) {
                        clearAllHistory()
                        isHistoryVisible = false
                        historySheetDragOffset = 0
                    }
                } message: {
                    Text("Usunie to wszystkie rozmowy i ostatnie zapytania. Tej operacji nie da się cofnąć.")
                }
                .alert(item: $deleteHistoryTarget) { target in
                    Alert(
                        title: Text(target.title),
                        message: Text(target.message),
                        primaryButton: .destructive(Text("Usuń")) {
                            switch target {
                            case .conversation(let conv):
                                deleteConversation(conv)
                            case .prompt(let prompt):
                                deletePrompt(prompt)
                            }
                        },
                        secondaryButton: .cancel(Text("Anuluj"))
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
        // Równy odstęp od krawędzi na małych i dużych iPhone'ach
        .padding(.horizontal, 12)
    }

    private func bubble(for msg: AiMessage) -> some View {
        Text(msg.text)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(
                msg.isUser
                ? themeColors.primary
                : themeColors.cardBackground.opacity(0.97)
            )
            .foregroundColor(msg.isUser ? themeColors.lightText : themeColors.primaryText)
            .cornerRadius(18)
            .shadow(color: themeColors.cardShadow, radius: 4, x: 0, y: 2)
            // AI ma być szersze (czytelniejsze), użytkownik może zostać węższy
            .frame(
                maxWidth: UIScreen.main.bounds.width * (msg.isUser ? 0.78 : 0.92),
                alignment: msg.isUser ? .trailing : .leading
            )
    }

    // MARK: - Input bar

    private var inputBar: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                Button {
                    historySheetDragOffset = 0
                    isHistoryVisible.toggle()
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(.label))
                        .frame(width: 30, height: 30)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Button {
                    toggleSpeechRecognition()
                } label: {
                    Image(systemName: isRecording ? "mic.fill" : "mic")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isRecording ? .red : Color(.label))
                        .frame(width: 30, height: 30)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemGray6))
                        .frame(height: 40)
                    TextField(String(localized: "ai_travel_placeholder", table: "Localizable"), text: $userInput)
                        .padding(.horizontal, 12)
                        .foregroundColor(Color(.label))
                        .focused($isInputFocused)
                        .submitLabel(.send)
                        .onSubmit { Task { await sendMessage() } }
                }
                .frame(height: 40)

                Button {
                    Task { await sendMessage() }
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 35, height: 35)
                        .background(
                            userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading
                            ? Color(.systemGray3)
                            : Color(.systemBlue)
                        )
                        .clipShape(Circle())
                }
                .disabled(userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity)
             .background(Color(.systemBackground).opacity(0.5).shadow(radius: 3))

        }
    }

    // MARK: - Wysyłanie wiadomości + rozmowy

    private func sendMessage() async {
        let prompt = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }

        await MainActor.run {
            addToHistory(prompt)
        }

        userInput = ""
        await appendMessage(prompt, isUser: true)

        await MainActor.run { isLoading = true }

        do {
            let response = try await AiTravelService.shared.send(
                prompt: prompt,
                history: messages
            )
            await appendMessage(response, isUser: false)
        } catch {
            await appendMessage(
                String(localized: "ai_travel_error", table: "Localizable"),
                isUser: false
            )
        }

        await MainActor.run {
            isLoading = false
            isInputFocused = false
        }
    }

    @MainActor
    private func appendMessage(_ text: String, isUser: Bool) {
        let message = AiMessage(text: text, isUser: isUser)
        messages.append(message)

        if let id = currentConversationId {
            conversationStore.append(message: message, to: id)
        } else {
            let conversation = conversationStore.createConversation(firstMessage: message)
            currentConversationId = conversation.id
        }
        conversationsSnapshot = conversationStore.conversations
    }

    private func loadLastConversation() {
        if let last = conversationStore.lastConversation() {
            currentConversationId = last.id
            messages = last.messages
        }
    }

    private func startNewConversation() {
        currentConversationId = nil
        messages = []
        userInput = ""
        conversationsSnapshot = conversationStore.conversations
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
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .allowBluetooth, .defaultToSpeaker])
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
