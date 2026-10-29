//
//  KeystrokeStats.swift
//  KeyTaper
//

import Foundation

struct DayCount: Codable, Identifiable, Equatable, Hashable {
    var date: String
    var count: Int

    var id: String { date }
}

struct KeystrokeStats: Equatable {
    var todayDate: String
    var todayCount: Int
    var days: [DayCount]
    /// Physical keyCode → lifetime press count. Keys stored as decimal strings for JSON.
    var keyCounts: [String: Int]

    static let empty = KeystrokeStats(
        todayDate: DayKey.string(),
        todayCount: 0,
        days: [],
        keyCounts: [:]
    )
}

extension KeystrokeStats: Codable {
    private enum CodingKeys: String, CodingKey {
        case todayDate
        case todayCount
        case days
        case keyCounts
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        todayDate = try container.decode(String.self, forKey: .todayDate)
        todayCount = try container.decode(Int.self, forKey: .todayCount)
        days = try container.decode([DayCount].self, forKey: .days)
        keyCounts = try container.decodeIfPresent([String: Int].self, forKey: .keyCounts) ?? [:]
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(todayDate, forKey: .todayDate)
        try container.encode(todayCount, forKey: .todayCount)
        try container.encode(days, forKey: .days)
        try container.encode(keyCounts, forKey: .keyCounts)
    }
}
