import SwiftUI
import Speech
import AVFoundation

struct SearchView: View {
    @Binding var searchText: String
    @Binding var showSettings: Bool
    @Binding var searchMode: SearchMode
    @Binding var triggerVoice: Bool
    @State private var suggestions: [String] = []
    @State private var results: [WebResult] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var isListening = false
    @State private var suggestionTask: Task<Void, Never>?
    @FocusState private var isSearchFocused: Bool

    @StateObject private var speechRecognizer = SpeechRecognizer()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                modePicker
                if let error = errorMessage {
                    errorBanner(error)
                }
                if isSearching {
                    ProgressView("Searching...")
                        .padding()
                    Spacer()
                } else if isListening {
                    listeningView
                } else if !suggestions.isEmpty && results.isEmpty {
                    suggestionsList
                } else if !results.isEmpty {
                    resultsList
                } else {
                    emptyState
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Private Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        startVoiceSearch()
                    } label: {
                        Image(systemName: isListening ? "mic.fill" : "mic")
                            .foregroundStyle(isListening ? .red : .primary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .onAppear {
                isSearchFocused = true
            }
            .onChange(of: triggerVoice) { _, newValue in
                if newValue {
                    triggerVoice = false
                    startVoiceSearch()
                }
            }
        }
    }

    // MARK: - Mode Picker

    private var modePicker: some View {
        Picker("Search mode", selection: $searchMode) {
            Label("Web", systemImage: "globe").tag(SearchMode.web)
            Label("Images", systemImage: "photo").tag(SearchMode.images)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.bottom, 4)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search privately", text: $searchText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($isSearchFocused)
                .onSubmit { performSearch() }
                .onChange(of: searchText) { _, newValue in
                    debouncedFetchSuggestions(for: newValue)
                }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    suggestions = []
                    results = []
                    errorMessage = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding()
    }

    // MARK: - Listening View

    private var listeningView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.red)
                .symbolEffect(.pulse)
            Text("Listening...")
                .font(.title3)
                .foregroundStyle(.secondary)
            if !speechRecognizer.transcript.isEmpty {
                Text(speechRecognizer.transcript)
                    .font(.headline)
                    .padding()
            }
            Button("Stop & Search") {
                stopVoiceAndSearch()
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            Spacer()
        }
    }

    // MARK: - Suggestions

    private var suggestionsList: some View {
        List(suggestions, id: \.self) { suggestion in
            Button {
                searchText = suggestion
                performSearch()
            } label: {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                    Text(suggestion)
                        .foregroundStyle(.primary)
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Results

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(results) { result in
                    Button {
                        if let url = URL(string: result.url) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            // Site info row
                            HStack(spacing: 8) {
                                AsyncImage(url: result.faviconURL) { image in
                                    image.resizable()
                                        .aspectRatio(contentMode: .fit)
                                } placeholder: {
                                    Image(systemName: "globe")
                                        .foregroundStyle(.secondary)
                                }
                                .frame(width: 16, height: 16)
                                .clipShape(RoundedRectangle(cornerRadius: 3))

                                Text(result.displayURL)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)

                                Spacer()
                            }

                            // Title
                            Text(result.title)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.orange)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)

                            // Description
                            if let desc = result.description {
                                Text(desc)
                                    .font(.system(size: 14))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(3)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.top, 4)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Image(systemName: "shield.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(.orange.gradient)
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .offset(y: -2)
            }
            Text("Search the web privately")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("Powered by Brave Search")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer()
        }
    }

    // MARK: - Error Banner

    private func errorBanner(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text(message)
                .font(.footnote)
            Spacer()
            Button("Settings") {
                showSettings = true
            }
            .font(.footnote.bold())
        }
        .padding(10)
        .background(Color(.systemYellow).opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal)
    }

    // MARK: - Voice Search

    private func startVoiceSearch() {
        guard !isListening else { return }
        isListening = true
        isSearchFocused = false
        speechRecognizer.startTranscribing { error in
            if let error = error {
                isListening = false
                errorMessage = error
            }
        }
    }

    private func stopVoiceAndSearch() {
        speechRecognizer.stopTranscribing()
        isListening = false
        if !speechRecognizer.transcript.isEmpty {
            searchText = speechRecognizer.transcript
            performSearch()
        }
    }

    // MARK: - Search Actions

    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSearchFocused = false
        suggestions = []
        isSearching = true
        errorMessage = nil

        switch searchMode {
        case .web:
            performWebSearch()
        case .images:
            performImageSearch()
        }
    }

    private func performWebSearch() {
        Task {
            do {
                let response = try await BraveSearchAPI.search(query: searchText)
                results = response.web?.results ?? []
                if results.isEmpty {
                    errorMessage = "No results found"
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isSearching = false
        }
    }

    private func performImageSearch() {
        let query = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? searchText
        if let url = URL(string: "https://search.brave.com/images?q=\(query)") {
            UIApplication.shared.open(url)
        }
        isSearching = false
    }

    // MARK: - Debounced Suggestions

    private func debouncedFetchSuggestions(for query: String) {
        suggestionTask?.cancel()
        guard query.count >= 2 else {
            suggestions = []
            return
        }
        suggestionTask = Task {
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            if let fetched = try? await BraveSearchAPI.suggest(query: query) {
                if searchText == query {
                    suggestions = fetched
                }
            }
        }
    }
}

// MARK: - Speech Recognizer

@MainActor
class SpeechRecognizer: ObservableObject {
    @Published var transcript = ""

    private var audioEngine = AVAudioEngine()
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?

    func startTranscribing(onError: @escaping (String?) -> Void) {
        transcript = ""

        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor in
                switch status {
                case .authorized:
                    self?.startAudioEngine(onError: onError)
                case .denied:
                    onError("Speech recognition denied. Enable it in Settings > Privacy > Speech Recognition.")
                case .restricted:
                    onError("Speech recognition is restricted on this device.")
                case .notDetermined:
                    onError("Speech recognition permission not determined.")
                @unknown default:
                    onError("Speech recognition unavailable.")
                }
            }
        }
    }

    private func startAudioEngine(onError: @escaping (String?) -> Void) {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            onError("Speech recognition is not available right now.")
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement)
            try audioSession.setActive(true)
        } catch {
            onError("Could not configure audio session.")
            return
        }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            onError("Could not start audio engine.")
            return
        }

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                if let result = result {
                    self?.transcript = result.bestTranscription.formattedString
                }
                if error != nil {
                    self?.stopTranscribing()
                }
            }
        }
    }

    func stopTranscribing() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil

        try? AVAudioSession.sharedInstance().setActive(false)
    }
}
