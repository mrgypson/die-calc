import SwiftUI

@main
struct DieCalcApp: App {
    var body: some Scene {
        WindowGroup {
            CalculatorRootView()
        }
    }
}

/// Owns `@AppStorage` for the skin and injects theme + skin writer into the calculator.
struct CalculatorRootView: View {
    @AppStorage(CalculatorSkin.appStorageKey) private var skinRaw: String = CalculatorSkin.vintage.rawValue
    @StateObject private var calculator = CalculatorViewModel()

    private var selectedSkin: CalculatorSkin {
        CalculatorSkin(rawValue: skinRaw) ?? .vintage
    }

    var body: some View {
        VintageCalculatorView(model: calculator)
            .calculatorTheme(selectedSkin.theme)
            .preferredColorScheme(.dark)
            .onAppear {
                calculator.applySkin = { skin in
                    skinRaw = skin.rawValue
                }
            }
    }
}
