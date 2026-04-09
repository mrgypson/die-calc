import SwiftUI

extension CalculatorTheme {
    /// Classic Macintosh System 1–style monochrome: dithered “desktop,” raised white keys, black ink.
    static let antiqueApple: CalculatorTheme = CalculatorTheme(
        page: Page(background: .checkerboardDither),
        keys: Keys(
            chromeStyle: .macSystem1Raised,
            faceTop: .white,
            faceBottom: .white,
            stroke: .black,
            label: .black,
            keyShadow: .clear,
            sumTotFaceTop: .white,
            sumTotFaceBottom: .white,
            sumTotAccent: .black,
            sumTotStroke: .black
        ),
        lcd: LCD(
            panelBackground: .white,
            foreground: .black,
            foregroundDim: Color(white: 0.35),
            bezelOuterStroke: .black,
            bezelInnerGradient: [
                Color.clear,
                Color.clear,
                Color.clear,
            ],
            bezelShadow: Color.black.opacity(0.22),
            bezelHighlightStroke: Color.clear,
            captionFont: .system(size: 10, weight: .bold, design: .default),
            expressionFont: .system(size: 13, weight: .semibold, design: .monospaced),
            expressionSmallFont: .system(size: 11, weight: .medium, design: .monospaced),
            primaryReadoutFont: .system(size: 46, weight: .bold, design: .monospaced),
            primaryReadoutItalic: false,
            useFlatBezel: true
        ),
        actions: Actions(
            clearTop: .white,
            clearBottom: .white,
            clearStroke: .black,
            clearIconRing: .black,
            clearIcon: .black,
            rollTop: .white,
            rollBottom: .white,
            rollStroke: .black,
            rollForeground: .black,
            rollTitleFont: .system(size: 22, weight: .bold, design: .default),
            clearIconFont: .system(size: 15, weight: .bold, design: .default)
        ),
        modifiers: Modifiers(
            advantage: Color(white: 0.22),
            doubleAdvantage: Color(white: 0.38),
            disadvantage: Color(white: 0.55),
            ledOff: Color(white: 0.88)
        ),
        tierLED: TierLED(
            off: Color(white: 0.88),
            cycle: [
                Color(white: 0.15),
                Color(white: 0.32),
                Color(white: 0.48),
                Color(white: 0.62),
                Color(white: 0.78),
            ]
        ),
        chrome: Chrome(
            sectionLabel: .black,
            dieGlyph: .black,
            keyLabelFont: .system(size: 18, weight: .medium, design: .default),
            modifierLabelFont: .system(size: 12, weight: .heavy, design: .default),
            sumTotLabelFont: .system(size: 12, weight: .heavy, design: .default)
        )
    )
}
