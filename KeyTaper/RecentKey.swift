//
//  RecentKey.swift
//  KeyTaper
//

import Foundation

struct RecentKey: Identifiable, Equatable, Hashable {
    let id: UUID
    let label: String

    init(label: String) {
        self.id = UUID()
        self.label = label
    }
}
