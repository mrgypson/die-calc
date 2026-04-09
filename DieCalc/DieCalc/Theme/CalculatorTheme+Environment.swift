import SwiftUI

private struct CalculatorThemeKey: EnvironmentKey {
    static let defaultValue: CalculatorTheme = .vintage
}

extension EnvironmentValues {
    var calculatorTheme: CalculatorTheme {
        get { self[CalculatorThemeKey.self] }
        set { self[CalculatorThemeKey.self] = newValue }
    }
}

extension View {
    func calculatorTheme(_ theme: CalculatorTheme) -> some View {
        environment(\.calculatorTheme, theme)
    }
}
