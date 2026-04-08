import SwiftUI

/// Sketch layout: table sum grid (1–20), digital dice pool with LEDs, bottom Clear + ROLL.
struct VintageCalculatorView: View {
    @ObservedObject var model: CalculatorViewModel

    /// Horizontal gap between table number keys (left / right).
    private let tableColumnSpacing: CGFloat = 12
    /// Vertical gap between rows of table keys (space below each row).
    private let tableRowSpacing: CGFloat = 14
    /// Gap between LED row and main label inside each key cap.
    private let tableLedToKeySpacing: CGFloat = 4
    /// Inset from the top border of the key for the LED strip.
    private let keyCapLedTopInset: CGFloat = 6
    /// Width ÷ height; > 1 yields a low, wide key cap (not square).
    private let keyCapAspectRatio: CGFloat = 1.18
    private var tableColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: tableColumnSpacing), count: 5)
    }

    var body: some View {
        ZStack {
            vintageBodyBackground
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SegmentedReadoutView(
                        caption: model.readoutCaption,
                        isTableReadout: model.showingTableReadout,
                        tableText: model.tableReadoutText,
                        tableExpressionLine: model.tableExpressionLine,
                        dicePoolSelectionTally: model.dicePoolSelectionTally,
                        diceDetailLine: model.diceDetailLine,
                        diceTotalLine: model.diceTotalLine,
                        bandMode: model.readoutBandMode
                    )

                    readoutBandModePhysicalToggle

                    LazyVGrid(columns: tableColumns, spacing: tableRowSpacing) {
                        ForEach(1 ... 20, id: \.self) { value in
                            physicalKey(value)
                        }
                    }

                    Text("Roll pool")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(red: 0.75, green: 0.72, blue: 0.65))
                        .textCase(.uppercase)
                        .tracking(1.1)

                    poolModifierButtonRow

                    LazyVGrid(columns: tableColumns, spacing: tableRowSpacing) {
                        ForEach(CalculatorViewModel.DigitalDie.allCases) { die in
                            digitalDieColumn(die)
                        }
                    }

                    HStack(spacing: 12) {
                        clearButton
                        rollButton
                    }
                    .padding(.top, 4)
                }
                .padding(16)
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private var vintageBodyBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.12, green: 0.11, blue: 0.10),
                Color(red: 0.06, green: 0.05, blue: 0.05),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Single physical key below the LCD: orange SUM/TOT label; tap toggles sum vs total readout.
    private var readoutBandModePhysicalToggle: some View {
        let faceTop = Color(red: 0.34, green: 0.32, blue: 0.30)
        let faceBottom = Color(red: 0.18, green: 0.16, blue: 0.15)
        let orangeText = Color(red: 1.0, green: 0.48, blue: 0.12)

        return HStack {
            Spacer(minLength: 0)
            Button {
                model.readoutBandMode = model.readoutBandMode == .sum ? .total : .sum
            } label: {
                Text("SUM/TOT")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .tracking(0.4)
                    .foregroundStyle(orangeText)
                    .frame(minWidth: 96, minHeight: 40)
                    .padding(.horizontal, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [faceTop, faceBottom],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.35), radius: 0, y: 2)
                    )
            }
            .buttonStyle(TableCalcKeyButtonStyle())
            .accessibilityLabel(
                model.readoutBandMode == .sum
                    ? "SUM readout, tap for total only"
                    : "Total readout, tap for sum detail"
            )
            .accessibilityHint("Toggles between sum line and large total")
        }
    }

    private func physicalKey(_ value: Int) -> some View {
        let presses = model.physicalPressCount(for: value)
        return Button {
            model.tapPhysicalNumber(value)
        } label: {
            VStack(spacing: tableLedToKeySpacing) {
                keyCapLedRow(pressCount: presses)
                    .padding(.top, keyCapLedTopInset)

                Text("\(value)")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(red: 0.95, green: 0.94, blue: 0.90))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .padding(.bottom, 6)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.24, green: 0.22, blue: 0.21),
                                Color(red: 0.14, green: 0.13, blue: 0.12),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.35), radius: 0, y: 2)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(TableCalcKeyButtonStyle())
        .frame(maxWidth: .infinity)
        .aspectRatio(keyCapAspectRatio, contentMode: .fit)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Table \(value), \(presses) presses, add \(value) to total")
    }

    /// Every 5 presses refills 1…5 lights; tier color cycles green → blue → purple → red → orange.
    private let advIndicatorBlue = Color(red: 0.28, green: 0.62, blue: 1.0)
    private let doubleAdvTeal = Color(red: 0.22, green: 0.78, blue: 0.76)
    private let disIndicatorRed = Color(red: 0.95, green: 0.22, blue: 0.22)
    private let modifierLedOff = Color(red: 0.15, green: 0.13, blue: 0.12)

    private var modifierGridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8),
        ]
    }

    private func modifierIndicatorLed(lit: Bool, color: Color) -> some View {
        Circle()
            .fill(lit ? color : modifierLedOff)
            .frame(width: 6, height: 6)
            .overlay(Circle().stroke(Color.black.opacity(0.35), lineWidth: 0.5))
    }

    private var poolModifierButtonRow: some View {
        LazyVGrid(columns: modifierGridColumns, spacing: 10) {
            poolModifierButton(title: "ADV", mode: .advantage, labelColor: advIndicatorBlue)
            poolModifierButton(title: "2X ADV", mode: .doubleAdvantage, labelColor: doubleAdvTeal)
            poolModifierButton(title: "DIS", mode: .disadvantage, labelColor: disIndicatorRed)
        }
        .padding(.top, 6)
    }

    @ViewBuilder
    private func poolModifierInCapLedRow(for buttonMode: CalculatorViewModel.PoolAssignmentMode) -> some View {
        let m = model.poolAssignmentMode
        switch buttonMode {
        case .advantage:
            HStack {
                Spacer(minLength: 0)
                modifierIndicatorLed(lit: m == .advantage, color: advIndicatorBlue)
                Spacer(minLength: 0)
            }
        case .doubleAdvantage:
            HStack(spacing: 3) {
                Spacer(minLength: 0)
                modifierIndicatorLed(lit: m == .doubleAdvantage, color: doubleAdvTeal)
                modifierIndicatorLed(lit: m == .doubleAdvantage, color: doubleAdvTeal)
                Spacer(minLength: 0)
            }
        case .disadvantage:
            HStack {
                Spacer(minLength: 0)
                modifierIndicatorLed(lit: m == .disadvantage, color: disIndicatorRed)
                Spacer(minLength: 0)
            }
        case .none:
            EmptyView()
        }
    }

    private func poolModifierButton(
        title: String,
        mode: CalculatorViewModel.PoolAssignmentMode,
        labelColor: Color
    ) -> some View {
        let armed = model.poolAssignmentMode == mode
        let stroke: Color = armed ? labelColor.opacity(0.95) : Color.white.opacity(0.12)
        return Button {
            model.togglePoolAssignmentMode(mode)
        } label: {
            VStack(spacing: tableLedToKeySpacing) {
                poolModifierInCapLedRow(for: mode)
                    .padding(.top, keyCapLedTopInset)

                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(labelColor)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.65)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .padding(.bottom, 6)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.24, green: 0.22, blue: 0.21),
                                Color(red: 0.14, green: 0.13, blue: 0.12),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(stroke, lineWidth: armed ? 2 : 1)
            )
            .shadow(color: .black.opacity(0.35), radius: 0, y: 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(TableCalcKeyButtonStyle())
        .accessibilityLabel(accessibilityLabelForPoolModifierButton(title: title, mode: mode, armed: armed))
    }

    private func accessibilityLabelForPoolModifierButton(
        title: String,
        mode: CalculatorViewModel.PoolAssignmentMode,
        armed: Bool
    ) -> String {
        let action: String
        switch mode {
        case .advantage: action = "advantage, roll twice keep higher"
        case .doubleAdvantage: action = "double advantage, roll three keep highest"
        case .disadvantage: action = "disadvantage, roll twice keep lower"
        case .none: action = ""
        }
        if armed {
            return "\(title), \(action), active, tap to cancel"
        }
        return "\(title), \(action), tap to assign to dice"
    }

    private func tieredLEDColor(index: Int, pressCount: Int) -> Color {
        let off = Color(red: 0.15, green: 0.13, blue: 0.12)
        let green = Color(red: 0.22, green: 0.88, blue: 0.38)
        let blue = Color(red: 0.28, green: 0.62, blue: 1.0)
        let purple = Color(red: 0.62, green: 0.32, blue: 0.92)
        let red = Color(red: 0.95, green: 0.22, blue: 0.22)
        let orange = Color(red: 1.0, green: 0.48, blue: 0.12)

        guard pressCount > 0 else { return off }
        let litInTier = (pressCount - 1) % 5 + 1
        guard index < litInTier else { return off }
        let colorTier = ((pressCount - 1) / 5) % 5
        switch colorTier {
        case 0: return green
        case 1: return blue
        case 2: return purple
        case 3: return red
        default: return orange
        }
    }

    /// Advantage / double advantage / disadvantage pool LEDs above the die key (leading-aligned with the button).
    private func diePoolModifierIndicators(die: CalculatorViewModel.DigitalDie) -> some View {
        let s = model.digitalPoolState
        let advLit = s.advantage[die, default: 0] > 0
        let adv2Lit = s.doubleAdvantage[die, default: 0] > 0
        let disLit = s.disadvantage[die, default: 0] > 0
        return HStack(spacing: 3) {
            modifierIndicatorLed(lit: advLit, color: advIndicatorBlue)
            modifierIndicatorLed(lit: adv2Lit, color: doubleAdvTeal)
            modifierIndicatorLed(lit: disLit, color: disIndicatorRed)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityHidden(true)
    }

    private func digitalDieColumn(_ die: CalculatorViewModel.DigitalDie) -> some View {
        let presses = model.digitalPressCount(for: die)
        let pool = model.digitalPoolCount(for: die)
        let labelFont = Font.system(size: 17, weight: .semibold, design: .rounded)
        let glyphSize: CGFloat = 17
        return VStack(alignment: .leading, spacing: 4) {
            diePoolModifierIndicators(die: die)

            Button {
                model.tapDigitalDie(die)
            } label: {
                VStack(spacing: tableLedToKeySpacing) {
                    keyCapLedRow(pressCount: presses)
                        .padding(.top, keyCapLedTopInset)

                    HStack(alignment: .center, spacing: 3) {
                        DigitalDieGlyphView(die: die)
                            .frame(width: glyphSize, height: glyphSize)
                        Text(die == .d100 ? "100" : die.buttonCaption)
                            .font(labelFont)
                            .foregroundStyle(Color(red: 0.95, green: 0.94, blue: 0.90))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .padding(.bottom, 6)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.24, green: 0.22, blue: 0.21),
                                    Color(red: 0.14, green: 0.13, blue: 0.12),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.35), radius: 0, y: 2)
                )
                .contentShape(Rectangle())
                .onLongPressGesture(minimumDuration: 3) {
                    model.removeOneDigitalDie(die)
                }
            }
            .buttonStyle(TableCalcKeyButtonStyle())
            .frame(maxWidth: .infinity)
            .aspectRatio(keyCapAspectRatio, contentMode: .fit)
            .accessibilityLabel(digitalDieAccessibilityLabel(die: die, pool: pool, presses: presses))
        }
    }

    private func digitalDieAccessibilityLabel(
        die: CalculatorViewModel.DigitalDie,
        pool: Int,
        presses: Int
    ) -> String {
        let mode = model.poolAssignmentMode
        let modeHint: String
        switch mode {
        case .none: modeHint = "add die"
        case .advantage: modeHint = "assign advantage"
        case .doubleAdvantage: modeHint = "assign double advantage"
        case .disadvantage: modeHint = "assign disadvantage"
        }
        let s = model.digitalPoolState
        let a = s.advantage[die, default: 0]
        let a2 = s.doubleAdvantage[die, default: 0]
        let d = s.disadvantage[die, default: 0]
        let modHint: String
        if a == 0, a2 == 0, d == 0 {
            modHint = "no advantage or disadvantage dice"
        } else {
            modHint = "\(a) advantage, \(a2) double advantage, \(d) disadvantage"
        }
        return "\(die.buttonCaption), \(pool) dice, \(presses) taps, \(modHint), \(modeHint), long press three seconds to remove one die"
    }

    /// Five tier LEDs along the top inside a physical table key cap.
    private func keyCapLedRow(pressCount: Int) -> some View {
        HStack(spacing: 2) {
            ForEach(0 ..< 5, id: \.self) { idx in
                Circle()
                    .fill(tieredLEDColor(index: idx, pressCount: pressCount))
                    .frame(width: 5, height: 5)
                    .overlay(Circle().stroke(Color.black.opacity(0.35), lineWidth: 0.5))
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var clearButton: some View {
        Button(action: { model.clearAll() }) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.32, green: 0.22, blue: 0.20),
                                Color(red: 0.22, green: 0.14, blue: 0.12),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                ZStack {
                    Circle()
                        .stroke(Color(red: 0.92, green: 0.88, blue: 0.82), lineWidth: 2)
                        .frame(width: 28, height: 28)
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(red: 0.95, green: 0.92, blue: 0.88))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Clear table and dice")
    }

    private var rollButton: some View {
        Button(action: { model.rollDigital() }) {
            Text("ROLL")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.08, green: 0.08, blue: 0.08))
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.92, green: 0.88, blue: 0.78),
                                    Color(red: 0.72, green: 0.68, blue: 0.58),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.white.opacity(0.35), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Roll digital dice")
    }
}

// MARK: - Table calculator key style

private struct TableCalcKeyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(y: configuration.isPressed ? 1 : 0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Roll pool shapes

/// Solid white die glyph, drawn to fit a square about the same size as the pool key label (17pt).
private struct DigitalDieGlyphView: View {
    let die: CalculatorViewModel.DigitalDie

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            let corner = max(1, s * 0.14)
            ZStack {
                switch die {
                case .d4:
                    TriangleShape()
                        .fill(Color.white)
                case .d6:
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .fill(Color.white)
                case .d8:
                    OctagonShape()
                        .fill(Color.white)
                case .d10:
                    DiamondShape()
                        .fill(Color.white)
                case .d12:
                    PentagonShape()
                        .fill(Color.white)
                case .d20:
                    HexagonShape()
                        .fill(Color.white)
                case .d100:
                    Text("%")
                        .font(.system(size: s * 0.92, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white)
                        .minimumScaleFactor(0.25)
                        .lineLimit(1)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

private struct TriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let inset = min(rect.width, rect.height) * 0.12
        let r = rect.insetBy(dx: inset, dy: inset)
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

private struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let inset = min(rect.width, rect.height) * 0.1
        let r = rect.insetBy(dx: inset, dy: inset)
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.midY))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.midY))
        p.closeSubpath()
        return p
    }
}

private struct PentagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        polygonPath(in: rect, sides: 5, phase: -.pi / 2)
    }
}

private struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        polygonPath(in: rect, sides: 6, phase: 0)
    }
}

private struct OctagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        polygonPath(in: rect, sides: 8, phase: -.pi / 2)
    }
}

private func polygonPath(in rect: CGRect, sides: Int, phase: CGFloat) -> Path {
    let inset = min(rect.width, rect.height) * 0.1
    let r = rect.insetBy(dx: inset, dy: inset)
    let center = CGPoint(x: r.midX, y: r.midY)
    let radius = min(r.width, r.height) / 2
    var path = Path()
    guard sides >= 3 else { return path }
    for i in 0 ..< sides {
        let t = phase + CGFloat(i) * 2 * .pi / CGFloat(sides)
        let pt = CGPoint(x: center.x + cos(t) * radius, y: center.y + sin(t) * radius)
        if i == 0 {
            path.move(to: pt)
        } else {
            path.addLine(to: pt)
        }
    }
    path.closeSubpath()
    return path
}

#Preview {
    VintageCalculatorView(model: CalculatorViewModel())
}
