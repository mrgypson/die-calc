import SwiftUI

/// LCD: pale green panel. SUM mode = expression band only; TOT mode = large digit readout only.
struct SegmentedReadoutView: View {
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

    /// Muted olive-gray LCD background (~#b8c3a9).
    private let lcdBackground = Color(red: 0.722, green: 0.765, blue: 0.663)
    /// Dark charcoal segments (~#3a3d3a).
    private let lcdForeground = Color(red: 0.227, green: 0.239, blue: 0.227)
    /// Slightly lighter for secondary / inactive glyphs.
    private let lcdForegroundDim = Color(red: 0.227, green: 0.239, blue: 0.227).opacity(0.72)
    /// Fixed band for expression lines so layout stays stable.
    private let expressionBandHeight: CGFloat = 56

    var body: some View {
        VStack(spacing: 0) {
            Text(caption.uppercased())
                .font(.system(size: 9, weight: .bold, design: .default))
                .foregroundStyle(lcdForegroundDim)
                .tracking(0.8)
                .frame(maxWidth: .infinity)
                .padding(.top, 6)
                .padding(.bottom, 4)

            VStack(alignment: .leading, spacing: 0) {
                if bandMode == .sum {
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

    private var expressionBand: some View {
        VStack(alignment: .leading, spacing: 3) {
            if isTableReadout {
                Text(tableExpressionLine)
                    .font(dotMatrixFont)
                    .foregroundStyle(lcdForeground)
                    .tracking(tableExpressionLine == "SUM" ? 1 : 0.6)
                    .lineLimit(1)
                    .minimumScaleFactor(0.45)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(dicePoolSelectionTally.isEmpty ? "—" : dicePoolSelectionTally)
                    .font(dotMatrixFont)
                    .foregroundStyle(lcdForeground)
                    .tracking(0.6)
                    .lineLimit(1)
                    .minimumScaleFactor(0.45)

                if !diceDetailLine.isEmpty {
                    Text(diceDetailLine)
                        .font(dotMatrixFontSmall)
                        .foregroundStyle(lcdForegroundDim)
                        .lineLimit(2)
                        .minimumScaleFactor(0.5)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(height: expressionBandHeight, alignment: .topLeading)
    }

    private var dotMatrixFont: Font {
        .system(size: 13, weight: .semibold, design: .monospaced)
    }

    private var dotMatrixFontSmall: Font {
        .system(size: 11, weight: .medium, design: .monospaced)
    }

    private func primaryReadout(text: String) -> some View {
        let display = formatLCDPrimaryDisplay(text)
        return Text(display)
            .font(.system(size: 46, weight: .heavy, design: .rounded))
            .italic()
            .tracking(5)
            .foregroundStyle(lcdForeground)
            .shadow(color: lcdForeground.opacity(0.35), radius: 0, x: 0.6, y: 0)
            .shadow(color: lcdForeground.opacity(0.2), radius: 1.5, x: 0, y: 0)
            .minimumScaleFactor(0.28)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.horizontal, 2)
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

    private var lcdBezelBackground: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(lcdBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.22), lineWidth: 1)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.28),
                                Color.black.opacity(0.06),
                                Color.white.opacity(0.12),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .padding(1)
            }
            .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    .padding(-0.5)
            )
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
