import SwiftUI
import UIKit

enum AppColors {
    static let brand = adaptive(light: 0x125BFF, dark: 0x5A8BFF)
    static let brandPressed = adaptive(light: 0x0A45D8, dark: 0x7CA3FF)
    static let brandSoft = adaptive(light: 0xDDE8FF, dark: 0x172C57)
    static let background = adaptive(light: 0xFFFFFF, dark: 0x0B1220)
    static let surface = adaptive(light: 0xF7F9FD, dark: 0x111C2E)
    static let surfaceRaised = adaptive(light: 0xFFFFFF, dark: 0x19263A)
    static let ink = adaptive(light: 0x12243D, dark: 0xF3F7FF)
    static let muted = adaptive(light: 0x66758F, dark: 0xA6B3C8)
    static let border = adaptive(light: 0xD8E1F0, dark: 0x2C3B52)
    static let unresolved = adaptive(light: 0xA8B4C7, dark: 0x607089)
    static let skipped = adaptive(light: 0x66758F, dark: 0xA6B3C8)
    static let scrim = Color.black.opacity(0.34)

    private static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(
            UIColor { traits in
                UIColor(rgb: traits.userInterfaceStyle == .dark ? dark : light)
            }
        )
    }
}

private extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}

enum AppSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

enum AppRadius {
    static let small: CGFloat = 10
    static let card: CGFloat = 16
    static let prominent: CGFloat = 22
    static let pill: CGFloat = 1_000
}

enum AppMotion {
    static let selection = Animation.easeOut(duration: 0.14)
    static let sheet = Animation.spring(duration: 0.22, bounce: 0.05)
    static let confirmation = Animation.easeOut(duration: 0.18)
}

extension Font {
    static func appDisplay(_ style: TextStyle = .title, weight: Font.Weight = .bold) -> Font {
        let size: CGFloat
        switch style {
        case .largeTitle: 34
        case .title: 28
        case .title2: 22
        case .title3: 20
        default: 18
        }
        return .custom("Plus Jakarta Sans", size: size, relativeTo: style).weight(weight)
    }

    static func appBody(_ style: TextStyle = .body, weight: Font.Weight = .regular) -> Font {
        let size: CGFloat
        switch style {
        case .headline: 17
        case .subheadline: 15
        case .callout: 16
        case .caption: 12
        case .caption2: 11
        default: 17
        }
        return .custom("DM Sans", size: size, relativeTo: style).weight(weight)
    }
}

struct AppSurface: ViewModifier {
    var prominent = false

    func body(content: Content) -> some View {
        content
            .background(prominent ? AppColors.brandSoft : AppColors.surfaceRaised)
            .clipShape(RoundedRectangle(cornerRadius: prominent ? AppRadius.prominent : AppRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: prominent ? AppRadius.prominent : AppRadius.card, style: .continuous)
                    .stroke(prominent ? AppColors.brand.opacity(0.32) : AppColors.border, lineWidth: 1)
            }
    }
}

extension View {
    func appSurface(prominent: Bool = false) -> some View {
        modifier(AppSurface(prominent: prominent))
    }
}

struct PrimaryActionButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appBody(.headline, weight: .bold))
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity, minHeight: 52)
            .padding(.horizontal, AppSpacing.md)
            .background(configuration.isPressed ? AppColors.brandPressed : AppColors.brand)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous))
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(reduceMotion ? nil : AppMotion.selection, value: configuration.isPressed)
    }
}

struct QuietActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appBody(.callout, weight: .semibold))
            .foregroundStyle(AppColors.ink)
            .frame(minHeight: 44)
            .padding(.horizontal, AppSpacing.md)
            .background(configuration.isPressed ? AppColors.brandSoft : AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                    .stroke(AppColors.border, lineWidth: 1)
            }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = AppSpacing.xs

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) -> CGSize {
        arrange(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, point) in result.points.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, points: [CGPoint]) {
        let maxWidth = proposal.width ?? 320
        var points: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            points.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return (CGSize(width: maxWidth, height: y + rowHeight), points)
    }
}
