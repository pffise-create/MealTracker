import SwiftUI
import UIKit

/// The map is a single painted backdrop with lightweight, stateful vector landmarks.
/// Coordinates are shared by the scenery, hit targets and the player's location.
struct CommonwealthMapView: View {
    let selectedSite: String
    let builtSites: Set<String>
    let securedSites: Set<String>
    let heroSite: String
    let onSelect: (String) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var hasArtwork: Bool { UIImage(named: "BriarGlenValley") != nil }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                LinearGradient(colors: [GlenInk.sage, GlenInk.grass, GlenInk.ochre], startPoint: .top, endPoint: .bottom)
                if hasArtwork {
                    Image("BriarGlenValley")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                }

                Canvas { originalContext, size in
                    var context = originalContext
                    context.scaleBy(x: size.width / 400, y: size.height / 500)
                    if !hasArtwork {
                        GlenDrawing.terrain(in: &context)
                        GlenDrawing.trails(in: &context)
                    }
                    for site in GlenSite.all {
                        GlenDrawing.landmark(site, built: builtSites.contains(site.id), secured: securedSites.contains(site.id), improvements: builtSites, paintedTerrain: hasArtwork, in: &context)
                    }
                    if let site = GlenSite.all.first(where: { $0.id == heroSite }) {
                        GlenDrawing.person(at: CGPoint(x: site.point.x + 24, y: site.point.y + 10), coat: GlenInk.banner, hero: true, in: &context)
                    }
                }
                .accessibilityHidden(true)

                ForEach(GlenSite.all) { site in
                    siteButton(site)
                        .position(x: geometry.size.width * site.x, y: geometry.size.height * site.y + 22)
                }

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("BRIAR GLEN")
                            .font(.system(size: 17, weight: .bold, design: .serif))
                            .tracking(2)
                        Text("THE BORDERLANDS")
                            .font(.system(size: 8, weight: .semibold))
                            .tracking(2.4)
                    }
                    .foregroundStyle(GlenInk.ink)
                    .padding(10)
                    .background(GlenInk.parchment.opacity(0.90), in: RoundedRectangle(cornerRadius: 4))
                    Spacer()
                    VStack(spacing: 1) {
                        Text("N").font(.system(size: 10, weight: .bold, design: .serif))
                        Image(systemName: "location.north.fill").font(.system(size: 18))
                    }
                    .foregroundStyle(GlenInk.ink)
                    .padding(9)
                    .background(GlenInk.parchment.opacity(0.85), in: Capsule())
                }
                .padding(12)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
        }
        .aspectRatio(0.8, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(GlenInk.ink.opacity(0.20), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Briar Glen world map")
        .accessibilityIdentifier("commonwealth.map")
    }

    private func siteButton(_ site: GlenSite) -> some View {
        let selected = selectedSite == site.id
        let secured = securedSites.contains(site.id)
        let built = builtSites.contains(site.id)
        let heroIsHere = heroSite == site.id
        return Button {
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.18)) { onSelect(site.id) }
        } label: {
            VStack(spacing: 1) {
                ZStack {
                    Ellipse()
                        .stroke(selected ? GlenInk.blue : GlenInk.parchment.opacity(0.75), lineWidth: selected ? 2.5 : 1)
                        .frame(width: selected ? 53 : 40, height: 17)
                    if selected {
                        Ellipse().fill(GlenInk.blue.opacity(0.16)).frame(width: 53, height: 17)
                    }
                }
                .frame(height: 21)
                HStack(spacing: 3) {
                    if secured {
                        Image(systemName: "flag.fill").font(.system(size: 8))
                    }
                    Text(site.label)
                        .font(.system(size: 11, weight: .semibold))
                        .lineLimit(1)
                }
                .foregroundStyle(selected ? Color.white : GlenInk.ink)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(selected ? GlenInk.blue : GlenInk.parchment.opacity(0.96), in: Capsule())
                .overlay(Capsule().stroke(selected ? GlenInk.blue : GlenInk.ink.opacity(0.24), lineWidth: 0.6))
            }
            .frame(minWidth: 66, minHeight: 50)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(site.accessibilityName)
        .accessibilityValue("\(secured ? "Secured" : "Contested"), \(built ? "developed" : "undeveloped")\(heroIsHere ? ", you are here" : "")")
        .accessibilityHint("Shows this location and available actions.")
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("commonwealth.site.\(site.id)")
    }
}

private struct GlenSite: Identifiable {
    let id: String
    let label: String
    let accessibilityName: String
    let x: CGFloat
    let y: CGFloat
    var point: CGPoint { CGPoint(x: x * 400, y: y * 500) }

    static let all: [GlenSite] = [
        .init(id: "ridge", label: "Greyback", accessibilityName: "Greyback Ridge", x: 0.73, y: 0.18),
        .init(id: "pinewood", label: "Pinewood", accessibilityName: "The Pinewood", x: 0.22, y: 0.32),
        .init(id: "creek", label: "Willow Creek", accessibilityName: "Willow Creek", x: 0.68, y: 0.43),
        .init(id: "homestead", label: "Homestead", accessibilityName: "Vale Homestead", x: 0.34, y: 0.64),
        .init(id: "crossing", label: "Voss Crossing", accessibilityName: "Voss Crossing", x: 0.78, y: 0.70),
        .init(id: "township", label: "The Commons", accessibilityName: "Briar Commons", x: 0.50, y: 0.85)
    ]
}

private enum GlenInk {
    static let ink = Color(red: 0.16, green: 0.23, blue: 0.20)
    static let forest = Color(red: 0.15, green: 0.31, blue: 0.24)
    static let sage = Color(red: 0.48, green: 0.57, blue: 0.40)
    static let grass = Color(red: 0.70, green: 0.70, blue: 0.46)
    static let ochre = Color(red: 0.79, green: 0.66, blue: 0.40)
    static let parchment = Color(red: 0.98, green: 0.93, blue: 0.79)
    static let timber = Color(red: 0.35, green: 0.27, blue: 0.19)
    static let plaster = Color(red: 0.72, green: 0.64, blue: 0.47)
    static let roof = Color(red: 0.40, green: 0.30, blue: 0.22)
    static let water = Color(red: 0.64, green: 0.78, blue: 0.74)
    static let blue = Color(red: 0.07, green: 0.36, blue: 1.0)
    static let banner = Color(red: 0.24, green: 0.37, blue: 0.53)
    static let rust = Color(red: 0.52, green: 0.30, blue: 0.21)
}

/// All drawing uses a 400 × 500 coordinate space, then scales once per render.
/// No particles, display links, retained sprite collections or offscreen 3D scenes.
private enum GlenDrawing {
    static func terrain(in context: inout GraphicsContext) {
        polygon([(-20, 115), (29, 44), (70, 60), (111, 18), (150, 50), (197, 7), (225, 39), (275, 15), (340, 44), (387, 19), (425, 90), (425, 212), (-20, 185)], fill: GlenInk.forest.opacity(0.52), in: &context)
        polygon([(-5, 128), (45, 78), (104, 116), (163, 71), (219, 111), (275, 60), (326, 86), (352, 59), (420, 135), (421, 250), (-5, 228)], fill: GlenInk.sage, in: &context)
        polygon([(-10, 320), (67, 249), (133, 253), (187, 280), (239, 240), (312, 272), (407, 236), (412, 515), (-10, 515)], fill: GlenInk.ochre.opacity(0.60), in: &context)

        var stream = Path()
        stream.move(to: CGPoint(x: 310, y: 57))
        stream.addCurve(to: CGPoint(x: 278, y: 250), control1: CGPoint(x: 231, y: 112), control2: CGPoint(x: 333, y: 188))
        stream.addCurve(to: CGPoint(x: 343, y: 520), control1: CGPoint(x: 219, y: 328), control2: CGPoint(x: 397, y: 378))
        context.stroke(stream, with: .color(GlenInk.forest.opacity(0.34)), style: StrokeStyle(lineWidth: 25, lineCap: .round))
        context.stroke(stream, with: .color(GlenInk.water), style: StrokeStyle(lineWidth: 16, lineCap: .round))
        context.stroke(stream, with: .color(GlenInk.parchment.opacity(0.6)), style: StrokeStyle(lineWidth: 2, lineCap: .round))

        for index in 0..<65 {
            let x = CGFloat((index * 59 + 19) % 398)
            let y = CGFloat((index * 83 + 87) % 450 + 45)
            if x < 152 && y < 290 || x > 345 && y < 330 {
                pine(at: CGPoint(x: x, y: y), height: CGFloat(13 + index % 13), in: &context)
            } else {
                var grass = Path()
                grass.move(to: CGPoint(x: x, y: y))
                grass.addLine(to: CGPoint(x: x + 3, y: y - 3))
                grass.move(to: CGPoint(x: x + 4, y: y + 1))
                grass.addLine(to: CGPoint(x: x + 5, y: y - 3))
                context.stroke(grass, with: .color(GlenInk.forest.opacity(0.25)), lineWidth: 0.8)
            }
        }
    }

    static func trails(in context: inout GraphicsContext) {
        var road = Path()
        road.move(to: CGPoint(x: 200, y: 455))
        road.addCurve(to: CGPoint(x: 136, y: 323), control1: CGPoint(x: 169, y: 401), control2: CGPoint(x: 112, y: 373))
        road.addCurve(to: CGPoint(x: 88, y: 164), control1: CGPoint(x: 168, y: 251), control2: CGPoint(x: 99, y: 209))
        road.move(to: CGPoint(x: 136, y: 323))
        road.addCurve(to: CGPoint(x: 312, y: 351), control1: CGPoint(x: 214, y: 289), control2: CGPoint(x: 247, y: 364))
        road.move(to: CGPoint(x: 224, y: 330))
        road.addCurve(to: CGPoint(x: 272, y: 217), control1: CGPoint(x: 257, y: 291), control2: CGPoint(x: 227, y: 242))
        road.addCurve(to: CGPoint(x: 292, y: 92), control1: CGPoint(x: 306, y: 181), control2: CGPoint(x: 271, y: 147))
        context.stroke(road, with: .color(GlenInk.ink.opacity(0.12)), style: StrokeStyle(lineWidth: 7, lineCap: .round))
        context.stroke(road, with: .color(GlenInk.parchment.opacity(0.55)), style: StrokeStyle(lineWidth: 4, lineCap: .round))
    }

    static func landmark(_ site: GlenSite, built: Bool, secured: Bool, improvements: Set<String>, paintedTerrain: Bool, in context: inout GraphicsContext) {
        let point = site.point
        groundShadow(at: point, width: built ? 66 : 36, in: &context)
        switch site.id {
        case "homestead":
            if built {
                if improvements.contains("garden") {
                    field(at: CGPoint(x: point.x - 41, y: point.y + 1), in: &context)
                    field(at: CGPoint(x: point.x - 31, y: point.y - 22), in: &context)
                }
                house(at: point, width: 39, height: 26, in: &context)
                house(at: CGPoint(x: point.x + 30, y: point.y + 3), width: 20, height: 15, in: &context)
                fence(from: CGPoint(x: point.x - 33, y: point.y + 7), count: 7, in: &context)
                person(at: CGPoint(x: point.x - 16, y: point.y + 9), coat: GlenInk.rust, hero: false, in: &context)
            } else {
                house(at: point, width: 25, height: 16, in: &context)
                fence(from: CGPoint(x: point.x - 29, y: point.y + 8), count: 3, in: &context)
            }
        case "pinewood":
            if !paintedTerrain {
                for offset in [-23.0, -13.0, 22.0] {
                    pine(at: CGPoint(x: point.x + offset, y: point.y - 3), height: 29, in: &context)
                }
            }
            if built {
                house(at: point, width: 33, height: 20, in: &context)
                logs(at: CGPoint(x: point.x - 24, y: point.y + 7), in: &context)
                person(at: CGPoint(x: point.x + 18, y: point.y + 7), coat: GlenInk.ochre, hero: false, in: &context)
            } else {
                logs(at: CGPoint(x: point.x - 3, y: point.y + 2), in: &context)
            }
        case "creek":
            if built {
                well(at: point, in: &context)
                person(at: CGPoint(x: point.x - 23, y: point.y + 6), coat: GlenInk.sage, hero: false, in: &context)
            } else if !paintedTerrain {
                polygon([(point.x - 13, point.y), (point.x - 7, point.y - 10), (point.x + 3, point.y - 12), (point.x + 11, point.y - 3), (point.x + 5, point.y + 3)], fill: GlenInk.sage, in: &context)
            }
        case "ridge":
            if built {
                quarry(at: point, in: &context)
                person(at: CGPoint(x: point.x - 15, y: point.y + 8), coat: GlenInk.ochre, hero: false, in: &context)
            } else if !paintedTerrain {
                polygon([(point.x - 16, point.y), (point.x - 7, point.y - 20), (point.x + 3, point.y - 13), (point.x + 11, point.y - 29), (point.x + 24, point.y + 1)], fill: GlenInk.ink.opacity(0.64), in: &context)
                polygon([(point.x + 3, point.y - 13), (point.x + 11, point.y - 29), (point.x + 15, point.y - 15)], fill: GlenInk.parchment.opacity(0.65), in: &context)
            }
        case "crossing":
            bridge(at: point, built: built, in: &context)
            if built {
                if improvements.contains("watchtower") {
                    tower(at: CGPoint(x: point.x - 25, y: point.y - 12), in: &context)
                    fence(from: CGPoint(x: point.x - 39, y: point.y - 1), count: 4, in: &context)
                } else if improvements.contains("tradingPost") {
                    market(at: CGPoint(x: point.x - 29, y: point.y - 10), in: &context)
                    market(at: CGPoint(x: point.x + 24, y: point.y - 18), in: &context)
                } else {
                    house(at: CGPoint(x: point.x - 28, y: point.y - 9), width: 19, height: 16, in: &context)
                }
                person(at: CGPoint(x: point.x + 21, y: point.y + 5), coat: GlenInk.rust, hero: false, in: &context)
            }
        case "township":
            if built {
                house(at: CGPoint(x: point.x - 24, y: point.y - 7), width: 22, height: 18, in: &context)
                house(at: CGPoint(x: point.x + 27, y: point.y - 6), width: 23, height: 20, in: &context)
                house(at: CGPoint(x: point.x + 1, y: point.y), width: 33, height: 30, in: &context)
                for index in 0..<4 {
                    person(at: CGPoint(x: point.x - 28 + CGFloat(index) * 15, y: point.y + 8 + CGFloat(index % 2) * 5), coat: index % 2 == 0 ? GlenInk.rust : GlenInk.sage, hero: false, in: &context)
                }
            } else {
                tent(at: CGPoint(x: point.x - 13, y: point.y - 1), in: &context)
                tent(at: CGPoint(x: point.x + 14, y: point.y + 2), in: &context)
            }
        default: break
        }
        flag(at: CGPoint(x: point.x + 23, y: point.y - 3), secured: secured, in: &context)
    }

    private static func house(at p: CGPoint, width w: CGFloat, height h: CGFloat, in context: inout GraphicsContext) {
        let depth = w * 0.35
        groundShadow(at: CGPoint(x: p.x + depth / 2, y: p.y), width: w * 1.9, in: &context)
        polygon([(p.x - w / 2, p.y - h), (p.x + w / 2, p.y - h + 3), (p.x + w / 2, p.y), (p.x - w / 2, p.y - 3)], fill: GlenInk.plaster, in: &context)
        polygon([(p.x + w / 2, p.y - h + 3), (p.x + w / 2 + depth, p.y - h - 4), (p.x + w / 2 + depth, p.y - 7), (p.x + w / 2, p.y)], fill: GlenInk.timber, in: &context)
        for row in stride(from: CGFloat(4), to: h, by: 3) {
            line(from: CGPoint(x: p.x - w / 2, y: p.y - h + row), to: CGPoint(x: p.x + w / 2, y: p.y - h + row + 3), color: GlenInk.timber.opacity(0.35), width: 0.65, in: &context)
            line(from: CGPoint(x: p.x + w / 2, y: p.y - h + row + 3), to: CGPoint(x: p.x + w / 2 + depth, y: p.y - h + row - 4), color: GlenInk.parchment.opacity(0.18), width: 0.5, in: &context)
        }
        polygon([(p.x - w / 2 - 3, p.y - h + 1), (p.x - 4, p.y - h - 12), (p.x + w / 2 + depth + 3, p.y - h - 3), (p.x + w / 2 + 2, p.y - h + 6)], fill: GlenInk.roof, in: &context)
        polygon([(p.x - 4, p.y - h - 12), (p.x + depth - 3, p.y - h - 17), (p.x + w / 2 + depth + 3, p.y - h - 3)], fill: GlenInk.timber, in: &context)
        for row in 1...4 {
            let t = CGFloat(row) / 5
            line(from: CGPoint(x: p.x - 4 + (-w / 2 + 1) * t, y: p.y - h - 12 + 13 * t), to: CGPoint(x: p.x + w / 2 + depth + 3 - (depth + 1) * t, y: p.y - h - 3 + 9 * t), color: GlenInk.parchment.opacity(row.isMultiple(of: 2) ? 0.20 : 0.12), width: 0.7, in: &context)
        }
        line(from: CGPoint(x: p.x - w / 2 - 3, y: p.y - h + 1), to: CGPoint(x: p.x + w / 2 + 2, y: p.y - h + 6), color: GlenInk.ink.opacity(0.55), width: 1.1, in: &context)
        context.fill(Path(CGRect(x: p.x - 2, y: p.y - 12, width: 6, height: 11)), with: .color(GlenInk.timber))
        context.fill(Path(CGRect(x: p.x - w / 2 + 5, y: p.y - h + 7, width: 5, height: 5)), with: .color(GlenInk.ink))
        context.fill(Path(CGRect(x: p.x + w / 2 - 9, y: p.y - h + 8, width: 4, height: 5)), with: .color(GlenInk.ink))
        context.fill(Path(CGRect(x: p.x + w / 3, y: p.y - h - 15, width: 4, height: 8)), with: .color(GlenInk.plaster))
        line(from: CGPoint(x: p.x - w / 2 + 7.5, y: p.y - h + 7), to: CGPoint(x: p.x - w / 2 + 7.5, y: p.y - h + 12), color: GlenInk.plaster, width: 0.6, in: &context)
        line(from: CGPoint(x: p.x - 3, y: p.y), to: CGPoint(x: p.x + 5, y: p.y + 1), color: GlenInk.plaster.opacity(0.8), width: 2, in: &context)
    }

    private static func pine(at p: CGPoint, height h: CGFloat, in context: inout GraphicsContext) {
        context.fill(Path(ellipseIn: CGRect(x: p.x - 9, y: p.y - 2, width: 22, height: 6)), with: .color(GlenInk.ink.opacity(0.14)))
        context.fill(Path(CGRect(x: p.x - 1, y: p.y - h / 3, width: 2, height: h / 3)), with: .color(GlenInk.timber))
        for tier in 0..<3 {
            let base = p.y - 4 - CGFloat(tier) * h * 0.19
            let halfWidth = h * (0.29 - CGFloat(tier) * 0.055)
            polygon([(p.x - halfWidth, base), (p.x, base - h * 0.55), (p.x + halfWidth, base)], fill: tier == 1 ? GlenInk.forest : GlenInk.ink.opacity(0.85), in: &context)
            polygon([(p.x, base), (p.x, base - h * 0.55), (p.x + halfWidth, base)], fill: GlenInk.sage.opacity(0.45), in: &context)
        }
    }

    private static func field(at p: CGPoint, in context: inout GraphicsContext) {
        polygon([(p.x - 13, p.y - 14), (p.x + 12, p.y - 22), (p.x + 25, p.y - 4), (p.x - 1, p.y + 4)], fill: GlenInk.timber.opacity(0.60), in: &context)
        for row in 0..<5 {
            line(from: CGPoint(x: p.x - 10 + CGFloat(row) * 3, y: p.y - 13 + CGFloat(row) * 3), to: CGPoint(x: p.x + 10 + CGFloat(row) * 3, y: p.y - 19 + CGFloat(row) * 3), color: GlenInk.ochre, width: 1.5, in: &context)
        }
    }

    private static func fence(from p: CGPoint, count: Int, in context: inout GraphicsContext) {
        let end = CGPoint(x: p.x + CGFloat(count - 1) * 7, y: p.y + CGFloat(count - 1))
        line(from: CGPoint(x: p.x, y: p.y - 6), to: CGPoint(x: end.x, y: end.y - 6), color: GlenInk.timber, width: 1, in: &context)
        line(from: CGPoint(x: p.x, y: p.y - 3), to: CGPoint(x: end.x, y: end.y - 3), color: GlenInk.timber, width: 1, in: &context)
        for index in 0..<count {
            line(from: CGPoint(x: p.x + CGFloat(index) * 7, y: p.y + CGFloat(index)), to: CGPoint(x: p.x + CGFloat(index) * 7, y: p.y + CGFloat(index) - 9), color: GlenInk.timber, width: 1.6, in: &context)
        }
    }

    private static func logs(at p: CGPoint, in context: inout GraphicsContext) {
        for index in 0..<3 {
            let y = p.y - CGFloat(index) * 3
            line(from: CGPoint(x: p.x - 8, y: y), to: CGPoint(x: p.x + 7, y: y - 3), color: GlenInk.timber, width: 3, in: &context)
            context.fill(Path(ellipseIn: CGRect(x: p.x - 10, y: y - 2, width: 4, height: 4)), with: .color(GlenInk.plaster))
        }
    }

    private static func well(at p: CGPoint, in context: inout GraphicsContext) {
        context.fill(Path(ellipseIn: CGRect(x: p.x - 11, y: p.y - 11, width: 24, height: 16)), with: .color(GlenInk.timber))
        context.fill(Path(ellipseIn: CGRect(x: p.x - 11, y: p.y - 15, width: 24, height: 13)), with: .color(GlenInk.plaster))
        context.fill(Path(ellipseIn: CGRect(x: p.x - 7, y: p.y - 12, width: 16, height: 7)), with: .color(GlenInk.water))
        for offset in [-11.0, 12.0] {
            line(from: CGPoint(x: p.x + offset, y: p.y), to: CGPoint(x: p.x + offset, y: p.y - 29), color: GlenInk.timber, width: 2.7, in: &context)
        }
        polygon([(p.x - 17, p.y - 25), (p.x - 2, p.y - 38), (p.x + 18, p.y - 24), (p.x + 2, p.y - 21)], fill: GlenInk.roof, in: &context)
        for row in 1...3 {
            let t = CGFloat(row) / 4
            line(from: CGPoint(x: p.x - 2 - 15 * t, y: p.y - 38 + 13 * t), to: CGPoint(x: p.x + 18 - 16 * t, y: p.y - 24 + 3 * t), color: GlenInk.parchment.opacity(0.22), width: 0.6, in: &context)
        }
        line(from: CGPoint(x: p.x + 1, y: p.y - 25), to: CGPoint(x: p.x + 1, y: p.y - 11), color: GlenInk.parchment, width: 0.8, in: &context)
        context.fill(Path(CGRect(x: p.x - 2, y: p.y - 13, width: 6, height: 4)), with: .color(GlenInk.timber))
    }

    private static func quarry(at p: CGPoint, in context: inout GraphicsContext) {
        let stone = GlenInk.parchment.opacity(0.85)
        for index in 0..<4 {
            let x = p.x - 19 + CGFloat(index % 2) * 13
            let y = p.y - 6 - CGFloat(index / 2) * 12
            polygon([(x, y), (x + 2, y - 9), (x + 13, y - 11), (x + 15, y - 2), (x + 10, y + 2)], fill: stone, in: &context)
            line(from: CGPoint(x: x + 2, y: y - 9), to: CGPoint(x: x + 11, y: y - 6), color: GlenInk.timber.opacity(0.40), width: 0.8, in: &context)
        }
        line(from: CGPoint(x: p.x + 13, y: p.y - 1), to: CGPoint(x: p.x + 13, y: p.y - 32), color: GlenInk.timber, width: 3, in: &context)
        line(from: CGPoint(x: p.x + 13, y: p.y - 31), to: CGPoint(x: p.x - 6, y: p.y - 31), color: GlenInk.timber, width: 2.5, in: &context)
        line(from: CGPoint(x: p.x - 4, y: p.y - 31), to: CGPoint(x: p.x - 4, y: p.y - 19), color: GlenInk.parchment, width: 0.8, in: &context)
        polygon([(p.x + 19, p.y + 2), (p.x + 32, p.y + 2), (p.x + 30, p.y - 6), (p.x + 17, p.y - 6)], fill: GlenInk.timber, in: &context)
        for offset in [20.0, 30.0] {
            context.fill(Path(ellipseIn: CGRect(x: p.x + offset - 2, y: p.y + 1, width: 4, height: 5)), with: .color(GlenInk.ink))
        }
    }

    private static func market(at p: CGPoint, in context: inout GraphicsContext) {
        for offset in [-12.0, 12.0] {
            line(from: CGPoint(x: p.x + offset, y: p.y + 2), to: CGPoint(x: p.x + offset, y: p.y - 19), color: GlenInk.timber, width: 1.7, in: &context)
        }
        polygon([(p.x - 15, p.y - 13), (p.x - 10, p.y - 24), (p.x + 15, p.y - 24), (p.x + 17, p.y - 13)], fill: GlenInk.parchment, in: &context)
        for index in 0..<3 {
            let x = p.x - 11 + CGFloat(index) * 9
            polygon([(x, p.y - 13), (x + 3, p.y - 24), (x + 7, p.y - 24), (x + 5, p.y - 13)], fill: GlenInk.rust, in: &context)
        }
        context.fill(Path(CGRect(x: p.x - 12, y: p.y - 7, width: 26, height: 7)), with: .color(GlenInk.timber))
        for index in 0..<5 {
            context.fill(Path(ellipseIn: CGRect(x: p.x - 9 + CGFloat(index) * 4, y: p.y - 9, width: 3.5, height: 3.5)), with: .color(index % 2 == 0 ? GlenInk.ochre : GlenInk.sage))
        }
    }

    private static func tower(at p: CGPoint, in context: inout GraphicsContext) {
        polygon([(p.x - 11, p.y), (p.x - 9, p.y - 36), (p.x + 9, p.y - 39), (p.x + 13, p.y - 3)], fill: GlenInk.plaster, in: &context)
        polygon([(p.x + 9, p.y - 39), (p.x + 17, p.y - 33), (p.x + 19, p.y - 9), (p.x + 13, p.y - 3)], fill: GlenInk.timber, in: &context)
        polygon([(p.x - 14, p.y - 34), (p.x - 1, p.y - 49), (p.x + 19, p.y - 34), (p.x + 4, p.y - 29)], fill: GlenInk.roof, in: &context)
        for level in 0..<2 {
            context.fill(Path(CGRect(x: p.x - 3, y: p.y - 26 + CGFloat(level) * 12, width: 4, height: 7)), with: .color(GlenInk.ink))
        }
    }

    private static func bridge(at p: CGPoint, built: Bool, in context: inout GraphicsContext) {
        if built {
            polygon([(p.x - 24, p.y - 9), (p.x + 22, p.y - 17), (p.x + 27, p.y - 3), (p.x - 19, p.y + 5)], fill: GlenInk.timber, in: &context)
            for index in 0..<10 {
                let x = p.x - 21 + CGFloat(index) * 4.5
                line(from: CGPoint(x: x, y: p.y - 8 - CGFloat(index) * 0.8), to: CGPoint(x: x + 4, y: p.y + 3 - CGFloat(index) * 0.8), color: GlenInk.plaster, width: 1.8, in: &context)
            }
            line(from: CGPoint(x: p.x - 24, y: p.y - 13), to: CGPoint(x: p.x + 22, y: p.y - 21), color: GlenInk.timber, width: 2, in: &context)
        } else {
            for index in 0..<5 {
                let x = p.x - 20 + CGFloat(index) * 10
                let y = p.y - 3 - CGFloat(index) * 2
                polygon([(x - 3, y), (x - 4, y - 5), (x + 3, y - 7), (x + 6, y - 2), (x + 2, y + 2)], fill: GlenInk.plaster, in: &context)
            }
        }
    }

    private static func tent(at p: CGPoint, in context: inout GraphicsContext) {
        groundShadow(at: p, width: 38, in: &context)
        polygon([(p.x - 12, p.y), (p.x - 2, p.y - 19), (p.x + 12, p.y - 3)], fill: GlenInk.plaster, in: &context)
        polygon([(p.x - 2, p.y - 19), (p.x + 8, p.y - 21), (p.x + 21, p.y - 6), (p.x + 12, p.y - 3)], fill: GlenInk.ochre, in: &context)
        polygon([(p.x - 3, p.y - 1), (p.x - 2, p.y - 12), (p.x + 5, p.y - 2)], fill: GlenInk.timber, in: &context)
        line(from: CGPoint(x: p.x + 8, y: p.y - 21), to: CGPoint(x: p.x + 15, y: p.y + 3), color: GlenInk.parchment.opacity(0.65), width: 0.55, in: &context)
        line(from: CGPoint(x: p.x - 2, y: p.y - 19), to: CGPoint(x: p.x - 17, y: p.y + 2), color: GlenInk.parchment.opacity(0.65), width: 0.55, in: &context)
    }

    private static func flag(at p: CGPoint, secured: Bool, in context: inout GraphicsContext) {
        line(from: p, to: CGPoint(x: p.x, y: p.y - 23), color: GlenInk.timber, width: 1.2, in: &context)
        polygon([(p.x, p.y - 23), (p.x + 11, p.y - 21), (p.x + 8, p.y - 17), (p.x + 11, p.y - 13), (p.x, p.y - 15)], fill: secured ? GlenInk.banner : GlenInk.rust, in: &context)
        if !secured {
            line(from: CGPoint(x: p.x + 4, y: p.y - 21), to: CGPoint(x: p.x + 4, y: p.y - 17), color: GlenInk.parchment, width: 1.3, in: &context)
        }
    }

    static func person(at p: CGPoint, coat: Color, hero: Bool, in context: inout GraphicsContext) {
        let scale: CGFloat = hero ? 1.45 : 1
        context.fill(Path(ellipseIn: CGRect(x: p.x - 4 * scale, y: p.y - 1, width: 10 * scale, height: 4 * scale)), with: .color(GlenInk.ink.opacity(0.25)))
        line(from: CGPoint(x: p.x - 1.5 * scale, y: p.y - 6 * scale), to: CGPoint(x: p.x - 2 * scale, y: p.y), color: GlenInk.ink, width: 1.8 * scale, in: &context)
        line(from: CGPoint(x: p.x + 1.5 * scale, y: p.y - 6 * scale), to: CGPoint(x: p.x + 2.5 * scale, y: p.y), color: GlenInk.ink, width: 1.8 * scale, in: &context)
        polygon([(p.x - 2 * scale, p.y - 12 * scale), (p.x + 2 * scale, p.y - 12 * scale), (p.x + 4 * scale, p.y - 5 * scale), (p.x - 4 * scale, p.y - 5 * scale)], fill: coat, in: &context)
        context.fill(Path(ellipseIn: CGRect(x: p.x - 2 * scale, y: p.y - 16 * scale, width: 4 * scale, height: 4 * scale)), with: .color(GlenInk.plaster))
        line(from: CGPoint(x: p.x - 4 * scale, y: p.y - 14 * scale), to: CGPoint(x: p.x + 4 * scale, y: p.y - 14 * scale), color: GlenInk.timber, width: 1.3 * scale, in: &context)
        if hero {
            context.fill(Path(CGRect(x: p.x - 2 * scale, y: p.y - 17 * scale, width: 4 * scale, height: 3 * scale)), with: .color(GlenInk.timber))
            line(from: CGPoint(x: p.x + 4, y: p.y - 10), to: CGPoint(x: p.x + 8, y: p.y - 2), color: GlenInk.parchment, width: 1.2, in: &context)
        }
    }

    private static func polygon(_ coordinates: [(CGFloat, CGFloat)], fill: Color, in context: inout GraphicsContext) {
        guard let first = coordinates.first else { return }
        var path = Path()
        path.move(to: CGPoint(x: first.0, y: first.1))
        for coordinate in coordinates.dropFirst() { path.addLine(to: CGPoint(x: coordinate.0, y: coordinate.1)) }
        path.closeSubpath()
        context.fill(path, with: .color(fill))
        let bounds = path.boundingRect
        context.fill(path, with: .linearGradient(
            Gradient(colors: [GlenInk.parchment.opacity(0.15), .clear, GlenInk.ink.opacity(0.24)]),
            startPoint: CGPoint(x: bounds.minX, y: bounds.minY),
            endPoint: CGPoint(x: bounds.maxX, y: bounds.maxY)
        ))
    }

    private static func groundShadow(at point: CGPoint, width: CGFloat, in context: inout GraphicsContext) {
        var shadow = context
        shadow.translateBy(x: point.x + 6, y: point.y + 2)
        shadow.scaleBy(x: 1, y: 0.29)
        shadow.fill(
            Path(ellipseIn: CGRect(x: -width / 2, y: -width / 2, width: width, height: width)),
            with: .radialGradient(Gradient(colors: [GlenInk.ink.opacity(0.46), GlenInk.ink.opacity(0.18), .clear]), center: .zero, startRadius: 0, endRadius: width / 2)
        )
    }

    private static func line(from start: CGPoint, to end: CGPoint, color: Color, width: CGFloat, in context: inout GraphicsContext) {
        var path = Path()
        path.move(to: start)
        path.addLine(to: end)
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round))
    }
}
