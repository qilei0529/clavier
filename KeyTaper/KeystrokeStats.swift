//
//  KeystrokeStats.swift
//  KeyTaper
//

import Foundation

enum HourlyCounts {
    static let hourCount = 24
    static let empty: [Int] = Array(repeating: 0, count: hourCount)

    /// Pad or truncate to exactly 24 entries.
    static func normalized(_ values: [Int]?) -> [Int] {
        guard let values else { return empty }
        if values.count == hourCount { return values }
        if values.count > hourCount { return Array(values.prefix(hourCount)) }
        return values + Array(repeating: 0, count: hourCount - values.count)
    }
}

struct DayCount: Identifiable, Equatable, Hashable {
    var date: String
    var count: Int
    /// Physical keyCode → press count for this day. Keys stored as decimal strings for JSON.
    var keyCounts: [String: Int]
    /// Keystroke totals per hour (index 0–23, local calendar).
    var hourlyCounts: [Int]
    var leftClicks: Int
    var rightClicks: Int

    var id: String { date }

    init(
        date: String,
        count: Int,
        keyCounts: [String: Int] = [:],
        hourlyCounts: [Int] = HourlyCounts.empty,
        leftClicks: Int = 0,
        rightClicks: Int = 0
    ) {
        self.date = date
        self.count = count
        self.keyCounts = keyCounts
        self.hourlyCounts = HourlyCounts.normalized(hourlyCounts)
        self.leftClicks = leftClicks
        self.rightClicks = rightClicks
    }
}

extension DayCount: Codable {
    private enum CodingKeys: String, CodingKey {
        case date
        case count
        case keyCounts
        case hourlyCounts
        case leftClicks
        case rightClicks
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        date = try container.decode(String.self, forKey: .date)
        count = try container.decode(Int.self, forKey: .count)
        keyCounts = try container.decodeIfPresent([String: Int].self, forKey: .keyCounts) ?? [:]
        hourlyCounts = HourlyCounts.normalized(
            try container.decodeIfPresent([Int].self, forKey: .hourlyCounts)
        )
        leftClicks = try container.decodeIfPresent(Int.self, forKey: .leftClicks) ?? 0
        rightClicks = try container.decodeIfPresent(Int.self, forKey: .rightClicks) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(date, forKey: .date)
        try container.encode(count, forKey: .count)
        try container.encode(keyCounts, forKey: .keyCounts)
        try container.encode(HourlyCounts.normalized(hourlyCounts), forKey: .hourlyCounts)
        try container.encode(leftClicks, forKey: .leftClicks)
        try container.encode(rightClicks, forKey: .rightClicks)
    }
}

struct KeystrokeStats: Equatable {
    var todayDate: String
    var todayCount: Int
    /// Today's per-key tallies (parallel to `todayCount`; folded into `days` at midnight).
    var todayKeyCounts: [String: Int]
    /// Today's per-hour tallies (parallel to `todayCount`).
    var todayHourlyCounts: [Int]
    var todayLeftClicks: Int
    var todayRightClicks: Int
    var days: [DayCount]
    /// Physical keyCode → lifetime press count. Keys stored as decimal strings for JSON.
    var keyCounts: [String: Int]
    var leftClicks: Int
    var rightClicks: Int

    static let empty = KeystrokeStats(
        todayDate: DayKey.string(),
        todayCount: 0,
        todayKeyCounts: [:],
        todayHourlyCounts: HourlyCounts.empty,
        todayLeftClicks: 0,
        todayRightClicks: 0,
        days: [],
        keyCounts: [:],
        leftClicks: 0,
        rightClicks: 0
    )
}

extension KeystrokeStats: Codable {
    private enum CodingKeys: String, CodingKey {
        case todayDate
        case todayCount
        case todayKeyCounts
        case todayHourlyCounts
        case todayLeftClicks
        case todayRightClicks
        case days
        case keyCounts
        case leftClicks
        case rightClicks
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        todayDate = try container.decode(String.self, forKey: .todayDate)
        todayCount = try container.decode(Int.self, forKey: .todayCount)
        todayKeyCounts = try container.decodeIfPresent([String: Int].self, forKey: .todayKeyCounts) ?? [:]
        todayHourlyCounts = HourlyCounts.normalized(
            try container.decodeIfPresent([Int].self, forKey: .todayHourlyCounts)
        )
        todayLeftClicks = try container.decodeIfPresent(Int.self, forKey: .todayLeftClicks) ?? 0
        todayRightClicks = try container.decodeIfPresent(Int.self, forKey: .todayRightClicks) ?? 0
        days = try container.decode([DayCount].self, forKey: .days)
        keyCounts = try container.decodeIfPresent([String: Int].self, forKey: .keyCounts) ?? [:]
        leftClicks = try container.decodeIfPresent(Int.self, forKey: .leftClicks) ?? 0
        rightClicks = try container.decodeIfPresent(Int.self, forKey: .rightClicks) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(todayDate, forKey: .todayDate)
        try container.encode(todayCount, forKey: .todayCount)
        try container.encode(todayKeyCounts, forKey: .todayKeyCounts)
        try container.encode(HourlyCounts.normalized(todayHourlyCounts), forKey: .todayHourlyCounts)
        try container.encode(todayLeftClicks, forKey: .todayLeftClicks)
        try container.encode(todayRightClicks, forKey: .todayRightClicks)
        try container.encode(days, forKey: .days)
        try container.encode(keyCounts, forKey: .keyCounts)
        try container.encode(leftClicks, forKey: .leftClicks)
        try container.encode(rightClicks, forKey: .rightClicks)
    }
}
