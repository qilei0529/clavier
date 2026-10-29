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

struct KeystrokeStats: Codable, Equatable {
    var todayDate: String
    var todayCount: Int
    var days: [DayCount]

    static let empty = KeystrokeStats(
        todayDate: DayKey.string(),
        todayCount: 0,
        days: []
    )
}
