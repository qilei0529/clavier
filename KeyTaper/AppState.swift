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
    private(set) var todayCount: Int = 0
    private(set) var history: [DayCount] = []
    private(set) var hasAccessibilityPermission: Bool = false

    private let store: StatsStore
    private var stats: KeystrokeStats
    private var monitor: KeystrokeMonitor?
    private var persistTask: Task<Void, Never>?
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

    init(store: StatsStore = StatsStore()) {
        self.store = store
        self.stats = store.load()
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
            monitor = KeystrokeMonitor { [weak self] in
                Task { @MainActor in
                    self?.handleKeyDown()
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

    private func handleKeyDown() {
        applyDayBoundaryIfNeeded(persist: true)
        guard hasAccessibilityPermission else { return }

        todayCount += 1
        stats.todayCount = todayCount
        schedulePersist()
    }

    private func applyDayBoundaryIfNeeded(persist: Bool) {
        let today = DayKey.string()
        guard stats.todayDate != today else { return }

        if stats.todayCount > 0 {
            upsertHistory(date: stats.todayDate, count: stats.todayCount)
        }

        stats.todayDate = today
        stats.todayCount = 0
        todayCount = 0
        history = sortedHistory(stats.days)

        if persist {
            persistNow()
        }
    }

    private func upsertHistory(date: String, count: Int) {
        guard !date.isEmpty else { return }

        if let index = stats.days.firstIndex(where: { $0.date == date }) {
            stats.days[index].count = count
        } else {
            stats.days.append(DayCount(date: date, count: count))
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
