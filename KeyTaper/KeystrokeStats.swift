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

    var id: String { date }

    init(
        date: String,
        count: Int,
        keyCounts: [String: Int] = [:],
        hourlyCounts: [Int] = HourlyCounts.empty
    ) {
        self.date = date
        self.count = count
        self.keyCounts = keyCounts
        self.hourlyCounts = HourlyCounts.normalized(hourlyCounts)
    }
}

extension DayCount: Codable {
    private enum CodingKeys: String, CodingKey {
        case date
        case count
        case keyCounts
        case hourlyCounts
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        date = try container.decode(String.self, forKey: .date)
        count = try container.decode(Int.self, forKey: .count)
        keyCounts = try container.decodeIfPresent([String: Int].self, forKey: .keyCounts) ?? [:]
        hourlyCounts = HourlyCounts.normalized(
            try container.decodeIfPresent([Int].self, forKey: .hourlyCounts)
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(date, forKey: .date)
        try container.encode(count, forKey: .count)
        try container.encode(keyCounts, forKey: .keyCounts)
        try container.encode(HourlyCounts.normalized(hourlyCounts), forKey: .hourlyCounts)
    }
}

struct KeystrokeStats: Equatable {
    var todayDate: String
    var todayCount: Int
    /// Today's per-key tallies (parallel to `todayCount`; folded into `days` at midnight).
    var todayKeyCounts: [String: Int]
    /// Today's per-hour tallies (parallel to `todayCount`).
    var todayHourlyCounts: [Int]
    var days: [DayCount]
    /// Physical keyCode → lifetime press count. Keys stored as decimal strings for JSON.
    var keyCounts: [String: Int]

    static let empty = KeystrokeStats(
        todayDate: DayKey.string(),
        todayCount: 0,
        todayKeyCounts: [:],
        todayHourlyCounts: HourlyCounts.empty,
        days: [],
        keyCounts: [:]
    )
}

extension KeystrokeStats: Codable {
    private enum CodingKeys: String, CodingKey {
        case todayDate
        case todayCount
        case todayKeyCounts
        case todayHourlyCounts
        case days
        case keyCounts
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        todayDate = try container.decode(String.self, forKey: .todayDate)
        todayCount = try container.decode(Int.self, forKey: .todayCount)
        todayKeyCounts = try container.decodeIfPresent([String: Int].self, forKey: .todayKeyCounts) ?? [:]
        todayHourlyCounts = HourlyCounts.normalized(
            try container.decodeIfPresent([Int].self, forKey: .todayHourlyCounts)
        )
        days = try container.decode([DayCount].self, forKey: .days)
        keyCounts = try container.decodeIfPresent([String: Int].self, forKey: .keyCounts) ?? [:]
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(todayDate, forKey: .todayDate)
        try container.encode(todayCount, forKey: .todayCount)
        try container.encode(todayKeyCounts, forKey: .todayKeyCounts)
        try container.encode(HourlyCounts.normalized(todayHourlyCounts), forKey: .todayHourlyCounts)
        try container.encode(days, forKey: .days)
        try container.encode(keyCounts, forKey: .keyCounts)
    }
}
