import SwiftUI

extension CalculatorTheme {
    static let vintage: CalculatorTheme = CalculatorTheme(
        page: Page(
            background: .linearGradient(
                top: Color(red: 0.12, green: 0.11, blue: 0.10),
                bottom: Color(red: 0.06, green: 0.05, blue: 0.05)
            )
        ),
        keys: Keys(
            chromeStyle: .roundedGradient,
            faceTop: Color(red: 0.24, green: 0.22, blue: 0.21),
            faceBottom: Color(red: 0.14, green: 0.13, blue: 0.12),
            stroke: Color.white.opacity(0.12),
            label: Color(red: 0.95, green: 0.94, blue: 0.90),
            keyShadow: Color.black.opacity(0.35),
            sumTotFaceTop: Color(red: 0.34, green: 0.32, blue: 0.30),
            sumTotFaceBottom: Color(red: 0.18, green: 0.16, blue: 0.15),
            sumTotAccent: Color(red: 1.0, green: 0.48, blue: 0.12),
            sumTotStroke: Color.white.opacity(0.1)
        ),
        lcd: LCD(
            panelBackground: Color(red: 0.722, green: 0.765, blue: 0.663),
            foreground: Color(red: 0.227, green: 0.239, blue: 0.227),
            foregroundDim: Color(red: 0.227, green: 0.239, blue: 0.227).opacity(0.72),
            bezelOuterStroke: Color.black.opacity(0.22),
            bezelInnerGradient: [
                Color.black.opacity(0.28),
                Color.black.opacity(0.06),
                Color.white.opacity(0.12),
            ],
            bezelShadow: Color.black.opacity(0.4),
            bezelHighlightStroke: Color.white.opacity(0.14),
            captionFont: .system(size: 9, weight: .bold, design: .default),
            expressionFont: .system(size: 13, weight: .semibold, design: .monospaced),
            expressionSmallFont: .system(size: 11, weight: .medium, design: .monospaced),
            primaryReadoutFont: .system(size: 46, weight: .heavy, design: .rounded),
            primaryReadoutItalic: true,
            useFlatBezel: false
        ),
        actions: Actions(
            clearTop: Color(red: 0.32, green: 0.22, blue: 0.20),
            clearBottom: Color(red: 0.22, green: 0.14, blue: 0.12),
            clearStroke: Color.white.opacity(0.12),
            clearIconRing: Color(red: 0.92, green: 0.88, blue: 0.82),
            clearIcon: Color(red: 0.95, green: 0.92, blue: 0.88),
            rollTop: Color(red: 0.92, green: 0.88, blue: 0.78),
            rollBottom: Color(red: 0.72, green: 0.68, blue: 0.58),
            rollStroke: Color.white.opacity(0.35),
            rollForeground: Color(red: 0.08, green: 0.08, blue: 0.08),
            rollTitleFont: .system(size: 22, weight: .bold, design: .rounded),
            clearIconFont: .system(size: 14, weight: .bold)
        ),
        modifiers: Modifiers(
            advantage: Color(red: 0.28, green: 0.62, blue: 1.0),
            doubleAdvantage: Color(red: 0.22, green: 0.78, blue: 0.76),
            disadvantage: Color(red: 0.95, green: 0.22, blue: 0.22),
            ledOff: Color(red: 0.15, green: 0.13, blue: 0.12)
        ),
        tierLED: TierLED(
            off: Color(red: 0.15, green: 0.13, blue: 0.12),
            cycle: [
                Color(red: 0.22, green: 0.88, blue: 0.38),
                Color(red: 0.28, green: 0.62, blue: 1.0),
                Color(red: 0.62, green: 0.32, blue: 0.92),
                Color(red: 0.95, green: 0.22, blue: 0.22),
                Color(red: 1.0, green: 0.48, blue: 0.12),
            ]
        ),
        chrome: Chrome(
            sectionLabel: Color(red: 0.75, green: 0.72, blue: 0.65),
            dieGlyph: Color.white,
            keyLabelFont: .system(size: 17, weight: .semibold, design: .rounded),
            modifierLabelFont: .system(size: 12, weight: .bold, design: .rounded),
            sumTotLabelFont: .system(size: 12, weight: .bold, design: .rounded)
        )
    )
}
