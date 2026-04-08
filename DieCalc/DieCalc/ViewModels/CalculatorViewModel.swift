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

    /// Active modifier when tapping dice after ADV / 2X ADV / DIS.
    enum PoolAssignmentMode: String, CaseIterable, Hashable {
        case none
        case advantage
        case doubleAdvantage
        case disadvantage
    }

    @Published private(set) var physicalRunningTotal: Int = 0

    /// Taps per table key (1…20) for LED indicators; unbounded count drives amber / red / purple tiers.
    @Published private(set) var physicalPressCounts: [Int: Int] = [:]

    /// Order of table key values tapped (1…20), for expression readout e.g. `1+1+5=`.
    @Published private(set) var physicalTapSequence: [Int] = []

    /// Per die: normal / advantage / double advantage / disadvantage counts, plus tier tap count for key-cap LEDs.
    @Published private(set) var digitalPoolState: DigitalPoolState = .empty()

    @Published private(set) var poolAssignmentMode: PoolAssignmentMode = .none

    @Published private(set) var lastDigitalRoll: DiceEngine.MultiPoolRollResult?
    @Published private(set) var digitalError: String?

    /// `true` = readout shows table total; `false` = readout shows dice selection / roll / error.
    @Published private(set) var showingTableReadout: Bool = true

    @Published var readoutBandMode: ReadoutBandMode = .sum

    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)

    /// After a long-press remove, the same touch can still deliver a button tap; skip one add for that die.
    private var skipNextTapForDie: DigitalDie?

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
            return roll.groups.map(Self.formatRollGroup).joined(separator: " · ")
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

    private static func formatRollGroup(_ group: DiceEngine.PoolRollGroup) -> String {
        let inner = zip(group.rolls, group.underlyingRolls).map { kept, under -> String in
            if under.count == 1 {
                return String(under[0])
            }
            let u = under.map(String.init).joined(separator: ",")
            return "\(u)→\(kept)"
        }.joined(separator: ",")
        return "d\(group.sides)[\(inner)]=\(group.subtotal)"
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

    /// Tier LED count for this pool key (every die tap advances tiers).
    func digitalPressCount(for die: DigitalDie) -> Int {
        digitalPoolState.tierTaps[die, default: 0]
    }

    /// Total dice of this type in the pool.
    func digitalPoolCount(for die: DigitalDie) -> Int {
        digitalPoolState.total(for: die)
    }

    func togglePoolAssignmentMode(_ target: PoolAssignmentMode) {
        guard target != .none else { return }
        if poolAssignmentMode == target {
            poolAssignmentMode = .none
        } else {
            poolAssignmentMode = target
        }
    }

    func tapDigitalDie(_ die: DigitalDie) {
        if skipNextTapForDie == die {
            skipNextTapForDie = nil
            return
        }

        clearPhysicalState()
        showingTableReadout = false
        digitalError = nil

        let maxC = DiceEngine.maxPoolDicePerType
        var next = digitalPoolState

        switch poolAssignmentMode {
        case .none:
            guard next.total(for: die) < maxC else { return }
            next.normal[die, default: 0] += 1
            next.tierTaps[die, default: 0] += 1
        case .advantage:
            guard next.applyAssignment(die: die, mode: .advantage, maxPerType: maxC) else { return }
        case .doubleAdvantage:
            guard next.applyAssignment(die: die, mode: .doubleAdvantage, maxPerType: maxC) else { return }
        case .disadvantage:
            guard next.applyAssignment(die: die, mode: .disadvantage, maxPerType: maxC) else { return }
        }

        digitalPoolState = next
        impactLight.prepare()
        impactLight.impactOccurred(intensity: 0.4)
    }

    /// Removes one die of this type from the pool (normal, then disadvantage, advantage, double advantage). No-op if none.
    func removeOneDigitalDie(_ die: DigitalDie) {
        clearPhysicalState()
        showingTableReadout = false
        digitalError = nil

        var next = digitalPoolState
        guard next.total(for: die) > 0 else { return }

        if next.normal[die, default: 0] > 0 {
            next.normal[die, default: 0] -= 1
        } else if next.disadvantage[die, default: 0] > 0 {
            next.disadvantage[die, default: 0] -= 1
        } else if next.advantage[die, default: 0] > 0 {
            next.advantage[die, default: 0] -= 1
        } else if next.doubleAdvantage[die, default: 0] > 0 {
            next.doubleAdvantage[die, default: 0] -= 1
        }

        let t = next.tierTaps[die, default: 0]
        if t > 0 {
            next.tierTaps[die, default: 0] = t - 1
        }

        digitalPoolState = next
        skipNextTapForDie = die
        impactLight.prepare()
        impactLight.impactOccurred(intensity: 0.35)
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

        var pools: [(sides: Int, count: Int, modifier: DiceEngine.RollPoolModifier)] = []
        for die in DigitalDie.allCases {
            let s = digitalPoolState
            let n = s.normal[die, default: 0]
            if n > 0 { pools.append((die.rawValue, n, .normal)) }
            let a = s.advantage[die, default: 0]
            if a > 0 { pools.append((die.rawValue, a, .advantage)) }
            let a2 = s.doubleAdvantage[die, default: 0]
            if a2 > 0 { pools.append((die.rawValue, a2, .doubleAdvantage)) }
            let d = s.disadvantage[die, default: 0]
            if d > 0 { pools.append((die.rawValue, d, .disadvantage)) }
        }

        do {
            let result = try DiceEngine.rollPoolsWithModifiers(pools: pools)
            lastDigitalRoll = result
            poolAssignmentMode = .none
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
        digitalPoolState = .empty()
        poolAssignmentMode = .none
        skipNextTapForDie = nil
    }

    private func clearPhysicalState() {
        physicalRunningTotal = 0
        physicalPressCounts = [:]
        physicalTapSequence = []
    }

    /// Compact pool text, e.g. `2d4+1d6^+1d20^^`.
    private func digitalSelectionSummaryCondensed() -> String {
        var segments: [String] = []
        for die in DigitalDie.allCases {
            let s = digitalPoolState
            let cap = die.buttonCaption
            let n = s.normal[die, default: 0]
            if n > 0 { segments.append("\(n)\(cap)") }
            let a = s.advantage[die, default: 0]
            if a > 0 { segments.append("\(a)\(cap)^") }
            let a2 = s.doubleAdvantage[die, default: 0]
            if a2 > 0 { segments.append("\(a2)\(cap)^^") }
            let d = s.disadvantage[die, default: 0]
            if d > 0 { segments.append("\(d)\(cap)v") }
        }
        return segments.joined(separator: "+")
    }
}

// MARK: - Digital pool buckets

extension CalculatorViewModel {
    struct DigitalPoolState: Equatable {
        var normal: [DigitalDie: Int]
        var advantage: [DigitalDie: Int]
        var doubleAdvantage: [DigitalDie: Int]
        var disadvantage: [DigitalDie: Int]
        var tierTaps: [DigitalDie: Int]

        static func empty() -> DigitalPoolState {
            let z = Dictionary(uniqueKeysWithValues: DigitalDie.allCases.map { ($0, 0) })
            return DigitalPoolState(normal: z, advantage: z, doubleAdvantage: z, disadvantage: z, tierTaps: z)
        }

        func total(for die: DigitalDie) -> Int {
            normal[die, default: 0] + advantage[die, default: 0]
                + doubleAdvantage[die, default: 0] + disadvantage[die, default: 0]
        }

        /// Moves one from normal into the bucket, or adds one die in that bucket if no normal left. Returns false if capped.
        mutating func applyAssignment(die: DigitalDie, mode: PoolAssignmentMode, maxPerType: Int) -> Bool {
            guard mode != .none else { return false }
            if normal[die, default: 0] > 0 {
                normal[die, default: 0] -= 1
                switch mode {
                case .advantage: advantage[die, default: 0] += 1
                case .doubleAdvantage: doubleAdvantage[die, default: 0] += 1
                case .disadvantage: disadvantage[die, default: 0] += 1
                case .none: break
                }
                tierTaps[die, default: 0] += 1
                return true
            }
            guard total(for: die) < maxPerType else { return false }
            switch mode {
            case .advantage: advantage[die, default: 0] += 1
            case .doubleAdvantage: doubleAdvantage[die, default: 0] += 1
            case .disadvantage: disadvantage[die, default: 0] += 1
            case .none: break
            }
            tierTaps[die, default: 0] += 1
            return true
        }
    }
}
