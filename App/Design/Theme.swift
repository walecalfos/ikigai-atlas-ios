import SwiftUI
import FluentUI

/// Ikigai Atlas is built on Microsoft's Fluent 2 design system (MIT licence).
/// This file re-themes Fluent's alias tokens with the atlas palette: aizome indigo as the brand,
/// shell-white paper, sumi ink. Every colour, font, space and radius in the app comes from here.
enum AtlasTheme {
    static let theme: FluentTheme = FluentTheme(colorOverrides: colorOverrides,
                                                typographyOverrides: typographyOverrides)

    /// Makes the atlas theme the default for every Fluent control in the app.
    static func install() {
        FluentTheme.shared = theme
    }

    private static func dyn(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(light: Color(hexValue: light), dark: Color(hexValue: dark))
    }

    private static let colorOverrides: [FluentTheme.ColorToken: Color] = [
        // Neutrals: gofun paper and sumi ink
        .backgroundCanvas: dyn(0xF3F4F1, 0x0F141A),
        .background1: dyn(0xFBFBF9, 0x161D25),
        .background1Pressed: dyn(0xEEF0EC, 0x1E2731),
        .background2: dyn(0xF7F8F5, 0x1A222B),
        .background3: dyn(0xEEF0EC, 0x222B35),
        .background5: dyn(0xE6E9E6, 0x222B35),
        .foreground1: dyn(0x1B2026, 0xE7EAE7),
        .foreground2: dyn(0x55606B, 0xA2ACB6),
        .foreground3: dyn(0x6F7882, 0x8A949E),
        .foregroundOnColor: dyn(0xFFFFFF, 0x0F141A),
        .stroke1: dyn(0xC4C9C6, 0x3A4652),
        .stroke2: dyn(0xD8DCD9, 0x28323C),

        // Brand: aizome indigo
        .brandBackground1: dyn(0x274A73, 0x93B4DC),
        .brandBackground1Pressed: dyn(0x1E3A5B, 0x7FA3CF),
        .brandBackground1Selected: dyn(0x1E3A5B, 0xA9C4E6),
        .brandBackground2: dyn(0x3A5F8A, 0x7FA3CF),
        .brandBackgroundTint: dyn(0xE3E9F1, 0x1C2939),
        .brandForeground1: dyn(0x274A73, 0x93B4DC),
        .brandForeground1Pressed: dyn(0x1E3A5B, 0xA9C4E6),
        .brandForegroundTint: dyn(0x274A73, 0xB6CCE8),
        .brandStroke1: dyn(0x274A73, 0x93B4DC),
        .brandStroke1Pressed: dyn(0x1E3A5B, 0xA9C4E6),

        // Status
        .successForeground1: dyn(0x48703E, 0x96BE82),
        .warningForeground1: dyn(0x9A6316, 0xDEB068),
        .dangerForeground1: dyn(0x9B3B30, 0xE68C80),
        .dangerStroke1: dyn(0x9B3B30, 0xE68C80)
    ]

    /// Display sizes use Shippori Mincho B1 (SIL Open Font Licence); everything else stays on
    /// Apple's system font, as Fluent iOS intends.
    private static let typographyOverrides: [FluentTheme.TypographyToken: FontInfo] = [
        .display: FontInfo(name: "ShipporiMinchoB1-ExtraBold", size: 34, weight: .heavy),
        .largeTitle: FontInfo(name: "ShipporiMinchoB1-Bold", size: 28, weight: .bold),
        .title1: FontInfo(name: "ShipporiMinchoB1-Bold", size: 22, weight: .bold)
    ]
}

// MARK: - Token accessors for views

enum Palette {
    private static func c(_ token: FluentTheme.ColorToken) -> Color { FluentTheme.shared.swiftUIColor(token) }

    static var canvas: Color { c(.backgroundCanvas) }
    static var surface: Color { c(.background1) }
    static var surfacePressed: Color { c(.background1Pressed) }
    static var surfaceSunken: Color { c(.background3) }
    static var ink: Color { c(.foreground1) }
    static var ink2: Color { c(.foreground2) }
    static var ink3: Color { c(.foreground3) }
    static var line: Color { c(.stroke2) }
    static var lineStrong: Color { c(.stroke1) }
    static var brand: Color { c(.brandForeground1) }
    static var brandFill: Color { c(.brandBackground1) }
    static var brandTint: Color { c(.brandBackgroundTint) }
    static var onBrand: Color { c(.foregroundOnColor) }
    static var fed: Color { c(.successForeground1) }
    static var hungry: Color { c(.warningForeground1) }
    static var alert: Color { c(.dangerForeground1) }

    /// Mother-of-pearl, a nod to 甲斐 (kai), the shell in the word ikigai.
    static var nacre: LinearGradient {
        LinearGradient(colors: [
            Color(light: Color(hexValue: 0xECD3DC), dark: Color(hexValue: 0x4D3A45)),
            Color(light: Color(hexValue: 0xD9D3EF), dark: Color(hexValue: 0x403D5C)),
            Color(light: Color(hexValue: 0xC9E6E7), dark: Color(hexValue: 0x33504F)),
            Color(light: Color(hexValue: 0xEFE3C9), dark: Color(hexValue: 0x51493A)),
            Color(light: Color(hexValue: 0xE6D2E4), dark: Color(hexValue: 0x4A3A4C))
        ], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

enum Typo {
    private static func f(_ token: FluentTheme.TypographyToken) -> Font { Font.fluent(FluentTheme.shared.typographyInfo(token)) }

    /// Serif display, for the hero and the ikigai statement.
    static var display: Font { f(.display) }
    /// Serif, for screen titles.
    static var largeTitle: Font { f(.largeTitle) }
    /// Serif, for section titles and threads.
    static var title1: Font { f(.title1) }
    static var title2: Font { f(.title2) }
    static var title3: Font { f(.title3) }
    static var bodyStrong: Font { f(.body1Strong) }
    static var body: Font { f(.body1) }
    static var body2Strong: Font { f(.body2Strong) }
    static var body2: Font { f(.body2) }
    /// Serif, for the ikigai statement on the atlas.
    static var statement: Font { Font.fluent(FontInfo(name: "ShipporiMinchoB1-Bold", size: 24, weight: .bold)) }
    static var captionStrong: Font { f(.caption1Strong) }
    static var caption: Font { f(.caption1) }
    static var caption2: Font { f(.caption2) }
}

enum Space {
    static let xxs = GlobalTokens.spacing(.size40)
    static let xs = GlobalTokens.spacing(.size80)
    static let s = GlobalTokens.spacing(.size120)
    static let m = GlobalTokens.spacing(.size160)
    static let l = GlobalTokens.spacing(.size240)
    static let xl = GlobalTokens.spacing(.size320)
    static let xxl = GlobalTokens.spacing(.size480)
}

enum Radius {
    static let control = GlobalTokens.corner(.radius80)
    static let card = GlobalTokens.corner(.radius120)
    static let sheet = GlobalTokens.corner(.radius160)
}

enum Stroke {
    static let hairline = GlobalTokens.stroke(.width10)
    static let thick = GlobalTokens.stroke(.width20)
}

extension View {
    /// Applies the atlas Fluent theme and accent colour to a presentation root.
    func themed() -> some View {
        self
            .fluentTheme(AtlasTheme.theme)
            .tint(Palette.brand)
    }
}
