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
    @State private var hoveredHour: Int?

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

        VStack(alignment: .leading, spacing: 8) {
            header

            if !appState.hasAccessibilityPermission {
                permissionBanner
            }

            historySection

            dayHourlySummary
            dayKeySummary
            dayMouseSummary

            panelDivider

            Toggle("Show key overlay", isOn: $appState.isOverlayVisible)
                .controlSize(.small)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.86))
                .padding(.horizontal, 2)

            Text("Overlay shows recent keys in memory only. Per-key tallies are stored for today and each past day.")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.54))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 2)

            panelDivider

            controls
        }
        .padding(10)
        .frame(width: 186)
        .background(MenuBarWindowBackground())
        .preferredColorScheme(.dark)
        .onAppear {
            appState.refreshPermissionAndMonitor()
            if selectedDate == nil {
                selectedDate = appState.todayDate
            }
        }
        .onChange(of: appState.todayDate) { oldToday, newToday in
            if selectedDate == nil || selectedDate == oldToday {
                selectedDate = newToday
            }
        }
    }

    private var panelDivider: some View {
        Divider()
            .overlay(Color.white.opacity(0.12))
    }

    private var header: some View {
        Button {
            selectedDate = appState.todayDate
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Today")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.62))
                Spacer(minLength: 8)
                Text(formattedCount(appState.todayCount))
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.snappy, value: appState.todayCount)
                    .foregroundStyle(.white.opacity(0.94))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(red: 20 / 255, green: 20 / 255, blue: 20 / 255).opacity(0.3))
                    .overlay {
                        if selectedDate == appState.todayDate {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.08))
                        }
                    }
            )
        }
        .buttonStyle(.plain)
    }

    private var permissionBanner: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Accessibility access is required to count keystrokes and show the key overlay.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)

            Button("Open Accessibility Settings") {
                appState.openAccessibilitySettings()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.white.opacity(0.08),
            in: RoundedRectangle(cornerRadius: 8)
        )
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Recent days")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.54))

            if appState.recentHistory.isEmpty {
                Text("No history yet")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.56))
            } else {
                ForEach(appState.recentHistory) { day in
                    Button {
                        selectedDate = day.date
                    } label: {
                        HStack {
                            Text(displayDate(day.date))
                                .font(.callout)
                                .foregroundStyle(.white)
                            Spacer()
                            Text(formattedCount(day.count))
                                .font(.callout.monospacedDigit())
                                .foregroundStyle(.white.opacity(0.72))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            selectedDate == day.date
                                ? Color.white.opacity(0.08)
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
            VStack(alignment: .leading, spacing: 4) {
                Text(selectedDate == appState.todayDate ? "Hourly today" : "Hourly")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.54))

                if maxCount == 0 {
                    Text("No hourly data for this day")
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.56))
                } else {
                    HStack(alignment: .bottom, spacing: 2) {
                        ForEach(0..<HourlyCounts.hourCount, id: \.self) { hour in
                            hourlyBar(
                                hour: hour,
                                value: hours[hour],
                                maxCount: maxCount
                            )
                        }
                    }
                    .frame(height: 24, alignment: .bottom)

                    if let peak = hours.enumerated().max(by: { $0.element < $1.element }),
                       peak.element > 0 {
                        Text("Peak \(String(format: "%02d:00", peak.offset)) · \(formattedCount(peak.element))")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.56))
                    }
                }
            }
        }
    }

    private func hourlyBar(hour: Int, value: Int, maxCount: Int) -> some View {
        let barHeight = value > 0
            ? max(2, CGFloat(value) / CGFloat(maxCount) * 24)
            : 1
        let isHovered = hoveredHour == hour
        // Right half of the day pins tooltip to trailing edge.
        let tooltipAlignment: Alignment = hour >= 12 ? .topTrailing : .topLeading

        return Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: 24)
            .overlay(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 1, style: .continuous)
                    .fill(value > 0 ? Color.white.opacity(0.85) : Color.white.opacity(0.12))
                    .frame(height: barHeight)
                    .overlay {
                        if isHovered {
                            RoundedRectangle(cornerRadius: 1, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.45), lineWidth: 1)
                        }
                    }
            }
            .overlay(alignment: tooltipAlignment) {
                if isHovered {
                    panelTooltip(
                        name: String(format: "%02d:00", hour),
                        count: value
                    )
                    .fixedSize()
                    .frame(height: 0, alignment: .bottom)
                    .offset(y: -4)
                }
            }
            .zIndex(isHovered ? 1000 : 0)
            .onHover { hovering in
                if hovering {
                    hoveredHour = hour
                } else if hoveredHour == hour {
                    hoveredHour = nil
                }
            }
    }

    private func panelTooltip(name: String, count: Int) -> some View {
        HStack(spacing: 6) {
            Text(name)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.94))
            Text(formattedCount(count))
                .font(.system(size: 11, weight: .medium, design: .rounded).monospacedDigit())
                .foregroundStyle(.white.opacity(0.62))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Color(white: 0.12).opacity(0.95),
            in: RoundedRectangle(cornerRadius: 6, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 3, y: 1)
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private var dayKeySummary: some View {
        if let selectedDate {
            let counts = appState.keyCounts(on: selectedDate)
            let clicks = appState.mouseClicks(on: selectedDate)
            VStack(alignment: .leading, spacing: 4) {
                Text(selectedDate == appState.todayDate ? "Keys today" : "Keys on \(displayDate(selectedDate))")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.54))

                KeyboardHeatmapView(
                    counts: counts,
                    leftClicks: clicks.left,
                    rightClicks: clicks.right
                )
                .animation(nil, value: appState.todayCount)
                .animation(nil, value: appState.todayLeftClicks)
                .animation(nil, value: appState.todayRightClicks)

                if counts.isEmpty {
                    Text(selectedDate == appState.todayDate
                         ? "No per-key data for today yet"
                         : "No per-key data for this day")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.56))
                }
            }
        }
    }

    @ViewBuilder
    private var dayMouseSummary: some View {
        if let selectedDate {
            let clicks = appState.mouseClicks(on: selectedDate)
            HStack(spacing: 10) {
                Text("Mouse")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.54))
                Spacer()
                Text("L \(formattedCount(clicks.left))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.72))
                Text("R \(formattedCount(clicks.right))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.72))
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
            .font(.caption)
            .foregroundStyle(.white.opacity(0.86))
            .buttonStyle(.borderless)
            .keyboardShortcut("q")
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 2)
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
