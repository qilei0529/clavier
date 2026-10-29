//
//  StatsStore.swift
//  KeyTaper
//

import Foundation

struct StatsStore {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let support = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first!
            let directory = support.appendingPathComponent("KeyTaper", isDirectory: true)
            self.fileURL = directory.appendingPathComponent("stats.json")
        }

        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        decoder = JSONDecoder()
    }

    func load() -> KeystrokeStats {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return .empty
        }

        do {
            let data = try Data(contentsOf: fileURL)
            return try decoder.decode(KeystrokeStats.self, from: data)
        } catch {
            return .empty
        }
    }

    func save(_ stats: KeystrokeStats) {
        do {
            let directory = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
            let data = try encoder.encode(stats)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // Persistence failures should not crash the menu-bar utility.
        }
    }
}
