//  © 2021 Ryan Ferrell. github.com/importRyan


import Foundation
import Combine

public class ConcurrentJournalStore {

    private var entries: [JJEntry.ID:JJEntry] = [:]

    private weak var persistence: JJPersisting?
    private weak var logging: JJLogging?
    private let queue: DispatchQueue

    public init(persistence: JJPersisting, logger: JJLogging, queue: DispatchQueue? = nil) {
        self.persistence = persistence
        self.logging = logger
        self.queue = queue ?? DispatchQueue(
            label: "\(appIdentifier).journalstore",
            qos: .userInitiated,
            attributes: .concurrent
        )
    }
}

extension ConcurrentJournalStore: JJEntriesStore {

    /// Starts to load the user library. Returns on an unowned background queue.
    public func start() -> AnyPublisher<Void, Error> {
        guard let persistence = persistence else {
            return Fail(error: JJLoadingError.persistenceServiceUnavailable)
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

    /// Enqueues the app's closing tasks behind any user intents on the store's queue
    public func appWillTerminate() -> Result<Void, Error> {
        queue.sync {
            .success(())
        }
    }
}

// MARK: - CRUD

extension ConcurrentJournalStore: EntriesProviding {

    public func getEntry(id: JJEntry.ID) -> JJEntry? {
        var entry: JJEntry? = nil
        queue.sync {
            entry = self.entries[id]
        }
        return entry
    }

    public func listEntries() -> [JJEntry] {
        var entries: [JJEntry] = []
        queue.sync {
            entries = self.entries.map(\.value)
        }
        self.logging?.log(event: "JournalStore served entry list of \(entries.endIndex)")

        // Temporary convenience for order stability before Monday
        return entries.sorted { $0.dateEdited > $1.dateEdited }
    }
}

extension ConcurrentJournalStore: EntriesEditing {

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

extension ConcurrentJournalStore: PersistingErrorHandlingDelegate {

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
