import Foundation

/// Persisted app skin choice (`rawValue` stored in `AppStorage`).
enum CalculatorSkin: String, CaseIterable, Identifiable, Sendable {
    case vintage
    /// Contrasting palette for testing skin switching before a Settings UI exists.
    case highContrast
    /// Classic Macintosh System 1–style 1-bit monochrome and dithered desktop.
    case antiqueApple

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .vintage: "Vintage Apple"
        case .highContrast: "High Contrast"
        case .antiqueApple: "Antique Apple"
        }
    }

    var theme: CalculatorTheme {
        switch self {
        case .vintage: .vintage
        case .highContrast: .highContrast
        case .antiqueApple: .antiqueApple
        }
    }

    /// UserDefaults / `AppStorage` key. Bind a future Settings picker to this string (see `DieCalcApp`).
    static let appStorageKey = "selectedCalculatorSkin"
}
