//  © 2021 Ryan Ferrell. github.com/importRyan


import Foundation

public protocol JJFormatting {
    var current: JJEntryFormatting { get }
}

// MARK: - Entries

public protocol JJEntryFormatting {
    var id: JJEntryIDFormatting { get set }
    var date: JJDateFormatting { get set }
    var title: JJTitleFormatting { get set }
}

public protocol JJEntryIDFormatting {
    func format(_ id: JJEntry.ID) -> String
}

public protocol JJTitleFormatting {
    func format(_ title: String) -> String
}

public protocol JJDateFormatting {
    func format(_ date: Date) -> String
}
