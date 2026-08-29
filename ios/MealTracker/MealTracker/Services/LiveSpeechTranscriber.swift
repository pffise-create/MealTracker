import AVFoundation
import Foundation
import Speech

enum SpeechTranscriptionError: LocalizedError {
    case permissionDenied
    case unavailable

    var errorDescription: String? {
        switch self {
        case .permissionDenied: "Speech or microphone access is off. Text logging is still available."
        case .unavailable: "Speech recognition is unavailable right now. Try text logging instead."
        }
    }
}

@MainActor
protocol VoiceTranscribing: AnyObject {
    var isRecording: Bool { get }
    func requestAuthorization() async -> Bool
    func start(onUpdate: @escaping (String) -> Void) throws
    func stop()
}

@MainActor
final class LiveSpeechTranscriber: NSObject, VoiceTranscribing {
    private let recognizer = SFSpeechRecognizer(locale: Locale.autoupdatingCurrent)
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var tapInstalled = false
    private(set) var isRecording = false

    func requestAuthorization() async -> Bool {
        let speechAllowed = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
        guard speechAllowed else { return false }
        return await AVAudioApplication.requestRecordPermission()
    }

    func start(onUpdate: @escaping (String) -> Void) throws {
        guard recognizer?.isAvailable == true else { throw SpeechTranscriptionError.unavailable }
        stop()

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.request = request

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1_024, format: format) { buffer, _ in
            request.append(buffer)
        }
        tapInstalled = true

        task = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if let result {
                Task { @MainActor in
                    onUpdate(result.bestTranscription.formattedString)
                    if result.isFinal { self.stop() }
                }
            } else if error != nil {
                Task { @MainActor in self.stop() }
            }
        }

        audioEngine.prepare()
        try audioEngine.start()
        isRecording = true
    }

    func stop() {
        if audioEngine.isRunning { audioEngine.stop() }
        if tapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            tapInstalled = false
        }
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
        isRecording = false
    }
}
