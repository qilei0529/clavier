//
//  ContentView.swift
//  KeyTaper
//
//  Created by Qilei on 2026/10/29.
//

import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedDate: String?

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
        @Bindable var appState = appState

        VStack(alignment: .leading, spacing: 16) {
            header

            if !appState.hasAccessibilityPermission {
                permissionBanner
            }

            historySection

            dayHourlySummary
            dayKeySummary
            dayMouseSummary

            Divider()

            Toggle("Show key overlay", isOn: $appState.isOverlayVisible)
                .controlSize(.small)

            Text("Overlay shows recent keys in memory only. Per-key tallies are stored for today and each past day.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            controls
        }
        .padding(16)
        .frame(width: 280)
        .onAppear {
            appState.refreshPermissionAndMonitor()
            if selectedDate == nil {
                selectedDate = appState.todayDate
            }
        }
    }

    private var header: some View {
        Button {
            selectedDate = appState.todayDate
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text("Today")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(formattedCount(appState.todayCount))
                    .font(.system(size: 36, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.snappy, value: appState.todayCount)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(6)
            .background(
                selectedDate == appState.todayDate
                    ? Color.accentColor.opacity(0.12)
                    : Color.clear,
                in: RoundedRectangle(cornerRadius: 8)
            )
        }
        .buttonStyle(.plain)
    }

    private var permissionBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Accessibility access is required to count keystrokes and show the key overlay.")
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
                    Button {
                        selectedDate = day.date
                    } label: {
                        HStack {
                            Text(displayDate(day.date))
                                .font(.callout)
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(formattedCount(day.count))
                                .font(.callout.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(
                            selectedDate == day.date
                                ? Color.accentColor.opacity(0.12)
                                : Color.clear,
                            in: RoundedRectangle(cornerRadius: 6)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var dayHourlySummary: some View {
        if let selectedDate {
            let hours = appState.hourlyCounts(on: selectedDate)
            let maxCount = hours.max() ?? 0
            VStack(alignment: .leading, spacing: 8) {
                Text(selectedDate == appState.todayDate ? "Hourly today" : "Hourly")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if maxCount == 0 {
                    Text("No hourly data for this day")
                        .font(.callout)
                        .foregroundStyle(.tertiary)
                } else {
                    HStack(alignment: .bottom, spacing: 2) {
                        ForEach(0..<HourlyCounts.hourCount, id: \.self) { hour in
                            let value = hours[hour]
                            let barHeight = value > 0
                                ? max(2, CGFloat(value) / CGFloat(maxCount) * 36)
                                : 1
                            RoundedRectangle(cornerRadius: 1, style: .continuous)
                                .fill(value > 0 ? Color.accentColor.opacity(0.85) : Color.secondary.opacity(0.15))
                                .frame(maxWidth: .infinity)
                                .frame(height: barHeight)
                        }
                    }
                    .frame(height: 36, alignment: .bottom)

                    if let peak = hours.enumerated().max(by: { $0.element < $1.element }),
                       peak.element > 0 {
                        Text("Peak \(String(format: "%02d:00", peak.offset)) · \(formattedCount(peak.element))")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var dayKeySummary: some View {
        if let selectedDate {
            let counts = appState.keyCounts(on: selectedDate)
            let clicks = appState.mouseClicks(on: selectedDate)
            VStack(alignment: .leading, spacing: 8) {
                Text(selectedDate == appState.todayDate ? "Keys today" : "Keys on \(displayDate(selectedDate))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                KeyboardHeatmapView(
                    counts: counts,
                    leftClicks: clicks.left,
                    rightClicks: clicks.right
                )
                .animation(nil, value: appState.todayLeftClicks)
                .animation(nil, value: appState.todayRightClicks)

                if counts.isEmpty {
                    Text("No per-key data for this day yet")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    @ViewBuilder
    private var dayMouseSummary: some View {
        if let selectedDate {
            let clicks = appState.mouseClicks(on: selectedDate)
            HStack(spacing: 12) {
                Text("Mouse")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("L \(formattedCount(clicks.left))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Text("R \(formattedCount(clicks.right))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            // Ensure live today clicks invalidate this view.
            .animation(nil, value: appState.todayLeftClicks)
            .animation(nil, value: appState.todayRightClicks)
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
