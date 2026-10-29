//
//  KeycastOverlayView.swift
//  KeyTaper
//

import AppKit
import SwiftUI

struct KeycastOverlayView: View {
    @Environment(AppState.self) private var appState

    private let hudWidth: CGFloat = 180
    private let topHeight: CGFloat = 52
    private let barHeight: CGFloat = 32
    private let cornerRadius: CGFloat = 14
    private let gap: CGFloat = 1
    private let letterKeySize: CGFloat = 26
    private let symbolKeySize: CGFloat = 16
    private let panelFill = Color.black.opacity(0.8)
    private let gapFill = Color.black.opacity(0.4)
    private let inactive = Color(white: 0.55)
    private let active = Color.white

    private var hudShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    var body: some View {
        VStack(spacing: 0) {
            keyDisplay
                .frame(maxWidth: .infinity)
                .frame(height: topHeight)
                .background(
                    panelFill,
                    in: UnevenRoundedRectangle(
                        topLeadingRadius: cornerRadius,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: cornerRadius,
                        style: .continuous
                    )
                )

            gapFill
                .frame(height: gap)

            modifierBar
                .frame(height: barHeight)
        }
        .frame(width: hudWidth)
        .contentShape(hudShape)
        .shadow(color: .black.opacity(0.25), radius: 6, y: 2)
        // Transparent inset so the panel frame includes the shadow (no blur in this region).
        .padding(10)
        .gesture(WindowDragGesture())
        .animation(nil, value: appState.recentKeys)
        .animation(nil, value: appState.activeModifiers.rawValue)
    }

    private var keyDisplay: some View {
        Group {
            if appState.recentKeys.isEmpty {
                Color.clear
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    // Reserve letter-size line metrics so the row height never jumps.
                    Text("A")
                        .font(overlayFont(size: letterKeySize, weight: .regular))
                        .hidden()
                        .frame(width: 0)
                        .accessibilityHidden(true)

                    ForEach(appState.recentKeys) { key in
                        Text(key.label)
                            .font(overlayFont(size: keyFontSize(for: key.label), weight: .regular))
                            .foregroundStyle(active)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                }
                .padding(.horizontal, 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Latin letters read larger; symbols / F-keys / punctuation stay compact.
    private func keyFontSize(for label: String) -> CGFloat {
        guard label.count == 1, let ch = label.first, ch.isASCII, ch.isLetter else {
            return symbolKeySize
        }
        return letterKeySize
    }

    /// Same face as KeyCastr: macOS system font (SF Pro via `NSFont.systemFont`).
    private func overlayFont(size: CGFloat, weight: Font.Weight) -> Font {
        OverlayFont.system.font(size: size, weight: weight)
    }

    private var modifierBar: some View {
        HStack(spacing: 0) {
            modifierCell(
                "⇧",
                isOn: appState.activeModifiers.contains(.shift),
                bottomLeading: cornerRadius,
                bottomTrailing: 0
            )
            gapFill
                .frame(width: gap)
            modifierCell(
                "⌃",
                isOn: appState.activeModifiers.contains(.control),
                bottomLeading: 0,
                bottomTrailing: 0
            )
            gapFill
                .frame(width: gap)
            modifierCell(
                "⌥",
                isOn: appState.activeModifiers.contains(.option),
                bottomLeading: 0,
                bottomTrailing: 0
            )
            gapFill
                .frame(width: gap)
            modifierCell(
                "⌘",
                isOn: appState.activeModifiers.contains(.command),
                bottomLeading: 0,
                bottomTrailing: cornerRadius
            )
        }
    }

    private func modifierCell(
        _ symbol: String,
        isOn: Bool,
        bottomLeading: CGFloat,
        bottomTrailing: CGFloat
    ) -> some View {
        Text(symbol)
            // Match KeyCastr Svelte: boldSystemFont for modifier glyphs.
            .font(overlayFont(size: 15, weight: .bold))
            .foregroundStyle(isOn ? active : inactive)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .shadow(color: isOn ? .white.opacity(0.35) : .clear, radius: 4)
            .background(
                panelFill,
                in: UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: bottomLeading,
                    bottomTrailingRadius: bottomTrailing,
                    topTrailingRadius: 0,
                    style: .continuous
                )
            )
    }
}

#Preview {
    KeycastOverlayView()
        .environment(AppState())
        .padding()
        .background(Color.gray)
}
