import DieCalcCore
import SwiftUI
import UIKit

/// Physical 1–20 sum (table) or digital dice pool—mutually exclusive; one combined readout.
@MainActor
final class CalculatorViewModel: ObservableObject {
    /// LCD upper band: full sum / roll detail vs. large total only.
    enum ReadoutBandMode: String, CaseIterable, Hashable {
        case sum
        case total
    }

    enum DigitalDie: Int, CaseIterable, Identifiable, Hashable {
        case d4 = 4
        case d6 = 6
        case d8 = 8
        case d10 = 10
        case d12 = 12
        case d20 = 20
        case d100 = 100

        var id: Int { rawValue }
        var label: String { "d\(rawValue)" }

        /// Shown in the selection summary, e.g. `2d6` / `2d100`. Pool key text for d100 is `100` beside the `%` glyph in the view.
        var buttonCaption: String { "d\(rawValue)" }
    }

    @Published private(set) var physicalRunningTotal: Int = 0

    /// Taps per table key (1…20) for LED indicators; unbounded count drives amber / red / purple tiers.
    @Published private(set) var physicalPressCounts: [Int: Int] = [:]

    /// Order of table key values tapped (1…20), for expression readout e.g. `1+5+10=`.
    @Published private(set) var physicalTapSequence: [Int] = []

    /// Taps per roll-pool die (1…`DiceEngine.maxPoolDicePerType`); roll count equals tap count. LEDs cycle amber → red → purple every 5 taps (visual only).
    @Published private(set) var digitalPressCounts: [DigitalDie: Int] = Dictionary(
        uniqueKeysWithValues: DigitalDie.allCases.map { ($0, 0) }
    )

    @Published private(set) var lastDigitalRoll: DiceEngine.MultiPoolRollResult?
    @Published private(set) var digitalError: String?

    /// `true` = readout shows table total; `false` = readout shows dice selection / roll / error.
    @Published private(set) var showingTableReadout: Bool = true

    @Published var readoutBandMode: ReadoutBandMode = .sum

    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)

    var readoutCaption: String {
        showingTableReadout ? "Table" : "Dice"
    }

    /// Table LCD: two-digit style total.
    var tableReadoutText: String {
        Self.formatTableDisplay(physicalRunningTotal)
    }

    /// Table mode expression band: `SUM` when empty, else `1+1+5=23` with running total.
    var tableExpressionLine: String {
        if physicalTapSequence.isEmpty {
            return "SUM"
        }
        let expr = physicalTapSequence.map(String.init).joined(separator: "+")
        return "\(expr)=\(physicalRunningTotal)"
    }

    /// Dice mode: pool tally shown in the LCD (always; `—` when nothing selected).
    var dicePoolSelectionTally: String {
        guard !showingTableReadout else { return "" }
        let compact = digitalSelectionSummaryCondensed()
        return compact.isEmpty ? "—" : compact
    }

    /// Dice mode: roll breakdown, error, or empty while only editing the pool.
    var diceDetailLine: String {
        guard !showingTableReadout else { return "" }
        if let err = digitalError {
            return err
        }
        if let roll = lastDigitalRoll {
            return roll.groups.map { group in
                let nums = group.rolls.map(String.init).joined(separator: ",")
                return "d\(group.sides)[\(nums)]=\(group.subtotal)"
            }.joined(separator: " · ")
        }
        return ""
    }

    /// Dice mode, large readout: total like table calculator, or placeholder / error state.
    var diceTotalLine: String {
        guard !showingTableReadout else { return "" }
        if digitalError != nil {
            return "--"
        }
        if let roll = lastDigitalRoll {
            return Self.formatTableDisplay(roll.grandTotal)
        }
        return "--"
    }

    private static func formatTableDisplay(_ total: Int) -> String {
        if total >= 0, total <= 99 {
            return String(format: "%02d", total)
        }
        return "\(total)"
    }

    func tapPhysicalNumber(_ value: Int) {
        guard (1 ... 20).contains(value) else { return }
        clearDigitalState()
        showingTableReadout = true
        physicalRunningTotal += value
        var next = physicalPressCounts
        next[value, default: 0] += 1
        physicalPressCounts = next
        physicalTapSequence.append(value)
        impactLight.prepare()
        impactLight.impactOccurred(intensity: 0.5)
    }

    func physicalPressCount(for key: Int) -> Int {
        physicalPressCounts[key, default: 0]
    }

    func digitalPressCount(for die: DigitalDie) -> Int {
        digitalPressCounts[die, default: 0]
    }

    /// How many dice of this type to roll (same as tap count). LEDs are visual tiers only.
    func digitalPoolCount(for die: DigitalDie) -> Int {
        digitalPressCount(for: die)
    }

    func tapDigitalDie(_ die: DigitalDie) {
        clearPhysicalState()
        showingTableReadout = false
        digitalError = nil
        let current = digitalPressCounts[die, default: 0]
        guard current < DiceEngine.maxPoolDicePerType else { return }
        var next = digitalPressCounts
        next[die, default: 0] += 1
        digitalPressCounts = next
        impactLight.prepare()
        impactLight.impactOccurred(intensity: 0.4)
    }

    /// Clears table total and digital dice state.
    func clearAll() {
        clearPhysicalState()
        clearDigitalState()
        showingTableReadout = true
        impactMedium.prepare()
        impactMedium.impactOccurred(intensity: 0.6)
    }

    func rollDigital() {
        clearPhysicalState()
        showingTableReadout = false
        digitalError = nil
        let pools: [(sides: Int, count: Int)] = DigitalDie.allCases.map { die in
            (sides: die.rawValue, count: digitalPoolCount(for: die))
        }
        do {
            let result = try DiceEngine.rollPools(pools: pools)
            lastDigitalRoll = result
            impactMedium.prepare()
            impactMedium.impactOccurred(intensity: 0.85)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch DiceEngine.DiceError.noDiceSelected {
            digitalError = "Select dice"
            lastDigitalRoll = nil
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        } catch {
            digitalError = "Can't roll"
            lastDigitalRoll = nil
        }
    }

    private func clearDigitalState() {
        digitalError = nil
        lastDigitalRoll = nil
        digitalPressCounts = Dictionary(uniqueKeysWithValues: DigitalDie.allCases.map { ($0, 0) })
    }

    private func clearPhysicalState() {
        physicalRunningTotal = 0
        physicalPressCounts = [:]
        physicalTapSequence = []
    }

    /// Compact pool text, e.g. `2d4+1d6` (uses current tier dice counts).
    private func digitalSelectionSummaryCondensed() -> String {
        let parts = DigitalDie.allCases.compactMap { die -> String? in
            let c = digitalPoolCount(for: die)
            guard c > 0 else { return nil }
            return "\(c)\(die.buttonCaption)"
        }
        return parts.joined(separator: "+")
    }
}
