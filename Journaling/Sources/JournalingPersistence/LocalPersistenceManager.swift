//  © 2021 Ryan Ferrell. github.com/importRyan


import Foundation
import Journaling
import Combine

public class LocalPersistenceManager {

    public var errorHandlingDelegate: PersistingErrorHandlingDelegate?
    private weak var logger: Logging?
    private let queue: DispatchQueue
    private let mode: EntryLoadingMode
    private let location: JournalLibraryLocation

    public init(mode: EntryLoadingMode,
                location: JournalLibraryLocation,
                logger: Logging,
                queue: DispatchQueue = .init(label: "\(appIdentifier).localPersistence",
                                             qos: .background)) {
        self.queue = queue
        self.mode = mode
        self.logger = logger
        self.location = location
    }
}

extension LocalPersistenceManager: Persisting {

    public func loadJournalLibrary() -> AnyPublisher<JournalLibraryLoadable, Error> {
        switch mode {
            case .writeOnlyMode:
                return Deferred { Future { [weak self] promise in
                    self?.queue.async {
                        let loadable = JournalLibraryLoadable(entries: [])
                        promise(.success(loadable))
                    }
                }}.eraseToAnyPublisher()

            case .immediatelyLoadUserEntryLibrary:
                return Just(JournalLibraryLoadable(entries: []))
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
        }
    }

    public func save(entries: [JJEntry]) {
        queue.async { [self] in
            self.logger?.log(event: "Persistence saved \(entries.endIndex) entries")
        }
    }

    public func performRemainingTasksBeforeTermination(tasksDidComplete: @escaping (Error?) -> Void) {
        queue.async { [self] in
            self.logger?.log(event: "Persistence finished saving files.")
            tasksDidComplete(nil)
        }
    }
}
