//
//  KeyboardHeatmapView.swift
//  KeyTaper
//

import SwiftUI

struct KeyboardHeatmapView: View {
    let counts: [UInt16: Int]

    @State private var hoveredKeyID: String?

    private let gap: CGFloat = 1
    /// Unit key size (1u × 1u).
    private let unitSize: CGFloat = 8
    private let cornerRadius: CGFloat = 1.5
    private let rowCount = 6

    private var maxCount: Int {
        counts.values.max() ?? 0
    }

    private var keyboardHeight: CGFloat {
        CGFloat(rowCount) * unitSize + CGFloat(rowCount - 1) * gap
    }

    private var hoveredKey: HeatmapKey? {
        guard let hoveredKeyID else { return nil }
        return Self.allKeys.first { $0.id == hoveredKeyID }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            tooltipBar

            HStack(alignment: .bottom, spacing: gap * 3) {
                mainKeyboard
                arrowCluster
            }
            .frame(height: keyboardHeight)
        }
    }

    private var tooltipBar: some View {
        Group {
            if let key = hoveredKey {
                let count = key.keyCode.flatMap { counts[$0] } ?? 0
                HStack(spacing: 6) {
                    Text(displayName(for: key))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                    Text(formattedCount(count))
                        .font(.system(size: 11, weight: .medium, design: .rounded).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.background.opacity(0.95), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
            } else {
                Text(" ")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .hidden()
            }
        }
        .frame(height: 22, alignment: .leading)
        .animation(.easeOut(duration: 0.12), value: hoveredKeyID)
    }

    private var mainKeyboard: some View {
        VStack(alignment: .leading, spacing: gap) {
            ForEach(Array(Self.rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: gap) {
                    if row.leadingInsetUnits > 0 {
                        Color.clear
                            .frame(
                                width: unitSize * row.leadingInsetUnits,
                                height: unitSize
                            )
                    }
                    ForEach(row.keys) { key in
                        keyCap(key)
                            .frame(
                                width: unitSize * key.widthUnits,
                                height: unitSize
                            )
                    }
                }
            }
        }
    }

    /// Inverted-T arrows on the right (↑ / ← ↓ →).
    private var arrowCluster: some View {
        VStack(spacing: gap) {
            HStack(spacing: gap) {
                Color.clear.frame(width: unitSize, height: unitSize)
                keyCap(.init(126, "↑", 1))
                    .frame(width: unitSize, height: unitSize)
                Color.clear.frame(width: unitSize, height: unitSize)
            }
            HStack(spacing: gap) {
                keyCap(.init(123, "←", 1))
                    .frame(width: unitSize, height: unitSize)
                keyCap(.init(125, "↓", 1))
                    .frame(width: unitSize, height: unitSize)
                keyCap(.init(124, "→", 1))
                    .frame(width: unitSize, height: unitSize)
            }
        }
    }

    private func keyCap(_ key: HeatmapKey) -> some View {
        let count = key.keyCode.flatMap { counts[$0] } ?? 0
        let isHovered = hoveredKeyID == key.id
        return RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Self.fillColor(count: count, maxCount: maxCount))
            .overlay {
                if isHovered {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.35), lineWidth: 1)
                }
            }
            .onHover { hovering in
                if hovering {
                    hoveredKeyID = key.id
                } else if hoveredKeyID == key.id {
                    hoveredKeyID = nil
                }
            }
    }

    private func displayName(for key: HeatmapKey) -> String {
        key.label.isEmpty ? "space" : key.label
    }

    private func formattedCount(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    // MARK: - Colors (GitHub-style greens)

    private static func fillColor(count: Int, maxCount: Int) -> Color {
        if count <= 0 || maxCount <= 0 {
            return emptyFill
        }
        let t = CGFloat(count) / CGFloat(maxCount)
        let level = min(4, max(1, Int(ceil(t * 4))))
        return heatLevels[level - 1]
    }

    private static let emptyFill = Color(red: 0.92, green: 0.93, blue: 0.94)
    private static let heatLevels: [Color] = [
        Color(red: 0.61, green: 0.91, blue: 0.64), // #9be9a8
        Color(red: 0.25, green: 0.77, blue: 0.39), // #40c463
        Color(red: 0.18, green: 0.63, blue: 0.30), // #30a14e
        Color(red: 0.09, green: 0.40, blue: 0.16), // #216e39
    ]

    // MARK: - ANSI layout (physical keyCodes)

    private static let arrowKeys: [HeatmapKey] = [
        .init(126, "↑", 1),
        .init(123, "←", 1),
        .init(125, "↓", 1),
        .init(124, "→", 1),
    ]

    private static var allKeys: [HeatmapKey] {
        rows.flatMap(\.keys) + arrowKeys
    }

    private static let rows: [HeatmapRow] = [
        // Esc sits alone on the top-left (Mac layout); keyCode 53.
        HeatmapRow(leadingInsetUnits: 0, keys: [
            .init(53, "esc", 1.25),
        ]),
        HeatmapRow(leadingInsetUnits: 0, keys: [
            .init(50, "`", 1), .init(18, "1", 1), .init(19, "2", 1), .init(20, "3", 1),
            .init(21, "4", 1), .init(23, "5", 1), .init(22, "6", 1), .init(26, "7", 1),
            .init(28, "8", 1), .init(25, "9", 1), .init(29, "0", 1), .init(27, "-", 1),
            .init(24, "=", 1), .init(51, "⌫", 1.6),
        ]),
        HeatmapRow(leadingInsetUnits: 0.15, keys: [
            .init(48, "⇥", 1.5), .init(12, "q", 1), .init(13, "w", 1), .init(14, "e", 1),
            .init(15, "r", 1), .init(17, "t", 1), .init(16, "y", 1), .init(32, "u", 1),
            .init(34, "i", 1), .init(31, "o", 1), .init(35, "p", 1), .init(33, "[", 1),
            .init(30, "]", 1), .init(42, "\\", 1.35),
        ]),
        HeatmapRow(leadingInsetUnits: 0.35, keys: [
            .init(57, "⇪", 1.75), .init(0, "a", 1), .init(1, "s", 1), .init(2, "d", 1),
            .init(3, "f", 1), .init(5, "g", 1), .init(4, "h", 1), .init(38, "j", 1),
            .init(40, "k", 1), .init(37, "l", 1), .init(41, ";", 1), .init(39, "'", 1),
            .init(36, "⏎", 1.75),
        ]),
        HeatmapRow(leadingInsetUnits: 0.55, keys: [
            .init(56, "⇧", 2.25), .init(6, "z", 1), .init(7, "x", 1), .init(8, "c", 1),
            .init(9, "v", 1), .init(11, "b", 1), .init(45, "n", 1), .init(46, "m", 1),
            .init(43, ",", 1), .init(47, ".", 1), .init(44, "/", 1), .init(60, "⇧", 2.25),
        ]),
        HeatmapRow(leadingInsetUnits: 0.2, keys: [
            .init(59, "⌃", 1.25), .init(58, "⌥", 1.25), .init(55, "⌘", 1.5),
            .init(49, "⎵", 5.5),
            .init(54, "⌘", 1.5), .init(61, "⌥", 1.25), .init(62, "⌃", 1.25),
        ]),
    ]
}

// MARK: - Layout model

private struct HeatmapKey: Identifiable {
    let id: String
    let keyCode: UInt16?
    let label: String
    let widthUnits: CGFloat

    init(_ code: UInt16?, _ label: String, _ widthUnits: CGFloat) {
        keyCode = code
        self.label = label
        self.widthUnits = widthUnits
        if let code {
            id = "\(code)"
        } else {
            id = "blank-\(label)-\(widthUnits)"
        }
    }
}

private struct HeatmapRow {
    let leadingInsetUnits: CGFloat
    let keys: [HeatmapKey]
}

#Preview {
    KeyboardHeatmapView(counts: [
        0: 120, 1: 80, 2: 40, 12: 200, 13: 150, 49: 300, 36: 90,
    ])
    .padding()
}
