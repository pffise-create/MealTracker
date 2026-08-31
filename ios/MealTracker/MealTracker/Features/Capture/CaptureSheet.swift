import AVFoundation
import PhotosUI
import SwiftUI
import UIKit

struct CaptureSheet: View {
    @EnvironmentObject private var store: MealTrackerStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var mode: CaptureMode?
    @State private var category = MealCategory.snacks
    @State private var text = ""
    @State private var transcript = ""
    @State private var recording = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showingCamera = false
    @State private var localError: String?

    init() {
        let hour = Calendar.autoupdatingCurrent.component(.hour, from: Date())
        let initialCategory: MealCategory
        switch hour {
        case 4..<11: initialCategory = .breakfast
        case 11..<15: initialCategory = .lunch
        case 17..<22: initialCategory = .dinner
        default: initialCategory = .snacks
        }
        _category = State(initialValue: initialCategory)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    if let mode {
                        activeMode(mode)
                    } else {
                        intro
                        captureGrid
                    }
                }
                .padding(AppSpacing.lg)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(AppColors.background)
            .navigationTitle(mode?.title ?? "Quick capture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(mode == nil ? "Close" : "Back") {
                        if mode == nil {
                            dismiss()
                        } else {
                            stopRecording()
                            self.mode = nil
                            localError = nil
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraPicker { data in
                showingCamera = false
                guard let data else { return }
                Task { await analyzePhoto(data, method: .camera) }
            }
            .ignoresSafeArea()
        }
        .onChange(of: selectedPhoto) { _, item in
            guard let item else { return }
            Task {
                do {
                    guard let data = try await item.loadTransferable(type: Data.self) else {
                        throw MealAnalysisError.imageUnreadable
                    }
                    await analyzePhoto(data, method: .photoLibrary)
                    selectedPhoto = nil
                } catch {
                    localError = error.localizedDescription
                }
            }
        }
        .onDisappear { stopRecording() }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Log first. Correct if needed.")
                .font(.appDisplay(.title2, weight: .bold))
                .foregroundStyle(AppColors.ink)
            Text("Text and photo nutrition use a clearly labeled local demo estimator in this build. Voice transcription is native. No original food photo is saved.")
                .font(.appBody(.subheadline))
                .foregroundStyle(AppColors.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var captureGrid: some View {
        LazyVGrid(
            columns: dynamicTypeSize.isAccessibilitySize
                ? [GridItem(.flexible())]
                : [GridItem(.flexible()), GridItem(.flexible())],
            spacing: AppSpacing.sm
        ) {
            CaptureChoice(icon: .sparkles, title: "Type it", subtitle: "Describe one or more foods") { mode = .text }
            CaptureChoice(icon: .mic, title: "Speak", subtitle: "Native speech transcription") { mode = .voice }
            CaptureChoice(icon: .camera, title: "Take photo", subtitle: "Camera access only when tapped") { requestCamera() }
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                CaptureChoiceLabel(icon: .image, title: "Choose photo", subtitle: "No full-library access needed")
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("capture.photoLibrary")
        }
    }

    @ViewBuilder
    private func activeMode(_ mode: CaptureMode) -> some View {
        categoryPicker
        switch mode {
        case .text:
            textEntry
        case .voice:
            voiceEntry
        case .camera, .photo:
            processingState
        }
    }

    @ViewBuilder
    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("MEAL CATEGORY")
                .font(.appBody(.caption2, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(AppColors.muted)
            if dynamicTypeSize.isAccessibilitySize {
                Picker("Meal category", selection: $category) {
                    ForEach(MealCategory.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .accessibilityIdentifier("capture.category")
            } else {
                Picker("Meal category", selection: $category) {
                    ForEach(MealCategory.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("capture.category")
            }
        }
    }

    private var textEntry: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            TextField("Example: turkey sandwich and a handful of chips", text: $text, axis: .vertical)
                .lineLimit(3...7)
                .font(.appBody())
                .padding(AppSpacing.md)
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                        .stroke(AppColors.border, lineWidth: 1)
                }
                .accessibilityIdentifier("capture.text")
            disclosure
            localErrorText
            Button {
                Task {
                    if await store.analyzeTextAndLog(text, category: category) { dismiss() }
                }
            } label: {
                if store.isAnalyzing {
                    ProgressView().tint(.white).accessibilityLabel("Estimating meal")
                } else {
                    HStack {
                        Text("Estimate and log")
                        LucideIcon(icon: .arrowRight, size: 18)
                    }
                }
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .disabled(store.isAnalyzing || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityIdentifier("capture.logText")
        }
    }

    private var voiceEntry: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            ZStack {
                Circle().fill(recording ? AppColors.brand : AppColors.brandSoft)
                LucideIcon(icon: recording ? .audioLines : .mic, size: 34)
                    .foregroundStyle(recording ? Color.white : AppColors.brand)
            }
            .frame(width: 78, height: 78)
            .frame(maxWidth: .infinity)

            Text(transcript.isEmpty ? "Your editable transcript appears here." : transcript)
                .font(.appBody())
                .foregroundStyle(transcript.isEmpty ? AppColors.muted : AppColors.ink)
                .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
                .padding(AppSpacing.md)
                .appSurface()
                .accessibilityIdentifier("capture.transcript")

            localErrorText
            Button(recording ? "Stop listening" : "Start listening") {
                recording ? stopRecording() : startRecording()
            }
            .buttonStyle(QuietActionButtonStyle())
            .accessibilityIdentifier("capture.record")

            Button {
                Task {
                    stopRecording()
                    if await store.analyzeTextAndLog(transcript, category: category, method: .voice) { dismiss() }
                }
            } label: {
                Text("Estimate and log transcript")
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .disabled(transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.isAnalyzing)
            .accessibilityIdentifier("capture.logVoice")
            disclosure
        }
    }

    private var processingState: some View {
        VStack(spacing: AppSpacing.md) {
            ProgressView().controlSize(.large).tint(AppColors.brand)
            Text(BackendMealAnalyzer() == nil ? "Preparing demo estimate…" : "Analyzing your meal…")
                .font(.appBody(.headline, weight: .semibold))
            if BackendMealAnalyzer() != nil {
                Text("The private server may need up to a minute to wake after inactivity.")
                    .font(.appBody(.caption))
                    .foregroundStyle(AppColors.muted)
                    .multilineTextAlignment(.center)
            }
            disclosure
        }
        .frame(maxWidth: .infinity, minHeight: 220)
    }

    private var disclosure: some View {
        HStack(alignment: .top, spacing: AppSpacing.xs) {
            LucideIcon(icon: .info, size: 15)
            Text(
                BackendMealAnalyzer() == nil
                    ? "Demo estimator: local sample rules, not live AI. The result logs optimistically with immediate Edit and Undo."
                    : "AI estimate from your private backend. Review with Edit or remove it immediately with Undo."
            )
        }
        .font(.appBody(.caption))
        .foregroundStyle(AppColors.muted)
    }

    @ViewBuilder
    private var localErrorText: some View {
        if let localError {
            HStack(alignment: .top, spacing: AppSpacing.xs) {
                LucideIcon(icon: .triangleAlert, size: 16)
                Text(localError)
            }
            .font(.appBody(.caption))
            .foregroundStyle(AppColors.muted)
            .accessibilityIdentifier("capture.error")
        }
    }

    private func requestCamera() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                localError = "Camera is unavailable on this device. Choose a photo or use text."
                return
            }
            showingCamera = true
        case .notDetermined:
            Task {
                if await AVCaptureDevice.requestAccess(for: .video),
                   UIImagePickerController.isSourceTypeAvailable(.camera) {
                    showingCamera = true
                } else {
                    localError = "Camera access is off or unavailable. Choose a photo or use text instead."
                }
            }
        case .denied, .restricted:
            localError = "Camera access is off. Choose a photo or use text instead."
        @unknown default:
            localError = "Camera is unavailable. Choose a photo or use text instead."
        }
    }

    private func startRecording() {
        Task {
            guard await store.voiceTranscriber.requestAuthorization() else {
                localError = SpeechTranscriptionError.permissionDenied.localizedDescription
                return
            }
            do {
                try store.voiceTranscriber.start { value in transcript = value }
                recording = true
                localError = nil
            } catch {
                localError = error.localizedDescription
            }
        }
    }

    private func stopRecording() {
        store.voiceTranscriber.stop()
        recording = false
    }

    private func analyzePhoto(_ data: Data, method: MealInputMethod) async {
        mode = method == .camera ? .camera : .photo
        guard let preparedData = preparedImageData(from: data) else {
            localError = MealAnalysisError.imageUnreadable.localizedDescription
            mode = nil
            return
        }
        let success = await store.analyzePhotoAndLog(preparedData, category: category, method: method)
        // Original and prepared bytes are scoped to this operation and are not persisted.
        if success { dismiss() } else { mode = nil }
    }

    private func preparedImageData(from data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let longestSide = max(image.size.width, image.size.height)
        let scale = min(1_600 / max(longestSide, 1), 1)
        let targetSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let rendered = UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return rendered.jpegData(compressionQuality: 0.78)
    }
}

private enum CaptureMode {
    case text
    case voice
    case camera
    case photo

    var title: String {
        switch self {
        case .text: "Describe meal"
        case .voice: "Speak meal"
        case .camera: "Camera estimate"
        case .photo: "Photo estimate"
        }
    }
}

private struct CaptureChoice: View {
    let icon: Lucide
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            CaptureChoiceLabel(icon: icon, title: title, subtitle: subtitle)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("capture.\(title.replacingOccurrences(of: " ", with: "-"))")
    }
}

private struct CaptureChoiceLabel: View {
    let icon: Lucide
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            LucideIcon(icon: icon, size: 24).foregroundStyle(AppColors.brand)
            Spacer(minLength: AppSpacing.xs)
            Text(title).font(.appBody(.headline, weight: .bold)).foregroundStyle(AppColors.ink)
            Text(subtitle).font(.appBody(.caption)).foregroundStyle(AppColors.muted).multilineTextAlignment(.leading)
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .leading)
        .appSurface()
    }
}

private struct CameraPicker: UIViewControllerRepresentable {
    let completion: (Data?) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(completion: completion) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let controller = UIImagePickerController()
        controller.sourceType = .camera
        controller.cameraCaptureMode = .photo
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let completion: (Data?) -> Void

        init(completion: @escaping (Data?) -> Void) {
            self.completion = completion
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let image = info[.originalImage] as? UIImage
            completion(image?.jpegData(compressionQuality: 0.78))
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            completion(nil)
        }
    }
}
