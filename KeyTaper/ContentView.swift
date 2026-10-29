//
//  ContentView.swift
//  KeyTaper
//
//  Created by Qilei on 2026/10/29.
//

import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    private static let countFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            if !appState.hasAccessibilityPermission {
                permissionBanner
            }

            historySection

            Divider()

            controls
        }
        .padding(16)
        .frame(width: 280)
        .onAppear {
            appState.refreshPermissionAndMonitor()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Today")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(formattedCount(appState.todayCount))
                .font(.system(size: 36, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.snappy, value: appState.todayCount)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var permissionBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Accessibility access is required to count keystrokes. KeyTaper only counts taps and never records which keys you press.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button("Open Accessibility Settings") {
                appState.openAccessibilitySettings()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.yellow.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent days")
                .font(.caption)
                .foregroundStyle(.secondary)

            if appState.recentHistory.isEmpty {
                Text("No history yet")
                    .font(.callout)
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(appState.recentHistory) { day in
                    HStack {
                        Text(displayDate(day.date))
                            .font(.callout)
                        Spacer()
                        Text(formattedCount(day.count))
                            .font(.callout.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var controls: some View {
        HStack {
            Spacer()
            Button("Quit") {
                appState.quit()
            }
            .keyboardShortcut("q")
        }
        .controlSize(.small)
    }

    private func formattedCount(_ value: Int) -> String {
        Self.countFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private func displayDate(_ key: String) -> String {
        if let date = DayKey.date(from: key) {
            return Self.dayFormatter.string(from: date)
        }
        return key
    }
}

#Preview {
    ContentView()
        .environment(AppState())
}
