import SwiftUI
import UIKit

// MARK: - Colors

struct AppColors {
    // Navigation, text links, icons
    static let blauw3 = Color(hex: "1261A3")
    static let blauw1 = Color(hex: "DAEBFA")

    // Primary
    static let groen3 = Color(hex: "248641")
    static let groen4 = Color(hex: "1D6B34")
    static let groen1 = Color(hex: "D5E7D4")   // lichte vulling, o.a. geselecteerde chip
    static let warmGrijs = Color(hex: "F8F7F5")
    static let geel3 = Color(hex: "F8D62D")
    static let geel2 = Color(hex: "FFEB85")
    static let geel1 = Color(hex: "FFF7D1")
    static let rood = Color(hex: "CF1C08")

    // Neutrals
    static let textPrimary = Color(hex: "1A1A1A")
    static let textSecondary = Color(hex: "4B4B4B")
    static let darkGrey = Color(hex: "2D2D2D")
    static let grijs2 = Color(hex: "D2D2D2")
    static let grijs4 = Color(hex: "767676")
    static let tegelBorder = Color(hex: "EBEAE6")
    static let background = Color.white
    static let backgroundGrey = Color(hex: "F8F7F5")
}

// MARK: - Typography

struct AppFont {
    // Heading Large: TheMixB, 22px, weight 540
    static func headingLarge() -> Font {
        .custom("TheMixB-W6SemiBold", size: 22)
    }

    // Heading Medium: TheSans C4s, 18px, weight 530, letter-spacing 0.1
    static func headingMedium() -> Font {
        .custom("TheSansC4s-SemiBold", size: 18)
    }

    // Body Regular: TheSans C4s, 16px, weight 500
    static func bodyRegular() -> Font {
        .custom("TheSansC4s-Regular", size: 16)
    }

    // Body Bold: TheSans C4s, 18px, weight 530
    static func bodyBold() -> Font {
        .custom("TheSansC4s-SemiBold", size: 18)
    }

    // Custom sizes
    static func theSans(size: CGFloat, weight: TheSansWeight = .plain) -> Font {
        .custom(weight.fontName, size: size)
    }

    static func theMix(size: CGFloat, weight: TheMixWeight = .semiBold) -> Font {
        .custom(weight.fontName, size: size)
    }

    enum TheSansWeight: String {
        case light = "TheSansC4s-Light"
        case semiLight = "TheSansC4s-SemiLight"
        case plain = "TheSansC4s-Regular"
        case semiBold = "TheSansC4s-SemiBold"
        case bold = "TheSansC4s-Bold"
        case extraBold = "TheSansC4s-ExtraBold"

        var fontName: String { rawValue }
    }

    enum TheMixWeight: String {
        case plain = "TheMixB-W5Plain"
        case semiBold = "TheMixB-W6SemiBold"
        case bold = "TheMixB-W7Bold"
        case extraBold = "TheMixB-W8ExtraBold"

        var fontName: String { rawValue }
    }
}

// MARK: - Design Constants

struct AppDesign {
    static let cornerRadius: CGFloat = 6
    static let horizontalPadding: CGFloat = 20
    static let cardSpacing: CGFloat = 12
    static let sectionSpacing: CGFloat = 40

    /// Hoogte van de top-safe-area (notch / Dynamic Island) van het actieve venster.
    static var safeAreaTop: CGFloat {
        (UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .safeAreaInsets.top) ?? 59
    }
}

// MARK: - Carrousel-clip

/// Clipt een view ALLEEN horizontaal (op de eigen breedte) en laat verticaal ver
/// doorlopen. Bedoeld om strak om een `scrollClipDisabled`-carrousel te zetten:
/// schaduwen en de oplopende schaal van het centrale kaartje mogen verticaal
/// overlopen, maar de buur-kaartjes kunnen nóóit horizontaal buiten het scherm
/// (en dus achter een andere tab) terechtkomen.
struct HorizontalOverflowClip: Shape {
    func path(in rect: CGRect) -> Path {
        Path(CGRect(x: rect.minX, y: rect.minY - 2000, width: rect.width, height: rect.height + 4000))
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
