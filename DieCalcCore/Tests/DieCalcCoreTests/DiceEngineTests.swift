import XCTest
import DieCalcCore

final class DiceEngineTests: XCTestCase {
    func testRollDeterministic() throws {
        var rng = SeededGenerator(seed: 42)
        let r = try DiceEngine.roll(count: 2, sides: 6, modifier: 3, rng: &rng)
        XCTAssertEqual(r.rolls.count, 2)
        XCTAssertEqual(r.modifier, 3)
        XCTAssertEqual(r.total, r.rolls.reduce(0, +) + 3)
    }

    func testInvalidSides() {
        XCTAssertThrowsError(try DiceEngine.roll(count: 1, sides: 1, modifier: 0))
    }

    func testInvalidCount() {
        XCTAssertThrowsError(try DiceEngine.roll(count: 0, sides: 20, modifier: 0))
    }

    func testMultiPoolDeterministic() throws {
        var rng = SeededGenerator(seed: 99)
        let result = try DiceEngine.rollPools(
            pools: [(sides: 4, count: 2), (sides: 20, count: 1)],
            rng: &rng
        )
        XCTAssertEqual(result.groups.count, 2)
        XCTAssertEqual(result.groups[0].sides, 4)
        XCTAssertEqual(result.groups[0].rolls.count, 2)
        XCTAssertEqual(result.groups[1].sides, 20)
        XCTAssertEqual(result.groups[1].rolls.count, 1)
        XCTAssertEqual(result.grandTotal, result.groups[0].subtotal + result.groups[1].subtotal)
    }

    func testMultiPoolSkipsZeros() throws {
        var rng = SeededGenerator(seed: 1)
        let result = try DiceEngine.rollPools(
            pools: [(sides: 6, count: 0), (sides: 10, count: 2)],
            rng: &rng
        )
        XCTAssertEqual(result.groups.count, 1)
        XCTAssertEqual(result.groups[0].sides, 10)
        XCTAssertEqual(result.groups[0].rolls.count, 2)
    }

    func testMultiPoolNoSelection() {
        XCTAssertThrowsError(try DiceEngine.rollPools(pools: [])) { error in
            XCTAssertEqual(error as? DiceEngine.DiceError, .noDiceSelected)
        }
        XCTAssertThrowsError(try DiceEngine.rollPools(pools: [(sides: 6, count: 0)])) { error in
            XCTAssertEqual(error as? DiceEngine.DiceError, .noDiceSelected)
        }
    }

    func testMultiPoolAllowsCountAboveFive() throws {
        var rng = SeededGenerator(seed: 3)
        let result = try DiceEngine.rollPools(pools: [(sides: 6, count: 8)], rng: &rng)
        XCTAssertEqual(result.groups.count, 1)
        XCTAssertEqual(result.groups[0].rolls.count, 8)
    }

    func testMultiPoolInvalidCountTooLarge() {
        XCTAssertThrowsError(try DiceEngine.rollPools(pools: [(sides: 6, count: 100)]))
    }

    func testRollPoolsWithModifiersAdvantageInvariants() throws {
        var rng = SeededGenerator(seed: 42)
        let result = try DiceEngine.rollPoolsWithModifiers(
            pools: [(sides: 20, count: 1, modifier: .advantage)],
            rng: &rng
        )
        XCTAssertEqual(result.groups.count, 1)
        let g = result.groups[0]
        XCTAssertEqual(g.modifier, .advantage)
        XCTAssertEqual(g.rolls.count, 1)
        XCTAssertEqual(g.underlyingRolls.count, 1)
        XCTAssertEqual(g.underlyingRolls[0].count, 2)
        XCTAssertEqual(g.rolls[0], max(g.underlyingRolls[0][0], g.underlyingRolls[0][1]))
        XCTAssertEqual(result.grandTotal, g.rolls[0])
    }

    func testRollPoolsWithModifiersDisadvantageInvariants() throws {
        var rng = SeededGenerator(seed: 7)
        let result = try DiceEngine.rollPoolsWithModifiers(
            pools: [(sides: 20, count: 2, modifier: .disadvantage)],
            rng: &rng
        )
        let g = result.groups[0]
        XCTAssertEqual(g.modifier, .disadvantage)
        XCTAssertEqual(g.underlyingRolls.count, 2)
        for i in 0 ..< 2 {
            XCTAssertEqual(g.underlyingRolls[i].count, 2)
            XCTAssertEqual(g.rolls[i], min(g.underlyingRolls[i][0], g.underlyingRolls[i][1]))
        }
        XCTAssertEqual(result.grandTotal, g.rolls.reduce(0, +))
    }

    func testRollPoolsWithModifiersDoubleAdvantageInvariants() throws {
        var rng = SeededGenerator(seed: 99)
        let result = try DiceEngine.rollPoolsWithModifiers(
            pools: [(sides: 6, count: 1, modifier: .doubleAdvantage)],
            rng: &rng
        )
        let g = result.groups[0]
        XCTAssertEqual(g.modifier, .doubleAdvantage)
        XCTAssertEqual(g.underlyingRolls[0].count, 3)
        let u = g.underlyingRolls[0]
        XCTAssertEqual(g.rolls[0], max(u[0], max(u[1], u[2])))
    }

    func testRollPoolsWithModifiersMixedGrandTotal() throws {
        var rng = SeededGenerator(seed: 3)
        let result = try DiceEngine.rollPoolsWithModifiers(
            pools: [
                (sides: 6, count: 1, modifier: .normal),
                (sides: 4, count: 1, modifier: .advantage),
            ],
            rng: &rng
        )
        XCTAssertEqual(result.groups.count, 2)
        let expected = result.groups[0].subtotal + result.groups[1].subtotal
        XCTAssertEqual(result.grandTotal, expected)
    }

    func testRollPoolsWithModifiersNoSelection() {
        XCTAssertThrowsError(try DiceEngine.rollPoolsWithModifiers(pools: []))
        XCTAssertThrowsError(try DiceEngine.rollPoolsWithModifiers(pools: [(sides: 6, count: 0, modifier: .normal)]))
    }
}

private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 1 : seed }
    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1
        return state
    }
}
