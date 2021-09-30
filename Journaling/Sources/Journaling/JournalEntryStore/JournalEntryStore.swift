//  © 2021 Ryan Ferrell. github.com/importRyan


import Foundation
import Combine

public protocol JournalEntryStore: AnyObject, EntriesProviding, EntriesEditing {
    func start() -> AnyPublisher<Void,Error>
}

// MARK: - Component Functions

public protocol EntriesProviding {
    func listEntries() -> [JJEntry]
    func getEntry(id: JJEntry.ID) -> JJEntry?
}

public protocol EntriesEditing {
    func addEntry(title: String, content: String)
}
