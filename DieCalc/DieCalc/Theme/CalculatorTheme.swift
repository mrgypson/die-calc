import SwiftUI

/// Semantic appearance tokens for the calculator UI. Layout stays in views; only visuals vary by skin.
struct CalculatorTheme {
    struct Page {
        enum Background: Equatable {
            case linearGradient(top: Color, bottom: Color)
            /// Classic Mac 1-bit “gray” via 2×2 black/white checkerboard.
            case checkerboardDither
        }

        var background: Background
    }

    struct Keys {
        /// Visual treatment for table/die/toolbar key caps (and matching action buttons when applied in views).
        enum ChromeStyle: Equatable {
            case roundedGradient
            /// Classic Mac OS 1-style: 1 pt top/left frame, solid bottom/right shadow.
            case macSystem1Raised
        }

        var chromeStyle: ChromeStyle
        var faceTop: Color
        var faceBottom: Color
        var stroke: Color
        var label: Color
        var keyShadow: Color
        var sumTotFaceTop: Color
        var sumTotFaceBottom: Color
        var sumTotAccent: Color
        var sumTotStroke: Color
    }

    struct LCD {
        var panelBackground: Color
        var foreground: Color
        var foregroundDim: Color
        var bezelOuterStroke: Color
        var bezelInnerGradient: [Color]
        var bezelShadow: Color
        var bezelHighlightStroke: Color
        var captionFont: Font
        var expressionFont: Font
        var expressionSmallFont: Font
        var primaryReadoutFont: Font
        /// When false, large readout matches flat Mac LCD (no italic, no faux glow).
        var primaryReadoutItalic: Bool
        /// When true, LCD uses a simple stroke + fill (no inner gradient bezel).
        var useFlatBezel: Bool
    }

    struct Actions {
        var clearTop: Color
        var clearBottom: Color
        var clearStroke: Color
        var clearIconRing: Color
        var clearIcon: Color
        var rollTop: Color
        var rollBottom: Color
        var rollStroke: Color
        var rollForeground: Color
        var rollTitleFont: Font
        var clearIconFont: Font
    }

    struct Modifiers {
        var advantage: Color
        var doubleAdvantage: Color
        var disadvantage: Color
        var ledOff: Color
    }

    struct TierLED {
        var off: Color
        var cycle: [Color]
    }

    struct Chrome {
        var sectionLabel: Color
        var dieGlyph: Color
        var keyLabelFont: Font
        var modifierLabelFont: Font
        var sumTotLabelFont: Font
    }

    var page: Page
    var keys: Keys
    var lcd: LCD
    var actions: Actions
    var modifiers: Modifiers
    var tierLED: TierLED
    var chrome: Chrome

    /// Key-cap tier LEDs: every 5 taps advances the palette (green → blue → purple → red → orange).
    func tieredLEDColor(index: Int, pressCount: Int) -> Color {
        let off = tierLED.off
        let palette = tierLED.cycle
        guard pressCount > 0, palette.count == 5 else { return off }
        let litInTier = (pressCount - 1) % 5 + 1
        guard index < litInTier else { return off }
        let colorTier = ((pressCount - 1) / 5) % 5
        return palette[colorTier]
    }
}
