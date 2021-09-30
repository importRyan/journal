//  © 2021 Ryan Ferrell. github.com/importRyan

import Foundation
import Combine

public protocol Persisting: AnyObject {

    /// Responds to ID collisions after a file save
    var errorHandlingDelegate: PersistingErrorHandlingDelegate? { get set }

    /// Returns on a background queue.
    func loadJournalLibrary() -> AnyPublisher<JournalLibraryLoadable,Error>

    /// Saves one or more entries asynchronously.
    func save(entries: [JJEntry])

    func performRemainingTasksBeforeTermination(tasksDidComplete: @escaping (Error?) -> Void)
}

public protocol PersistingErrorHandlingDelegate: AnyObject {

    /// In the case of an ID collision, use these new uniqued identifiers.
    func entryIDsDidChangeFromConflict(_ changes: [JJEntryIDChangeInfo])
}

/// Contents of the app's persistent store
public struct JournalLibraryLoadable {
    public let entries: [JJEntry]
}

/// Communicates ID collections when saving
public struct JJEntryIDChangeInfo {
    public let oldID: JJEntry.ID
    public let newID: JJEntry.ID

    public init(oldID: JJEntry.ID, newID: JJEntry.ID) {
        self.oldID = oldID
        self.newID = newID
    }
}
