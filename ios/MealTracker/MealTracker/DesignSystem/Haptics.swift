import UIKit

enum Haptics {
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func loggingConfirmation() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func dayCompletion() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred(intensity: 0.72)
    }

    static func undo() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
