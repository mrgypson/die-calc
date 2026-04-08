import Foundation

/// Pure dice resolution for TTRPG rolls (single expression: count × die + modifier, or multiple pools).
public enum DiceEngine {
    /// How each die in a pool is resolved (normal single roll, adv/dis multiple rolls keep one).
    public enum RollPoolModifier: Equatable, Sendable, Hashable {
        case normal
        /// Roll twice, keep the higher.
        case advantage
        /// Roll three times, keep the highest.
        case doubleAdvantage
        /// Roll twice, keep the lower.
        case disadvantage
    }

    public struct RollResult: Equatable, Sendable {
        public let rolls: [Int]
        public let modifier: Int
        public let total: Int

        public init(rolls: [Int], modifier: Int, total: Int) {
            self.rolls = rolls
            self.modifier = modifier
            self.total = total
        }
    }

    /// One segment’s rolls in a multi-pool result (`rolls` are kept values; `underlyingRolls` parallel per die).
    public struct PoolRollGroup: Equatable, Sendable {
        public let sides: Int
        /// Kept value per die (length equals number of dice in this segment).
        public let rolls: [Int]
        public let modifier: RollPoolModifier
        /// For each kept value in `rolls`, the raw dice rolled (1, 2, or 3 integers).
        public let underlyingRolls: [[Int]]

        public var subtotal: Int { rolls.reduce(0, +) }

        public init(sides: Int, rolls: [Int], modifier: RollPoolModifier, underlyingRolls: [[Int]]) {
            self.sides = sides
            self.rolls = rolls
            self.modifier = modifier
            self.underlyingRolls = underlyingRolls
        }

        /// Plain pool with no advantage (each underlying roll is a single value).
        public init(sides: Int, rolls: [Int]) {
            self.sides = sides
            self.rolls = rolls
            self.modifier = .normal
            self.underlyingRolls = rolls.map { [$0] }
        }
    }

    /// Result of rolling several pools (e.g. 2d6 + 1d20).
    public struct MultiPoolRollResult: Equatable, Sendable {
        public let groups: [PoolRollGroup]
        public let grandTotal: Int

        public init(groups: [PoolRollGroup], grandTotal: Int) {
            self.groups = groups
            self.grandTotal = grandTotal
        }
    }

    public enum DiceError: Error, Equatable, Sendable {
        case invalidSides(Int)
        case invalidCount(Int)
        case noDiceSelected
    }

    /// Maximum dice per type in one multi-pool roll (UI / sanity cap).
    public static let maxPoolDicePerType = 99

    /// Rolls multiple pools; entries with `count == 0` are skipped. Each non-zero count must be 1…`maxPoolDicePerType`.
    public static func rollPools(
        pools: [(sides: Int, count: Int)],
        rng: inout some RandomNumberGenerator
    ) throws -> MultiPoolRollResult {
        let active = pools.filter { $0.count > 0 }
        guard !active.isEmpty else { throw DiceError.noDiceSelected }

        var groups: [PoolRollGroup] = []
        groups.reserveCapacity(active.count)
        var grandTotal = 0

        for pool in active {
            guard pool.count >= 1, pool.count <= maxPoolDicePerType else { throw DiceError.invalidCount(pool.count) }
            guard pool.sides >= 2 else { throw DiceError.invalidSides(pool.sides) }

            var rolls: [Int] = []
            rolls.reserveCapacity(pool.count)
            for _ in 0 ..< pool.count {
                rolls.append(Int.random(in: 1 ... pool.sides, using: &rng))
            }
            let sub = rolls.reduce(0, +)
            grandTotal += sub
            groups.append(PoolRollGroup(sides: pool.sides, rolls: rolls))
        }

        return MultiPoolRollResult(groups: groups, grandTotal: grandTotal)
    }

    /// Rolls multiple segments; each segment uses one modifier (normal / advantage / double advantage / disadvantage).
    public static func rollPoolsWithModifiers(
        pools: [(sides: Int, count: Int, modifier: RollPoolModifier)],
        rng: inout some RandomNumberGenerator
    ) throws -> MultiPoolRollResult {
        let active = pools.filter { $0.count > 0 }
        guard !active.isEmpty else { throw DiceError.noDiceSelected }

        var groups: [PoolRollGroup] = []
        groups.reserveCapacity(active.count)
        var grandTotal = 0

        for pool in active {
            guard pool.count >= 1, pool.count <= maxPoolDicePerType else { throw DiceError.invalidCount(pool.count) }
            guard pool.sides >= 2 else { throw DiceError.invalidSides(pool.sides) }

            var kept: [Int] = []
            var underlying: [[Int]] = []
            kept.reserveCapacity(pool.count)
            underlying.reserveCapacity(pool.count)

            for _ in 0 ..< pool.count {
                switch pool.modifier {
                case .normal:
                    let v = Int.random(in: 1 ... pool.sides, using: &rng)
                    kept.append(v)
                    underlying.append([v])
                case .advantage:
                    let a = Int.random(in: 1 ... pool.sides, using: &rng)
                    let b = Int.random(in: 1 ... pool.sides, using: &rng)
                    underlying.append([a, b])
                    kept.append(max(a, b))
                case .doubleAdvantage:
                    let a = Int.random(in: 1 ... pool.sides, using: &rng)
                    let b = Int.random(in: 1 ... pool.sides, using: &rng)
                    let c = Int.random(in: 1 ... pool.sides, using: &rng)
                    underlying.append([a, b, c])
                    kept.append(max(a, max(b, c)))
                case .disadvantage:
                    let a = Int.random(in: 1 ... pool.sides, using: &rng)
                    let b = Int.random(in: 1 ... pool.sides, using: &rng)
                    underlying.append([a, b])
                    kept.append(min(a, b))
                }
            }

            let sub = kept.reduce(0, +)
            grandTotal += sub
            groups.append(
                PoolRollGroup(
                    sides: pool.sides,
                    rolls: kept,
                    modifier: pool.modifier,
                    underlyingRolls: underlying
                )
            )
        }

        return MultiPoolRollResult(groups: groups, grandTotal: grandTotal)
    }

    public static func rollPoolsWithModifiers(
        pools: [(sides: Int, count: Int, modifier: RollPoolModifier)]
    ) throws -> MultiPoolRollResult {
        var rng = SystemRandomNumberGenerator()
        return try rollPoolsWithModifiers(pools: pools, rng: &rng)
    }

    public static func rollPools(pools: [(sides: Int, count: Int)]) throws -> MultiPoolRollResult {
        var rng = SystemRandomNumberGenerator()
        return try rollPools(pools: pools, rng: &rng)
    }

    /// Rolls `count` dice with `sides` (e.g. 20 for d20), adds `modifier`, using `rng` for reproducibility in tests.
    public static func roll(
        count: Int,
        sides: Int,
        modifier: Int,
        rng: inout some RandomNumberGenerator
    ) throws -> RollResult {
        guard count >= 1 else { throw DiceError.invalidCount(count) }
        guard sides >= 2 else { throw DiceError.invalidSides(sides) }

        var rolls: [Int] = []
        rolls.reserveCapacity(count)
        for _ in 0 ..< count {
            rolls.append(Int.random(in: 1 ... sides, using: &rng))
        }
        let sum = rolls.reduce(0, +)
        return RollResult(rolls: rolls, modifier: modifier, total: sum + modifier)
    }

    public static func roll(count: Int, sides: Int, modifier: Int) throws -> RollResult {
        var rng = SystemRandomNumberGenerator()
        return try roll(count: count, sides: sides, modifier: modifier, rng: &rng)
    }
}
