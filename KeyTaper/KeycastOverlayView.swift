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
    private let line = Color.white.opacity(0.28)
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

            Rectangle()
                .fill(line)
                .frame(height: 1)

            modifierBar
                .frame(height: barHeight)
        }
        .frame(width: hudWidth)
        .background(hudShape.fill(Color.black.opacity(0.89)))
        .clipShape(hudShape)
        .contentShape(hudShape)
        .shadow(color: .black.opacity(0.35), radius: 10, y: 4)
        .gesture(WindowDragGesture())
        .animation(nil, value: appState.recentKeys)
        .animation(nil, value: appState.activeModifiers.rawValue)
    }

    private var keyDisplay: some View {
        Group {
            if appState.recentKeys.isEmpty {
                Color.clear
            } else {
                HStack(spacing: 6) {
                    ForEach(appState.recentKeys) { key in
                        Text(key.label)
                            .font(.system(size: 22, weight: .semibold, design: .default))
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

    private var modifierBar: some View {
        HStack(spacing: 0) {
            modifierCell("⇧", isOn: appState.activeModifiers.contains(.shift))
            barDivider
            modifierCell("⌃", isOn: appState.activeModifiers.contains(.control))
            barDivider
            modifierCell("⌥", isOn: appState.activeModifiers.contains(.option))
            barDivider
            modifierCell("⌘", isOn: appState.activeModifiers.contains(.command))
        }
    }

    private var barDivider: some View {
        Rectangle()
            .fill(line)
            .frame(width: 1)
            .frame(maxHeight: .infinity)
    }

    private func modifierCell(_ symbol: String, isOn: Bool) -> some View {
        Text(symbol)
            .font(.system(size: 15, weight: .light, design: .default))
            .foregroundStyle(isOn ? active : inactive)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .shadow(color: isOn ? .white.opacity(0.35) : .clear, radius: 4)
    }
}

#Preview {
    KeycastOverlayView()
        .environment(AppState())
        .padding()
        .background(Color.gray)
}
