//
//  AppState.swift
//  KeyTaper
//

import AppKit
import Foundation
import Observation

@Observable
@MainActor
final class AppState {
    private static let overlayVisibleKey = "isOverlayVisible"
    private static let maxRecentKeys = 6
    private static let recentKeysIdleClear: Duration = .seconds(5)

    private(set) var todayCount: Int = 0
    private(set) var history: [DayCount] = []
    private(set) var hasAccessibilityPermission: Bool = false
    private(set) var recentKeys: [RecentKey] = []
    private(set) var activeModifiers: NSEvent.ModifierFlags = []
    var isOverlayVisible: Bool {
        didSet {
            UserDefaults.standard.set(isOverlayVisible, forKey: Self.overlayVisibleKey)
        }
    }

    private let store: StatsStore
    private var stats: KeystrokeStats
    private var monitor: KeystrokeMonitor?
    private var persistTask: Task<Void, Never>?
    private var recentKeysClearTask: Task<Void, Never>?
    nonisolated(unsafe) private var dayChangeObserver: NSObjectProtocol?
    nonisolated(unsafe) private var becomeActiveObserver: NSObjectProtocol?

    var menuBarTitle: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let countText = formatter.string(from: NSNumber(value: todayCount)) ?? "\(todayCount)"

        if !hasAccessibilityPermission {
            return "⚠︎ \(countText)"
        }
        return countText
    }

    var recentHistory: [DayCount] {
        Array(history.prefix(14))
    }

    var todayDate: String {
        stats.todayDate
    }

    /// Lifetime per-key tallies. Keys are physical keyCodes.
    var keyCounts: [UInt16: Int] {
        Self.mapKeyCounts(stats.keyCounts)
    }

    /// Per-key tallies for a calendar day (`yyyy-MM-dd`). Today uses the live map.
    func keyCounts(on date: String) -> [UInt16: Int] {
        if date == stats.todayDate {
            return Self.mapKeyCounts(stats.todayKeyCounts)
        }
        guard let day = stats.days.first(where: { $0.date == date }) else {
            return [:]
        }
        return Self.mapKeyCounts(day.keyCounts)
    }

    /// Top keys for a day, highest count first.
    func topKeyCounts(on date: String, limit: Int = 8) -> [(code: UInt16, count: Int)] {
        keyCounts(on: date)
            .map { (code: $0.key, count: $0.value) }
            .sorted {
                if $0.count != $1.count { return $0.count > $1.count }
                return $0.code < $1.code
            }
            .prefix(limit)
            .map { $0 }
    }

    /// Per-hour totals for a calendar day (always length 24). Today uses the live array.
    func hourlyCounts(on date: String) -> [Int] {
        if date == stats.todayDate {
            return HourlyCounts.normalized(stats.todayHourlyCounts)
        }
        guard let day = stats.days.first(where: { $0.date == date }) else {
            return HourlyCounts.empty
        }
        return HourlyCounts.normalized(day.hourlyCounts)
    }

    private static func mapKeyCounts(_ raw: [String: Int]) -> [UInt16: Int] {
        var result: [UInt16: Int] = [:]
        result.reserveCapacity(raw.count)
        for (key, count) in raw {
            guard let code = UInt16(key) else { continue }
            result[code] = count
        }
        return result
    }

    init(store: StatsStore = StatsStore()) {
        self.store = store
        self.stats = store.load()
        if UserDefaults.standard.object(forKey: Self.overlayVisibleKey) == nil {
            self.isOverlayVisible = true
        } else {
            self.isOverlayVisible = UserDefaults.standard.bool(forKey: Self.overlayVisibleKey)
        }
        applyDayBoundaryIfNeeded(persist: true)
        syncFromStats()
        startObservers()
        refreshPermissionAndMonitor()
    }

    func openAccessibilitySettings() {
        AccessibilityPermission.requestIfNeeded()
        AccessibilityPermission.openSystemSettings()
    }

    func refreshPermissionAndMonitor() {
        if !AccessibilityPermission.isGranted {
            AccessibilityPermission.requestIfNeeded()
        }
        hasAccessibilityPermission = AccessibilityPermission.isGranted

        guard hasAccessibilityPermission else {
            monitor?.stop()
            return
        }

        if monitor == nil {
            monitor = KeystrokeMonitor { [weak self] event in
                Task { @MainActor in
                    self?.handleEvent(event)
                }
            }
        }

        _ = monitor?.start()
    }

    func quit() {
        persistNow()
        monitor?.stop()
        NSApplication.shared.terminate(nil)
    }

    private func handleEvent(_ event: NSEvent) {
        if event.type == .flagsChanged {
            activeModifiers = KeyLabelFormatter.activeModifiers(from: event.modifierFlags)
            // Modifiers do not emit keyDown; count presses here for the heatmap only.
            if KeyLabelFormatter.isModifierPressed(in: event) {
                recordModifierKey(event.keyCode)
            }
            return
        }

        guard event.type == .keyDown else { return }

        applyDayBoundaryIfNeeded(persist: true)
        guard hasAccessibilityPermission else { return }

        // Keep modifier chrome in sync with the key that was just pressed.
        activeModifiers = KeyLabelFormatter.activeModifiers(from: event.modifierFlags)

        todayCount += 1
        stats.todayCount = todayCount

        let codeKey = String(event.keyCode)
        stats.keyCounts[codeKey, default: 0] += 1
        stats.todayKeyCounts[codeKey, default: 0] += 1

        let hour = Calendar.current.component(.hour, from: Date())
        if stats.todayHourlyCounts.count != HourlyCounts.hourCount {
            stats.todayHourlyCounts = HourlyCounts.normalized(stats.todayHourlyCounts)
        }
        stats.todayHourlyCounts[hour] += 1

        schedulePersist()

        if let label = KeyLabelFormatter.keyName(for: event) {
            // Mask password / secure-field input in the overlay only; counts still use keyCode.
            appendRecentKey(SecureInputDetector.isActive ? "*" : label)
        }
    }

    /// Heatmap / per-day key maps only — does not inflate the menu-bar day total.
    private func recordModifierKey(_ keyCode: UInt16) {
        applyDayBoundaryIfNeeded(persist: true)
        guard hasAccessibilityPermission else { return }

        let codeKey = String(keyCode)
        stats.keyCounts[codeKey, default: 0] += 1
        stats.todayKeyCounts[codeKey, default: 0] += 1
        schedulePersist()
    }

    private func appendRecentKey(_ label: String) {
        recentKeys.append(RecentKey(label: label))
        if recentKeys.count > Self.maxRecentKeys {
            recentKeys.removeFirst(recentKeys.count - Self.maxRecentKeys)
        }
        scheduleRecentKeysClear()
    }

    private func scheduleRecentKeysClear() {
        recentKeysClearTask?.cancel()
        recentKeysClearTask = Task { @MainActor in
            try? await Task.sleep(for: Self.recentKeysIdleClear)
            guard !Task.isCancelled else { return }
            recentKeys = []
        }
    }

    private func applyDayBoundaryIfNeeded(persist: Bool) {
        let today = DayKey.string()
        guard stats.todayDate != today else { return }

        if stats.todayCount > 0 {
            upsertHistory(
                date: stats.todayDate,
                count: stats.todayCount,
                keyCounts: stats.todayKeyCounts,
                hourlyCounts: stats.todayHourlyCounts
            )
        }

        stats.todayDate = today
        stats.todayCount = 0
        stats.todayKeyCounts = [:]
        stats.todayHourlyCounts = HourlyCounts.empty
        todayCount = 0
        history = sortedHistory(stats.days)

        if persist {
            persistNow()
        }
    }

    private func upsertHistory(
        date: String,
        count: Int,
        keyCounts: [String: Int],
        hourlyCounts: [Int]
    ) {
        guard !date.isEmpty else { return }

        let normalizedHourly = HourlyCounts.normalized(hourlyCounts)
        if let index = stats.days.firstIndex(where: { $0.date == date }) {
            stats.days[index].count = count
            stats.days[index].keyCounts = keyCounts
            stats.days[index].hourlyCounts = normalizedHourly
        } else {
            stats.days.append(
                DayCount(
                    date: date,
                    count: count,
                    keyCounts: keyCounts,
                    hourlyCounts: normalizedHourly
                )
            )
        }

        stats.days = sortedHistory(stats.days)
    }

    private func sortedHistory(_ days: [DayCount]) -> [DayCount] {
        days.sorted { $0.date > $1.date }
    }

    private func syncFromStats() {
        todayCount = stats.todayCount
        history = sortedHistory(stats.days)
    }

    private func schedulePersist() {
        persistTask?.cancel()
        persistTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            persistNow()
        }
    }

    private func persistNow() {
        persistTask?.cancel()
        persistTask = nil
        stats.todayCount = todayCount
        stats.todayDate = DayKey.string()
        stats.days = sortedHistory(stats.days)
        store.save(stats)
    }

    private func startObservers() {
        dayChangeObserver = NotificationCenter.default.addObserver(
            forName: .NSCalendarDayChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.applyDayBoundaryIfNeeded(persist: true)
            }
        }

        becomeActiveObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.applyDayBoundaryIfNeeded(persist: true)
                self.refreshPermissionAndMonitor()
            }
        }
    }

    deinit {
        if let dayChangeObserver {
            NotificationCenter.default.removeObserver(dayChangeObserver)
        }
        if let becomeActiveObserver {
            NotificationCenter.default.removeObserver(becomeActiveObserver)
        }
    }
}
