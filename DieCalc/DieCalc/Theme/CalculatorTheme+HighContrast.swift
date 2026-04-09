import SwiftUI

extension CalculatorTheme {
    /// Alternate skin: cool gray page, near-black keys, amber LCD for easy visual distinction when testing.
    static let highContrast: CalculatorTheme = CalculatorTheme(
        page: Page(
            background: .linearGradient(
                top: Color(red: 0.18, green: 0.20, blue: 0.24),
                bottom: Color(red: 0.06, green: 0.07, blue: 0.10)
            )
        ),
        keys: Keys(
            chromeStyle: .roundedGradient,
            faceTop: Color(red: 0.12, green: 0.12, blue: 0.14),
            faceBottom: Color(red: 0.05, green: 0.05, blue: 0.07),
            stroke: Color.white.opacity(0.22),
            label: Color(red: 1.0, green: 1.0, blue: 1.0),
            keyShadow: Color.black.opacity(0.5),
            sumTotFaceTop: Color(red: 0.22, green: 0.22, blue: 0.26),
            sumTotFaceBottom: Color(red: 0.10, green: 0.10, blue: 0.12),
            sumTotAccent: Color(red: 1.0, green: 0.75, blue: 0.2),
            sumTotStroke: Color.white.opacity(0.2)
        ),
        lcd: LCD(
            panelBackground: Color(red: 0.12, green: 0.14, blue: 0.12),
            foreground: Color(red: 1.0, green: 0.85, blue: 0.35),
            foregroundDim: Color(red: 1.0, green: 0.85, blue: 0.35).opacity(0.75),
            bezelOuterStroke: Color.black.opacity(0.5),
            bezelInnerGradient: [
                Color.white.opacity(0.15),
                Color.black.opacity(0.2),
                Color.white.opacity(0.08),
            ],
            bezelShadow: Color.black.opacity(0.55),
            bezelHighlightStroke: Color.white.opacity(0.25),
            captionFont: .system(size: 9, weight: .bold, design: .default),
            expressionFont: .system(size: 13, weight: .semibold, design: .monospaced),
            expressionSmallFont: .system(size: 11, weight: .medium, design: .monospaced),
            primaryReadoutFont: .system(size: 46, weight: .heavy, design: .rounded),
            primaryReadoutItalic: true,
            useFlatBezel: false
        ),
        actions: Actions(
            clearTop: Color(red: 0.35, green: 0.15, blue: 0.15),
            clearBottom: Color(red: 0.2, green: 0.08, blue: 0.08),
            clearStroke: Color.white.opacity(0.25),
            clearIconRing: Color(red: 1.0, green: 0.85, blue: 0.85),
            clearIcon: Color.white,
            rollTop: Color(red: 1.0, green: 0.92, blue: 0.55),
            rollBottom: Color(red: 0.85, green: 0.65, blue: 0.2),
            rollStroke: Color.white.opacity(0.45),
            rollForeground: Color.black,
            rollTitleFont: .system(size: 22, weight: .bold, design: .rounded),
            clearIconFont: .system(size: 14, weight: .bold)
        ),
        modifiers: Modifiers(
            advantage: Color(red: 0.4, green: 0.75, blue: 1.0),
            doubleAdvantage: Color(red: 0.35, green: 0.95, blue: 0.9),
            disadvantage: Color(red: 1.0, green: 0.45, blue: 0.45),
            ledOff: Color(red: 0.1, green: 0.1, blue: 0.12)
        ),
        tierLED: TierLED(
            off: Color(red: 0.1, green: 0.1, blue: 0.12),
            cycle: [
                Color(red: 0.3, green: 1.0, blue: 0.45),
                Color(red: 0.45, green: 0.75, blue: 1.0),
                Color(red: 0.85, green: 0.5, blue: 1.0),
                Color(red: 1.0, green: 0.35, blue: 0.35),
                Color(red: 1.0, green: 0.75, blue: 0.2),
            ]
        ),
        chrome: Chrome(
            sectionLabel: Color(red: 0.85, green: 0.88, blue: 0.92),
            dieGlyph: Color(red: 1.0, green: 0.92, blue: 0.55),
            keyLabelFont: .system(size: 17, weight: .semibold, design: .rounded),
            modifierLabelFont: .system(size: 12, weight: .bold, design: .rounded),
            sumTotLabelFont: .system(size: 12, weight: .bold, design: .rounded)
        )
    )
}
