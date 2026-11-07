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
    @State private var showCalendar = false
    @State private var calendarMonth = Date()
    @State private var hoveredDay: String?

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

    private static let compactDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter
    }()

    private static let yearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter
    }()

    private static let monthTitleFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter
    }()

    private static let calendarDaySize: CGFloat = 17

    var body: some View {
        @Bindable var appState = appState

        VStack(alignment: .leading, spacing: 8) {
            header

            if !appState.hasAccessibilityPermission {
                permissionBanner
            }

            if showCalendar {
                calendarSection
            }

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
        let displayedDate = selectedDate ?? appState.todayDate
        let displayedCount = count(for: displayedDate)

        return HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Button(action: selectToday) {
                    Text(displayedDate == appState.todayDate ? "Today" : compactDisplayDate(displayedDate))
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .buttonStyle(.plain)

                HStack(alignment: .center, spacing: 4) {
                    Button(action: selectToday) {
                        Text(displayYear(displayedDate))
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)

                    Button {
                        toggleCalendar()
                    } label: {
                        Image(systemName: "calendar")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(showCalendar ? 0.9 : 0.55))
                            .frame(width: 12, height: 12)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("Choose a day")
                }
                .frame(height: 18)
            }

            Spacer(minLength: 8)

            Button(action: selectToday) {
                Text(formattedCount(displayedCount))
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.1)
                    .allowsTightening(true)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: displayedCount)
                    .foregroundStyle(.white.opacity(0.94))
            }
            .buttonStyle(.plain)
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

    private var calendarSection: some View {
        let calendar = Calendar.current
        let days = monthDays(for: calendarMonth)
        let weekdaySymbols = calendar.veryShortWeekdaySymbols
        let firstWeekday = calendar.firstWeekday
        let orderedWeekdays = (0..<7).map { weekdaySymbols[($0 + firstWeekday - 1) % 7] }

        return VStack(spacing: 6) {
            HStack(spacing: 4) {
                Button {
                    shiftMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(width: 18, height: 18)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Text(Self.monthTitleFormatter.string(from: calendarMonth))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.82))
                    .frame(maxWidth: .infinity)

                Button {
                    shiftMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(canGoToNextMonth ? 0.7 : 0.25))
                        .frame(width: 18, height: 18)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!canGoToNextMonth)
            }

            HStack(spacing: 0) {
                ForEach(Array(orderedWeekdays.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7),
                spacing: 1
            ) {
                ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                    if let day {
                        calendarDayCell(day, column: index % 7)
                    } else {
                        Color.clear
                            .frame(height: Self.calendarDaySize)
                    }
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity)
        .background(
            Color.white.opacity(0.06),
            in: RoundedRectangle(cornerRadius: 8)
        )
    }

    private func calendarDayCell(_ date: Date, column: Int) -> some View {
        let dayKey = DayKey.string(from: date)
        let dayNumber = Calendar.current.component(.day, from: date)
        let isFuture = dayKey > appState.todayDate
        let isSelected = selectedDate == dayKey
        let isToday = dayKey == appState.todayDate
        let isHovered = hoveredDay == dayKey
        let dayCount = count(for: dayKey)
        let tooltipAlignment: Alignment = column >= 4 ? .topTrailing : .topLeading

        return Button {
            guard !isFuture else { return }
            selectedDate = dayKey
        } label: {
            Text("\(dayNumber)")
                .font(.system(size: 9, weight: isToday || isSelected ? .semibold : .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(
                    isFuture
                        ? Color.white.opacity(0.22)
                        : Color.white.opacity(isSelected || isToday ? 0.95 : 0.72)
                )
                .frame(width: Self.calendarDaySize, height: Self.calendarDaySize)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            isSelected
                                ? Color.white.opacity(0.14)
                                : isHovered && !isFuture
                                    ? Color.white.opacity(0.08)
                                    : Color.clear
                        )
                )
                .overlay {
                    if isToday && !isSelected {
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(Color.white.opacity(0.28), lineWidth: 1)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: Self.calendarDaySize)
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
        .overlay(alignment: tooltipAlignment) {
            if isHovered && !isFuture {
                panelTooltip(
                    name: compactDisplayDate(dayKey),
                    count: dayCount
                )
                .fixedSize()
                .frame(height: 0, alignment: .bottom)
                .offset(y: -4)
            }
        }
        .zIndex(isHovered ? 1000 : 0)
        .onHover { hovering in
            guard !isFuture else { return }
            if hovering {
                hoveredDay = dayKey
            } else if hoveredDay == dayKey {
                hoveredDay = nil
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

    private var canGoToNextMonth: Bool {
        let calendar = Calendar.current
        guard let today = DayKey.date(from: appState.todayDate) else { return false }
        let visible = calendar.dateComponents([.year, .month], from: calendarMonth)
        let todayComponents = calendar.dateComponents([.year, .month], from: today)
        guard let visibleYear = visible.year,
              let visibleMonth = visible.month,
              let todayYear = todayComponents.year,
              let todayMonth = todayComponents.month else {
            return false
        }
        return (visibleYear, visibleMonth) < (todayYear, todayMonth)
    }

    private func selectToday() {
        selectedDate = appState.todayDate
        showCalendar = false
        hoveredDay = nil
    }

    private func toggleCalendar() {
        if showCalendar {
            showCalendar = false
            hoveredDay = nil
            return
        }
        syncCalendarMonth(to: selectedDate ?? appState.todayDate)
        showCalendar = true
    }

    private func syncCalendarMonth(to dayKey: String) {
        if let date = DayKey.date(from: dayKey) {
            calendarMonth = startOfMonth(for: date)
        } else if let today = DayKey.date(from: appState.todayDate) {
            calendarMonth = startOfMonth(for: today)
        } else {
            calendarMonth = startOfMonth(for: Date())
        }
    }

    private func shiftMonth(by value: Int) {
        let calendar = Calendar.current
        guard let next = calendar.date(byAdding: .month, value: value, to: startOfMonth(for: calendarMonth)) else {
            return
        }
        if value > 0 {
            guard let today = DayKey.date(from: appState.todayDate) else { return }
            let nextComponents = calendar.dateComponents([.year, .month], from: next)
            let todayComponents = calendar.dateComponents([.year, .month], from: today)
            guard let nextYear = nextComponents.year,
                  let nextMonth = nextComponents.month,
                  let todayYear = todayComponents.year,
                  let todayMonth = todayComponents.month,
                  (nextYear, nextMonth) <= (todayYear, todayMonth) else {
                return
            }
        }
        calendarMonth = next
        hoveredDay = nil
    }

    private func startOfMonth(for date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }

    /// Month grid cells for a full set of weeks. `nil` marks empty leading/trailing slots.
    private func monthDays(for month: Date) -> [Date?] {
        let calendar = Calendar.current
        let start = startOfMonth(for: month)
        guard let dayRange = calendar.range(of: .day, in: .month, for: start) else {
            return Array(repeating: nil, count: 42)
        }

        let weekdayOfStart = calendar.component(.weekday, from: start)
        let leading = (weekdayOfStart - calendar.firstWeekday + 7) % 7
        var days: [Date?] = Array(repeating: nil, count: leading)

        for day in dayRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: start) {
                days.append(date)
            }
        }

        while days.count % 7 != 0 {
            days.append(nil)
        }
        return days
    }

    private func count(for dayKey: String) -> Int {
        if dayKey == appState.todayDate {
            return appState.todayCount
        }
        return appState.history.first(where: { $0.date == dayKey })?.count ?? 0
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

    private func compactDisplayDate(_ key: String) -> String {
        if let date = DayKey.date(from: key) {
            return Self.compactDayFormatter.string(from: date)
        }
        return key
    }

    private func displayYear(_ key: String) -> String {
        if let date = DayKey.date(from: key) {
            return Self.yearFormatter.string(from: date)
        }
        return String(key.prefix(4))
    }
}

#Preview {
    ContentView()
        .environment(AppState())
}
