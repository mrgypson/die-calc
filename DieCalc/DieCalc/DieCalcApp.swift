import SwiftUI

@main
struct DieCalcApp: App {
    @StateObject private var calculator = CalculatorViewModel()

    var body: some Scene {
        WindowGroup {
            VintageCalculatorView(model: calculator)
                .preferredColorScheme(.dark)
        }
    }
}
