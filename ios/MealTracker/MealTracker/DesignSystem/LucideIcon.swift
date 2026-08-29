import SwiftUI

enum Lucide: String {
    case utensils
    case calendarDays = "calendar-days"
    case compass
    case sparkles
    case mic
    case camera
    case image
    case chevronRight = "chevron-right"
    case flame
    case gem
    case check
    case circle
    case circleDashed = "circle-dashed"
    case x
    case pencil
    case undo = "undo-2"
    case plus
    case mapPin = "map-pin"
    case search
    case settings
    case clock
    case info
    case refresh = "refresh-cw"
    case trash = "trash-2"
    case arrowRight = "arrow-right"
    case shieldCheck = "shield-check"
    case heartPulse = "heart-pulse"
    case skipForward = "skip-forward"
    case checkCircle = "circle-check-big"
    case triangleAlert = "triangle-alert"
    case wifiOff = "wifi-off"
    case lock
    case salad
    case sandwich
    case soup
    case audioLines = "audio-lines"
}

struct LucideIcon: View {
    var icon: Lucide
    var size: CGFloat = 20
    var strokeWidth: CGFloat = 1.85

    var body: some View {
        Image(icon.rawValue)
            .resizable()
            .renderingMode(.template)
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}
