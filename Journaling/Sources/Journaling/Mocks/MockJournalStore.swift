//  © 2021 Ryan Ferrell. github.com/importRyan


import Foundation
import Combine

public class MockJournalStore: JournalEntryStore {

    private var entries: [JJEntry.ID:JJEntry] = [:]

    private weak var persistence: Persisting?
    private weak var logging: Logging?
    private let queue = DispatchQueue(label: "\(appIdentifier).mockStore",
                                      qos: .userInitiated,
                                      attributes: .concurrent)

    public init(persistence: Persisting, logger: Logging) {
        self.persistence = persistence
        self.logging = logger
    }
}

public extension MockJournalStore {
    /// Returns on unowned background thread.
    /// Coordinates initial loading of the user library.
    func start() -> AnyPublisher<Void, Error> {
        guard let persistence = persistence else {
            return Fail(error: LoadingError.persistenceServiceUnavailable)
                .eraseToAnyPublisher()
        }

        return persistence.loadJournalLibrary()
            .handleEvents(receiveOutput: { [weak self] loadable in
                DispatchQueue.main.async { [weak self] in
                    let pairs = zip(loadable.entries.map(\.id), loadable.entries)
                    self?.entries = Dictionary(pairs, uniquingKeysWith: { (first, _) in first })
                }
                self?.logging?.log(event: "JournalStore received \(loadable.entries.count) entries")
            })
            .map { _ in () }
            .eraseToAnyPublisher()
    }
}

// MARK: - CRUD

extension MockJournalStore: EntriesProviding {

    public func getEntry(id: JJEntry.ID) -> JJEntry? {
        var entry: JJEntry? = nil
        queue.sync {
            entry = self.entries[id]
        }
        return entry
    }

    public func listEntries() -> [JJEntry] {
        var entries: [JJEntry] = []
        defer { self.logging?.log(event: "JournalStore served entry list of \(entries.endIndex)") }
        queue.sync {
            entries = self.entries.map(\.value)
        }
        // Temporary convenience for order stability before Monday
        return entries.sorted { $0.dateEdited > $1.dateEdited }
    }
}

extension MockJournalStore: EntriesEditing {

    public func addEntry(title: String, content: String) {
        queue.async(flags: .barrier) {
            var newEntry = JJEntry(title: title, content: content)
            while self.entries[newEntry.id] != nil {
                newEntry.changeID(.init())
            }
            self.entries[newEntry.id] = newEntry
            self.persistence?.save(entries: [newEntry])
            self.logging?.log(event: "JournalStore saved entry \(title)")
        }
    }
}

// MARK: - Handle an unlikely UUID collision when saving files

extension MockJournalStore: PersistingErrorHandlingDelegate {

    public func entryIDsDidChangeFromConflict(_ changes: [JJEntryIDChangeInfo]) {
        for change in changes {
            guard var existing = entries[change.oldID] else {
                logging?.log(event: "JournalStore handled ID conflict")
                continue
            }
            existing.changeID(change.newID)
            entries.removeValue(forKey: change.oldID)
            entries[change.newID] = existing
        }
    }
}
