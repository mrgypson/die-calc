import SwiftUI

/// LCD: pale green panel. SUM mode = expression band only; TOT mode = large digit readout only.
struct SegmentedReadoutView: View {
    @Environment(\.calculatorTheme) private var theme

    let caption: String
    let isTableReadout: Bool
    /// Table mode only.
    let tableText: String
    /// Table mode: `SUM` or `1+5+10=23`.
    let tableExpressionLine: String
    /// Dice mode: what will be rolled (`—` if empty).
    let dicePoolSelectionTally: String
    /// Dice mode: roll breakdown or error (may be empty).
    let diceDetailLine: String
    /// Dice mode: large total (`--` when none / error).
    let diceTotalLine: String
    let bandMode: CalculatorViewModel.ReadoutBandMode

    var isSettingsMode: Bool = false
    var settingsTitleLines: [String] = []
    var settingsFooterLine: String?

    /// Fixed band for expression lines so layout stays stable (calculator modes).
    private let expressionBandHeight: CGFloat = 56

    var body: some View {
        let lcd = theme.lcd
        VStack(spacing: 0) {
            Text(caption.uppercased())
                .font(lcd.captionFont)
                .foregroundStyle(lcd.foregroundDim)
                .tracking(theme.keys.chromeStyle == .macSystem1Raised ? 0.5 : 0.8)
                .frame(maxWidth: .infinity)
                .padding(.top, 6)
                .padding(.bottom, 4)

            VStack(alignment: .leading, spacing: 0) {
                if isSettingsMode {
                    settingsMenuBlock
                } else if bandMode == .sum {
                    expressionBand
                } else {
                    primaryReadout(text: isTableReadout ? tableText : diceTotalLine)
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(lcdBezelBackground)
    }

    private var settingsMenuBlock: some View {
        let lcd = theme.lcd
        return VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(settingsTitleLines.enumerated()), id: \.offset) { _, line in
                Text(line)
                    .font(lcd.expressionFont)
                    .foregroundStyle(lcd.foreground)
                    .tracking(0.5)
                    .lineLimit(2)
                    .minimumScaleFactor(0.55)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if let footer = settingsFooterLine {
                Text(footer)
                    .font(lcd.expressionSmallFont)
                    .foregroundStyle(lcd.foregroundDim)
                    .tracking(0.6)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(minHeight: settingsBandMinHeight, alignment: .topLeading)
    }

    private var settingsBandMinHeight: CGFloat {
        let lineCount = settingsTitleLines.count + (settingsFooterLine != nil ? 1 : 0)
        let base: CGFloat = 8
        let perLine: CGFloat = 16
        return max(expressionBandHeight, base + CGFloat(max(lineCount, 1)) * perLine)
    }

    private var expressionBand: some View {
        let lcd = theme.lcd
        return VStack(alignment: .leading, spacing: 3) {
            if isTableReadout {
                Text(tableExpressionLine)
                    .font(lcd.expressionFont)
                    .foregroundStyle(lcd.foreground)
                    .tracking(tableExpressionLine == "SUM" ? 1 : 0.6)
                    .lineLimit(1)
                    .minimumScaleFactor(0.45)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(dicePoolSelectionTally.isEmpty ? "—" : dicePoolSelectionTally)
                    .font(lcd.expressionFont)
                    .foregroundStyle(lcd.foreground)
                    .tracking(0.6)
                    .lineLimit(1)
                    .minimumScaleFactor(0.45)

                if !diceDetailLine.isEmpty {
                    Text(diceDetailLine)
                        .font(lcd.expressionSmallFont)
                        .foregroundStyle(lcd.foregroundDim)
                        .lineLimit(2)
                        .minimumScaleFactor(0.5)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(height: expressionBandHeight, alignment: .topLeading)
    }

    @ViewBuilder
    private func primaryReadout(text: String) -> some View {
        let lcd = theme.lcd
        let display = formatLCDPrimaryDisplay(text)
        if lcd.primaryReadoutItalic {
            Text(display)
                .font(lcd.primaryReadoutFont)
                .italic()
                .tracking(5)
                .foregroundStyle(lcd.foreground)
                .shadow(color: lcd.foreground.opacity(0.35), radius: 0, x: 0.6, y: 0)
                .shadow(color: lcd.foreground.opacity(0.2), radius: 1.5, x: 0, y: 0)
                .minimumScaleFactor(0.28)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 2)
        } else {
            Text(display)
                .font(lcd.primaryReadoutFont)
                .tracking(5)
                .foregroundStyle(lcd.foreground)
                .minimumScaleFactor(0.28)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 2)
        }
    }

    /// Keeps zero-padded table totals; adds `'` thousands separators for larger integers.
    private func formatLCDPrimaryDisplay(_ text: String) -> String {
        if text == "--" { return text }
        guard text.allSatisfy({ $0.isNumber }) else { return text }
        if text.count == 2, text.first == "0" { return text }
        guard let value = Int(text) else { return text }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "'"
        formatter.usesGroupingSeparator = abs(value) >= 1000
        return formatter.string(from: NSNumber(value: value)) ?? text
    }

    @ViewBuilder
    private var lcdBezelBackground: some View {
        let lcd = theme.lcd
        let shape = RoundedRectangle(cornerRadius: 6, style: .continuous)
        if lcd.useFlatBezel {
            shape
                .fill(lcd.panelBackground)
                .overlay(shape.strokeBorder(lcd.bezelOuterStroke, lineWidth: 1))
                .shadow(color: lcd.bezelShadow, radius: 1, x: 0, y: 1)
        } else {
            shape
                .fill(lcd.panelBackground)
                .overlay(
                    shape
                        .strokeBorder(lcd.bezelOuterStroke, lineWidth: 1)
                )
                .overlay {
                    shape
                        .strokeBorder(
                            LinearGradient(
                                colors: lcd.bezelInnerGradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .padding(1)
                }
                .shadow(color: lcd.bezelShadow, radius: 3, x: 0, y: 2)
                .overlay(
                    shape
                        .stroke(lcd.bezelHighlightStroke, lineWidth: 1)
                        .padding(-0.5)
                )
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        SegmentedReadoutView(
            caption: "Table",
            isTableReadout: true,
            tableText: "42",
            tableExpressionLine: "1+1+5+6+10+18=42",
            dicePoolSelectionTally: "",
            diceDetailLine: "",
            diceTotalLine: "",
            bandMode: .sum
        )
        SegmentedReadoutView(
            caption: "SETTINGS",
            isTableReadout: true,
            tableText: "",
            tableExpressionLine: "",
            dicePoolSelectionTally: "",
            diceDetailLine: "",
            diceTotalLine: "",
            bandMode: .sum,
            isSettingsMode: true,
            settingsTitleLines: ["1 - THEMES"],
            settingsFooterLine: "SUM/TOT · SELECT"
        )
        SegmentedReadoutView(
            caption: "Dice",
            isTableReadout: false,
            tableText: "",
            tableExpressionLine: "",
            dicePoolSelectionTally: "2d4+1d20",
            diceDetailLine: "d4[2,3]=5 · d20[19]=19",
            diceTotalLine: "24",
            bandMode: .total
        )
    }
    .padding()
    .calculatorTheme(.vintage)
    .background(
        LinearGradient(
            colors: [
                Color(red: 0.12, green: 0.11, blue: 0.10),
                Color(red: 0.06, green: 0.05, blue: 0.05),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}

#Preview("Antique Apple") {
    SegmentedReadoutView(
        caption: "Table",
        isTableReadout: true,
        tableText: "42",
        tableExpressionLine: "1+1+5=7",
        dicePoolSelectionTally: "",
        diceDetailLine: "",
        diceTotalLine: "",
        bandMode: .sum
    )
    .padding()
    .calculatorTheme(.antiqueApple)
    .background(Color(white: 0.5))
}

#Preview("Antique Apple total") {
    SegmentedReadoutView(
        caption: "Dice",
        isTableReadout: false,
        tableText: "",
        tableExpressionLine: "",
        dicePoolSelectionTally: "2d6",
        diceDetailLine: "d6[4,3]=7",
        diceTotalLine: "7",
        bandMode: .total
    )
    .padding()
    .calculatorTheme(.antiqueApple)
    .background(Color(white: 0.5))
}
