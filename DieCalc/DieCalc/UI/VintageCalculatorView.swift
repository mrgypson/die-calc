import SwiftUI

/// Width of the four-die `HStack` so the three-die row can match `narrow` / `wide` column splits.
private struct DiePoolInnerRowWidthPreference: PreferenceKey, Sendable {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        let n = nextValue()
        if n > 0 { value = n }
    }
}

/// Per–die-type key cap frames in `diePoolKeyplate` space (merged for the two-row box).
private struct DiePoolKeyBoundsPreference: PreferenceKey, Sendable {
    static let defaultValue: [Int: CGRect] = [:]
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

private enum DiePoolKeyplateLayout {
    static let row1Keys = [4, 6, 8, 10]
    static let row2Keys = [12, 20, 100]
    static let horizontalOutsetFromKeys: CGFloat = 6
    static let orange = Color(red: 0.95, green: 0.52, blue: 0.1)

    static func geometry(bounds: [Int: CGRect]) -> (leftX: CGFloat, rightX: CGFloat, row1MidY: CGFloat, row2MidY: CGFloat)? {
        let r1 = row1Keys.compactMap { bounds[$0] }
        let r2 = row2Keys.compactMap { bounds[$0] }
        guard r1.count == 4, r2.count == 3 else { return nil }
        let all = r1 + r2
        let keyMinX = all.map(\.minX).min() ?? 0
        let keyMaxX = all.map(\.maxX).max() ?? 0
        guard keyMaxX > keyMinX else { return nil }
        let row1MidY = rowMidY(rects: r1)
        let row2MidY = rowMidY(rects: r2)
        guard row2MidY > row1MidY else { return nil }
        let leftX = keyMinX - horizontalOutsetFromKeys
        let rightX = keyMaxX + horizontalOutsetFromKeys
        return (leftX, rightX, row1MidY, row2MidY)
    }

    private static func rowMidY(rects: [CGRect]) -> CGFloat {
        let mids = rects.map { ($0.minY + $0.maxY) / 2 }
        return mids.reduce(0, +) / CGFloat(mids.count)
    }
}

/// Orange strokes only — behind the die columns.
private struct DiePoolKeyplateLineArt: View {
    let bounds: [Int: CGRect]
    private let dVerticalGapHalf: CGFloat = 11

    var body: some View {
        GeometryReader { _ in
            if let g = DiePoolKeyplateLayout.geometry(bounds: bounds) {
                let midV = (g.row1MidY + g.row2MidY) / 2
                Path { path in
                    path.move(to: CGPoint(x: g.leftX, y: g.row1MidY))
                    path.addLine(to: CGPoint(x: g.rightX, y: g.row1MidY))
                    path.move(to: CGPoint(x: g.leftX, y: g.row2MidY))
                    path.addLine(to: CGPoint(x: g.rightX, y: g.row2MidY))

                    path.move(to: CGPoint(x: g.leftX, y: g.row1MidY))
                    path.addLine(to: CGPoint(x: g.leftX, y: midV - dVerticalGapHalf))
                    path.move(to: CGPoint(x: g.leftX, y: midV + dVerticalGapHalf))
                    path.addLine(to: CGPoint(x: g.leftX, y: g.row2MidY))

                    path.move(to: CGPoint(x: g.rightX, y: g.row1MidY))
                    path.addLine(to: CGPoint(x: g.rightX, y: midV - dVerticalGapHalf))
                    path.move(to: CGPoint(x: g.rightX, y: midV + dVerticalGapHalf))
                    path.addLine(to: CGPoint(x: g.rightX, y: g.row2MidY))
                }
                .stroke(DiePoolKeyplateLayout.orange, style: StrokeStyle(lineWidth: 2.25, lineCap: .round, lineJoin: .round))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Orange `D` labels on the vertical — above keys so they stay legible.
private struct DiePoolKeyplateDLabels: View {
    let bounds: [Int: CGRect]
    let dFont: Font

    var body: some View {
        GeometryReader { _ in
            if let g = DiePoolKeyplateLayout.geometry(bounds: bounds) {
                let midV = (g.row1MidY + g.row2MidY) / 2
                ZStack {
                    Text("D")
                        .font(dFont.weight(.bold))
                        .foregroundStyle(DiePoolKeyplateLayout.orange)
                        .position(x: g.leftX, y: midV)
                    Text("D")
                        .font(dFont.weight(.bold))
                        .foregroundStyle(DiePoolKeyplateLayout.orange)
                        .position(x: g.rightX, y: midV)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Sketch layout: table sum grid (1–20), digital dice pool with LEDs, bottom Clear + ROLL.
struct VintageCalculatorView: View {
    @ObservedObject var model: CalculatorViewModel
    @Environment(\.calculatorTheme) private var theme

    /// Measured from the first die row; used to size d12 / d20 / d100 columns.
    @State private var diePoolInnerRowWidth: CGFloat = 0

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

    private var showPhysicalKeypad: Bool {
        model.isSettingsMode || model.primaryCalculatorMode == .add
    }

    private var showRollPoolSection: Bool {
        model.isSettingsMode || model.primaryCalculatorMode == .roll
    }

    /// Inset the whole die grid so orange side lines have more breathing room.
    private let diePoolKeyGridHorizontalInset: CGFloat = 6
    /// Narrows each die key cap within its column (does not affect modifier / mini readout).
    private let diePoolKeyButtonHorizontalInset: CGFloat = 4

    /// Page body color for a 2pt halo stroke so orange framing does not read as touching the keys.
    private var diePoolKeyHaloColor: Color {
        switch theme.page.background {
        case .linearGradient(let top, _):
            return top
        case .checkerboardDither:
            return Color.white
        }
    }

    var body: some View {
        ZStack {
            vintageBodyBackground
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                        bandMode: model.readoutBandMode,
                        isSettingsMode: model.isSettingsMode,
                        settingsTitleLines: model.settingsTitleLines,
                        settingsFooterLine: model.settingsFooterLine
                    )

                    readoutToolbarRow

                    if showPhysicalKeypad {
                        LazyVGrid(columns: tableColumns, spacing: tableRowSpacing) {
                            ForEach(1 ... 20, id: \.self) { value in
                                physicalKey(value)
                            }
                        }

                        addCalculatorClearButton
                            .padding(.top, 4)
                    }

                    if showRollPoolSection {
                        Group {
                            Text("Roll pool")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(theme.chrome.sectionLabel)
                                .textCase(.uppercase)
                                .tracking(theme.keys.chromeStyle == .macSystem1Raised ? 1.5 : 1.1)

                            poolModifierButtonRow

                            VStack(spacing: tableRowSpacing) {
                                diePoolRowFourEqual()
                                diePoolRowThreeWithWiderD100()
                            }
                            .padding(.horizontal, diePoolKeyGridHorizontalInset)
                            .coordinateSpace(name: "diePoolKeyplate")
                            .backgroundPreferenceValue(DiePoolKeyBoundsPreference.self) { keyBounds in
                                DiePoolKeyplateLineArt(bounds: keyBounds)
                            }
                            .overlayPreferenceValue(DiePoolKeyBoundsPreference.self) { keyBounds in
                                DiePoolKeyplateDLabels(bounds: keyBounds, dFont: theme.chrome.keyLabelFont)
                            }
                            .onPreferenceChange(DiePoolInnerRowWidthPreference.self) { w in
                                if w > 0, abs(w - diePoolInnerRowWidth) > 0.5 {
                                    diePoolInnerRowWidth = w
                                }
                            }

                            HStack(spacing: 12) {
                                rollPoolClearButton
                                rollButton
                            }
                            .padding(.top, 4)
                        }
                        .opacity(model.isSettingsMode ? 0.38 : 1)
                        .allowsHitTesting(!model.isSettingsMode)
                    }
                }
                .padding(16)
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    @ViewBuilder
    private var vintageBodyBackground: some View {
        switch theme.page.background {
        case .linearGradient(let top, let bottom):
            LinearGradient(
                colors: [top, bottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .checkerboardDither:
            CheckerboardDitherBackground(cellSize: 2)
        }
    }

    /// Gear (settings) and SUM/TOT below the LCD.
    private var readoutToolbarRow: some View {
        let k = theme.keys
        let keyCap = RoundedRectangle(cornerRadius: 8, style: .continuous)
        return HStack(spacing: 12) {
            Button {
                model.toggleGear()
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(k.sumTotAccent)
                    .frame(minWidth: 44, minHeight: 40)
                    .background(toolbarKeyChromeBackground(keys: k, shape: keyCap))
            }
            .buttonStyle(TableCalcKeyButtonStyle())
            .accessibilityLabel(gearAccessibilityLabel)

            Button {
                model.togglePrimaryCalculatorMode()
            } label: {
                let addLED = Color(red: 0.22, green: 0.48, blue: 0.98)
                let rollLED = Color(red: 0.16, green: 0.72, blue: 0.36)
                let tracking = theme.keys.chromeStyle == .macSystem1Raised ? 0.6 : 0.4
                return HStack(alignment: .bottom, spacing: 3) {
                    VStack(spacing: 3) {
                        modifierIndicatorLed(
                            lit: model.primaryCalculatorMode == .add,
                            color: addLED
                        )
                        Text("ADD")
                            .font(theme.chrome.sumTotLabelFont)
                            .tracking(tracking)
                            .foregroundStyle(k.sumTotAccent)
                    }
                    Text("/")
                        .font(theme.chrome.sumTotLabelFont)
                        .tracking(tracking)
                        .foregroundStyle(k.sumTotAccent.opacity(0.88))
                    VStack(spacing: 3) {
                        modifierIndicatorLed(
                            lit: model.primaryCalculatorMode == .roll,
                            color: rollLED
                        )
                        Text("ROLL")
                            .font(theme.chrome.sumTotLabelFont)
                            .tracking(tracking)
                            .foregroundStyle(k.sumTotAccent)
                    }
                }
                .frame(minWidth: 108, minHeight: 44)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(toolbarKeyChromeBackground(keys: k, shape: keyCap))
            }
            .buttonStyle(TableCalcKeyButtonStyle())
            .accessibilityLabel(
                model.primaryCalculatorMode == .add
                    ? "Add calculator, tap to switch to roll pool"
                    : "Roll calculator, tap to switch to add"
            )
            .accessibilityHint("Toggles between add and roll calculators")

            Spacer(minLength: 0)

            Button {
                model.readoutBandMode = model.readoutBandMode == .sum ? .total : .sum
            } label: {
                Text("SUM/TOT")
                    .font(theme.chrome.sumTotLabelFont)
                    .tracking(theme.keys.chromeStyle == .macSystem1Raised ? 0.6 : 0.4)
                    .foregroundStyle(k.sumTotAccent)
                    .frame(minWidth: 96, minHeight: 40)
                    .padding(.horizontal, 8)
                    .background(toolbarKeyChromeBackground(keys: k, shape: keyCap))
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

    @ViewBuilder
    private func toolbarKeyChromeBackground(keys k: CalculatorTheme.Keys, shape: RoundedRectangle) -> some View {
        switch k.chromeStyle {
        case .roundedGradient:
            shape
                .fill(
                    LinearGradient(
                        colors: [k.sumTotFaceTop, k.sumTotFaceBottom],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(shape.stroke(k.sumTotStroke, lineWidth: 1))
                .shadow(color: k.keyShadow, radius: 0, y: 2)
        case .macSystem1Raised:
            MacRaisedKeyBackground()
        }
    }

    private var gearAccessibilityLabel: String {
        switch model.settingsPhase {
        case .inactive:
            return "Settings"
        case .root:
            return "Close settings"
        case .themes:
            return "Back to settings menu"
        }
    }

    private func physicalKey(_ value: Int) -> some View {
        let presses = model.physicalPressCount(for: value)
        let k = theme.keys
        return Button {
            if model.isSettingsMode {
                model.handleSettingsKey(value)
            } else {
                model.tapPhysicalNumber(value)
            }
        } label: {
            VStack(spacing: tableLedToKeySpacing) {
                keyCapLedRow(pressCount: presses)
                    .padding(.top, keyCapLedTopInset)

                Text("\(value)")
                    .font(theme.chrome.keyLabelFont)
                    .tracking(k.chromeStyle == .macSystem1Raised ? 0.4 : 0)
                    .foregroundStyle(k.label)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .padding(.bottom, 6)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(tableKeyCapChromeBackground(keys: k))
            .contentShape(Rectangle())
        }
        .buttonStyle(TableCalcKeyButtonStyle())
        .frame(maxWidth: .infinity)
        .aspectRatio(keyCapAspectRatio, contentMode: .fit)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            model.isSettingsMode
                ? model.settingsKeyAccessibilityLabel(key: value)
                : "Table \(value), \(presses) presses, add \(value) to total"
        )
    }

    @ViewBuilder
    private func tableKeyCapChromeBackground(keys k: CalculatorTheme.Keys) -> some View {
        let shape = RoundedRectangle(cornerRadius: 8, style: .continuous)
        switch k.chromeStyle {
        case .roundedGradient:
            shape
                .fill(
                    LinearGradient(
                        colors: [k.faceTop, k.faceBottom],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(shape.stroke(k.stroke, lineWidth: 1))
                .shadow(color: k.keyShadow, radius: 0, y: 2)
        case .macSystem1Raised:
            MacRaisedKeyBackground()
        }
    }

    private var modifierGridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8),
        ]
    }

    private func modifierIndicatorLed(lit: Bool, color: Color) -> some View {
        Circle()
            .fill(lit ? color : theme.modifiers.ledOff)
            .frame(width: 6, height: 6)
            .overlay(Circle().stroke(Color.black.opacity(0.35), lineWidth: 0.5))
    }

    private var poolModifierButtonRow: some View {
        let m = theme.modifiers
        return LazyVGrid(columns: modifierGridColumns, spacing: 10) {
            poolModifierButton(title: "ADV", mode: .advantage, labelColor: m.advantage)
            poolModifierButton(title: "2X ADV", mode: .doubleAdvantage, labelColor: m.doubleAdvantage)
            poolModifierButton(title: "DIS", mode: .disadvantage, labelColor: m.disadvantage)
        }
        .padding(.top, 6)
    }

    @ViewBuilder
    private func poolModifierInCapLedRow(for buttonMode: CalculatorViewModel.PoolAssignmentMode) -> some View {
        let m = model.poolAssignmentMode
        let mod = theme.modifiers
        switch buttonMode {
        case .advantage:
            HStack {
                Spacer(minLength: 0)
                modifierIndicatorLed(lit: m == .advantage, color: mod.advantage)
                Spacer(minLength: 0)
            }
        case .doubleAdvantage:
            HStack(spacing: 3) {
                Spacer(minLength: 0)
                modifierIndicatorLed(lit: m == .doubleAdvantage, color: mod.doubleAdvantage)
                modifierIndicatorLed(lit: m == .doubleAdvantage, color: mod.doubleAdvantage)
                Spacer(minLength: 0)
            }
        case .disadvantage:
            HStack {
                Spacer(minLength: 0)
                modifierIndicatorLed(lit: m == .disadvantage, color: mod.disadvantage)
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
        let k = theme.keys
        let stroke: Color = armed ? labelColor.opacity(0.95) : k.stroke
        return Button {
            model.togglePoolAssignmentMode(mode)
        } label: {
            VStack(spacing: tableLedToKeySpacing) {
                poolModifierInCapLedRow(for: mode)
                    .padding(.top, keyCapLedTopInset)

                Text(title)
                    .font(theme.chrome.modifierLabelFont)
                    .foregroundStyle(labelColor)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.65)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .padding(.bottom, 6)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 4)
            .background(poolModifierKeyBackground(keys: k))
            .overlay(poolModifierKeyOverlay(keys: k, stroke: stroke, armed: armed))
            .shadow(color: k.keyShadow, radius: 0, y: k.chromeStyle == .macSystem1Raised ? 0 : 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(TableCalcKeyButtonStyle())
        .accessibilityLabel(accessibilityLabelForPoolModifierButton(title: title, mode: mode, armed: armed))
    }

    @ViewBuilder
    private func poolModifierKeyBackground(keys k: CalculatorTheme.Keys) -> some View {
        let shape = RoundedRectangle(cornerRadius: 8, style: .continuous)
        switch k.chromeStyle {
        case .roundedGradient:
            shape
                .fill(
                    LinearGradient(
                        colors: [k.faceTop, k.faceBottom],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        case .macSystem1Raised:
            MacRaisedKeyBackground()
        }
    }

    @ViewBuilder
    private func poolModifierKeyOverlay(keys k: CalculatorTheme.Keys, stroke: Color, armed: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: 8, style: .continuous)
        switch k.chromeStyle {
        case .roundedGradient:
            shape
                .stroke(stroke, lineWidth: armed ? 2 : 1)
        case .macSystem1Raised:
            if armed {
                Rectangle()
                    .strokeBorder(stroke, lineWidth: 2)
                    .padding(4)
            }
        }
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

    /// Advantage / double advantage / disadvantage pool LEDs above the die key (leading-aligned with the button).
    private func diePoolModifierIndicators(die: CalculatorViewModel.DigitalDie) -> some View {
        let s = model.digitalPoolState
        let mod = theme.modifiers
        let advLit = s.advantage[die, default: 0] > 0
        let adv2Lit = s.doubleAdvantage[die, default: 0] > 0
        let disLit = s.disadvantage[die, default: 0] > 0
        return HStack(spacing: 3) {
            modifierIndicatorLed(lit: advLit, color: mod.advantage)
            modifierIndicatorLed(lit: adv2Lit, color: mod.doubleAdvantage)
            modifierIndicatorLed(lit: disLit, color: mod.disadvantage)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityHidden(true)
    }

    /// Four dice; width of this row is reported for the bottom row column math.
    private func diePoolFourDiceCoreWithGaps() -> some View {
        HStack(alignment: .bottom, spacing: tableColumnSpacing) {
            digitalDieColumn(.d4)
                .frame(maxWidth: .infinity)
            digitalDieColumn(.d6)
                .frame(maxWidth: .infinity)
            digitalDieColumn(.d8)
                .frame(maxWidth: .infinity)
            digitalDieColumn(.d10)
                .frame(maxWidth: .infinity)
        }
        .background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: DiePoolInnerRowWidthPreference.self,
                    value: proxy.size.width
                )
            }
        )
    }

    /// d4–d10 (orange frame is `DiePoolKeyplateLineArt` + `DiePoolKeyplateDLabels`).
    private func diePoolRowFourEqual() -> some View {
        diePoolFourDiceCoreWithGaps()
    }

    /// Approximate column height from key cap width (modifier strip + mini readout + keyed button).
    private func diePoolColumnStackHeight(forKeyColumnWidth w: CGFloat) -> CGFloat {
        let modifierStripApprox: CGFloat = 10
        let miniReadoutMax: CGFloat = 36
        let vStackSpacing: CGFloat = 4 + 4
        let keyHeight = w / keyCapAspectRatio
        return modifierStripApprox + miniReadoutMax + keyHeight + vStackSpacing
    }

    /// d12, d20, d100: same face chrome and inter-key dashes; d100 ~1.5× narrow (width from first-row core).
    private func diePoolRowThreeWithWiderD100() -> some View {
        let sp = tableColumnSpacing
        let inner = max(diePoolInnerRowWidth, 220)
        let innerThree = max(0, inner - sp * 2)
        // Two gaps between three columns (same spacing as top row).
        let narrow = innerThree / 3.5
        let wide = narrow * 1.5
        let uniformKeyHeight = narrow / keyCapAspectRatio
        let rowHeight = diePoolColumnStackHeight(forKeyColumnWidth: narrow)
        return HStack(alignment: .bottom, spacing: tableColumnSpacing) {
            digitalDieColumn(.d12, uniformKeyHeight: uniformKeyHeight)
                .frame(width: narrow)
            digitalDieColumn(.d20, uniformKeyHeight: uniformKeyHeight)
                .frame(width: narrow)
            digitalDieColumn(.d100, uniformKeyHeight: uniformKeyHeight)
                .frame(width: wide)
        }
        .frame(maxWidth: .infinity)
        .frame(height: rowHeight)
    }

    private func digitalDieColumn(_ die: CalculatorViewModel.DigitalDie, uniformKeyHeight: CGFloat? = nil) -> some View {
        let presses = model.digitalPressCount(for: die)
        let pool = model.digitalPoolCount(for: die)
        let miniRoll = model.digitalMiniRollText(for: die)
        let k = theme.keys
        let labelFont = theme.chrome.keyLabelFont
        let glyphSize: CGFloat = 17
        let keyButton = Button {
            model.tapDigitalDie(die)
        } label: {
            VStack(spacing: tableLedToKeySpacing) {
                keyCapLedRow(pressCount: presses)
                    .padding(.top, keyCapLedTopInset)

                HStack(alignment: .center, spacing: 3) {
                    DigitalDieGlyphView(die: die, fill: theme.chrome.dieGlyph)
                        .frame(width: glyphSize, height: glyphSize)
                    Text(die.keyFaceNumber)
                        .font(labelFont)
                        .foregroundStyle(k.label)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .padding(.bottom, 6)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(tableKeyCapChromeBackground(keys: k))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(diePoolKeyHaloColor, lineWidth: 2)
            }
            .contentShape(Rectangle())
            .onLongPressGesture(minimumDuration: 3) {
                model.removeOneDigitalDie(die)
            }
        }
        .buttonStyle(TableCalcKeyButtonStyle())
        .frame(maxWidth: .infinity)
        .accessibilityLabel(digitalDieAccessibilityLabel(die: die, pool: pool, presses: presses, miniRollText: miniRoll))

        return VStack(alignment: .leading, spacing: 4) {
            diePoolModifierIndicators(die: die)

            dieMiniRollReadout(text: miniRoll)

            Group {
                if let h = uniformKeyHeight {
                    keyButton.frame(height: h)
                } else {
                    keyButton.aspectRatio(keyCapAspectRatio, contentMode: .fit)
                }
            }
            .padding(.horizontal, diePoolKeyButtonHorizontalInset)
            .background(
                GeometryReader { geo in
                    Color.clear.preference(
                        key: DiePoolKeyBoundsPreference.self,
                        value: [die.rawValue: geo.frame(in: .named("diePoolKeyplate"))]
                    )
                }
            )
        }
    }

    /// Compact LCD strip: idle until `text` is non-empty after a roll (or "—" for unused die column).
    private func dieMiniRollReadout(text: String) -> some View {
        let lcd = theme.lcd
        return Text(text)
            .font(lcd.expressionSmallFont)
            .foregroundStyle(text.isEmpty ? lcd.foregroundDim.opacity(0.35) : lcd.foreground)
            .lineLimit(3)
            .minimumScaleFactor(0.45)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 30, maxHeight: 36, alignment: .center)
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
            .background(lcd.panelBackground)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            .accessibilityElement(children: .ignore)
            .accessibilityHidden(true)
    }

    private func digitalDieAccessibilityLabel(
        die: CalculatorViewModel.DigitalDie,
        pool: Int,
        presses: Int,
        miniRollText: String
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
        let rollHint = miniRollText.isEmpty ? "" : ", last roll \(miniRollText)"
        return "\(die.buttonCaption), \(pool) dice, \(presses) taps, \(modHint), \(modeHint)\(rollHint), long press three seconds to remove one die"
    }

    /// Five tier LEDs along the top inside a physical table key cap.
    private func keyCapLedRow(pressCount: Int) -> some View {
        HStack(spacing: 2) {
            ForEach(0 ..< 5, id: \.self) { idx in
                Circle()
                    .fill(theme.tieredLEDColor(index: idx, pressCount: pressCount))
                    .frame(width: 5, height: 5)
                    .overlay(Circle().stroke(Color.black.opacity(0.35), lineWidth: 0.5))
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var addCalculatorClearButton: some View {
        let a = theme.actions
        let k = theme.keys
        return Button(action: { model.clearAddCalculator() }) {
            ZStack {
                actionButtonChrome(keys: k, actions: a, kind: .clear)
                ZStack {
                    Circle()
                        .stroke(a.clearIconRing, lineWidth: 2)
                        .frame(width: 28, height: 28)
                    Image(systemName: "xmark")
                        .font(a.clearIconFont)
                        .foregroundStyle(a.clearIcon)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            model.isSettingsMode
                ? "Close settings"
                : "Clear table sum"
        )
    }

    private var rollPoolClearButton: some View {
        let a = theme.actions
        let k = theme.keys
        return Button(action: { model.clearRollPool() }) {
            ZStack {
                actionButtonChrome(keys: k, actions: a, kind: .clear)
                ZStack {
                    Circle()
                        .stroke(a.clearIconRing, lineWidth: 2)
                        .frame(width: 28, height: 28)
                    Image(systemName: "xmark")
                        .font(a.clearIconFont)
                        .foregroundStyle(a.clearIcon)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Clear dice pool")
    }

    private var rollButton: some View {
        let a = theme.actions
        let k = theme.keys
        return Button(action: { model.rollDigital() }) {
            Text("ROLL")
                .font(a.rollTitleFont)
                .tracking(k.chromeStyle == .macSystem1Raised ? 0.8 : 0)
                .foregroundStyle(a.rollForeground)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(actionButtonChrome(keys: k, actions: a, kind: .roll))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Roll digital dice")
    }

    private enum ActionPadKind {
        case clear
        case roll
    }

    @ViewBuilder
    private func actionButtonChrome(keys k: CalculatorTheme.Keys, actions a: CalculatorTheme.Actions, kind: ActionPadKind) -> some View {
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        switch k.chromeStyle {
        case .roundedGradient:
            switch kind {
            case .clear:
                shape
                    .fill(
                        LinearGradient(
                            colors: [a.clearTop, a.clearBottom],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(shape.stroke(a.clearStroke, lineWidth: 1))
            case .roll:
                shape
                    .fill(
                        LinearGradient(
                            colors: [a.rollTop, a.rollBottom],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(shape.stroke(a.rollStroke, lineWidth: 1))
            }
        case .macSystem1Raised:
            MacRaisedKeyBackground()
        }
    }
}

// MARK: - Classic Mac raised key chrome

/// System 1–style control: 1 pt top/left frame, solid bottom/right shadow (raised look).
private struct MacRaisedKeyBackground: View {
    var faceColor: Color = .white
    var frameColor: Color = .black
    private let edgeWidth: CGFloat = 1
    private let shadowDepth: CGFloat = 3

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            guard w > edgeWidth + shadowDepth, h > edgeWidth + shadowDepth else { return }
            // Bottom shadow
            context.fill(
                Path(CGRect(x: 0, y: h - shadowDepth, width: w, height: shadowDepth)),
                with: .color(frameColor)
            )
            // Right shadow
            context.fill(
                Path(CGRect(x: w - shadowDepth, y: 0, width: shadowDepth, height: h - shadowDepth)),
                with: .color(frameColor)
            )
            // Top edge
            context.fill(
                Path(CGRect(x: 0, y: 0, width: w - shadowDepth, height: edgeWidth)),
                with: .color(frameColor)
            )
            // Left edge
            context.fill(
                Path(CGRect(x: 0, y: edgeWidth, width: edgeWidth, height: h - shadowDepth - edgeWidth)),
                with: .color(frameColor)
            )
            // Face
            context.fill(
                Path(
                    CGRect(
                        x: edgeWidth,
                        y: edgeWidth,
                        width: w - shadowDepth - edgeWidth,
                        height: h - shadowDepth - edgeWidth
                    )
                ),
                with: .color(faceColor)
            )
        }
    }
}

// MARK: - Antique Apple page fill

/// 1-bit “gray” desktop: alternating black/white cells (classic Mac dither).
private struct CheckerboardDitherBackground: View {
    var cellSize: CGFloat = 2

    var body: some View {
        Canvas { context, size in
            guard cellSize > 0 else { return }
            let cols = Int(ceil(size.width / cellSize))
            let rows = Int(ceil(size.height / cellSize))
            for row in 0 ..< rows {
                for col in 0 ..< cols {
                    let isBlack = (row + col) % 2 == 0
                    let rect = CGRect(
                        x: CGFloat(col) * cellSize,
                        y: CGFloat(row) * cellSize,
                        width: cellSize,
                        height: cellSize
                    )
                    context.fill(Path(rect), with: .color(isBlack ? .black : .white))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

/// Solid die glyph, drawn to fit a square about the same size as the pool key label (17pt).
private struct DigitalDieGlyphView: View {
    let die: CalculatorViewModel.DigitalDie
    let fill: Color

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            let corner = max(1, s * 0.14)
            ZStack {
                switch die {
                case .d4:
                    TriangleShape()
                        .fill(fill)
                case .d6:
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .fill(fill)
                case .d8:
                    OctagonShape()
                        .fill(fill)
                case .d10:
                    DiamondShape()
                        .fill(fill)
                case .d12:
                    PentagonShape()
                        .fill(fill)
                case .d20:
                    HexagonShape()
                        .fill(fill)
                case .d100:
                    Text("%")
                        .font(.system(size: s * 0.92, weight: .bold, design: .rounded))
                        .foregroundStyle(fill)
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
        .calculatorTheme(.vintage)
}

#Preview("Antique Apple") {
    VintageCalculatorView(model: CalculatorViewModel())
        .calculatorTheme(.antiqueApple)
}
