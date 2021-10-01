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

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    private let writeScheduler = CurrentValueSubject<Date,Never>(.init())
    private var writePipeline: AnyCancellable? = nil

    private var wrapper: FileWrapper? = nil

    /// Organizes local JSON file persistence. Uses the FileWrapper API for
    /// sparing disk writes and debounces frequent requests.
    ///
    /// - Parameters:
    ///   - mode: Lazy / greedy library loading mode
    ///   - location: Save location to use for writes
    ///   - logger: Logging service
    ///   - queue: Serial queue
    public init(
        mode: EntryLoadingMode,
        location: JournalLibraryLocation,
        logger: Logging,
        queue: DispatchQueue = .init(label: "\(appIdentifier).localPersistence", qos: .background)
    ) {
        self.queue = queue
        self.mode = mode
        self.logger = logger
        self.location = location
        setupDebouncedWritePipeline()
    }

    /// Allows injecting a wrapper spy for testing.
    /// - Parameters:
    ///   - wrapper: Override the save container by providing an initialized wrapper
    internal convenience init(mode: EntryLoadingMode,
                location: JournalLibraryLocation,
                logger: Logging,
                queue: DispatchQueue = .init(label: "\(appIdentifier).localPersistence", qos: .background),
                wrapper: FileWrapper? = nil
    ) {
        self.init(mode: mode, location: location, logger: logger)
        self.wrapper = wrapper
    }
}

// MARK: - API

extension LocalPersistenceManager: Persisting {

    public func loadJournalLibrary() -> AnyPublisher<JournalLibraryLoadable, Error> {
        Deferred { Future { [weak self] promise in
            self?.queue.async { [weak self] in
                guard let self = self else { return }
                do {
                    switch self.mode {
                        case .writeOnlyMode:
                            try self.getFileWrapperForUserData()
                            promise(.success(JournalLibraryLoadable(entries: [])))

                        case .immediatelyLoadUserEntryLibrary:
                            let library = try self.loadLibraryFromDisk()
                            promise(.success(library))
                    }
                } catch { promise(.failure(error)) }
            }}
        }.eraseToAnyPublisher()
    }

    public func save(entries: [JJEntry]) {
        guard !entries.isEmpty else { return }
        queue.async { [self] in
            do {
                guard let wrapper = wrapper
                else { throw LocalPersistenceError.persistenceServiceUnavailable }

                for entry in entries {
                    try saveToFileWrapper(wrapper, entry: entry)
                }
                self.logger?.log(event: "Persistence scheduled to save \(entries.endIndex) entries")
                writeScheduler.send(.init())
            } catch {
                self.logger?.log(error: error)
            }
        }
    }

    public func appWillTerminate() -> Result<Void, Error> {
        queue.sync {
            do {
                try writeFileWrapperToDisk()
                self.logger?.log(event: "Persistence finished saving files.")
                return .success(())
            } catch {
                return .failure(error)
            }
        }
    }
}

// MARK: - Methods for Loading

private extension LocalPersistenceManager {

    @discardableResult
    func getFileWrapperForUserData() throws -> FileWrapper {
        if let existingWrapper = self.wrapper { return existingWrapper }
        let url = try location.getAppUserDataFolder()
        let wrapper = try FileWrapper(url: url, options: .withoutMapping)
        self.wrapper = wrapper
        return wrapper
    }

    func loadLibraryFromDisk() throws -> JournalLibraryLoadable {
        let wrapper = try getFileWrapperForUserData()
        guard let userFiles = wrapper.fileWrappers
        else { throw LocalPersistenceError.directoryContentsReadError }

        let entries = userFiles.reduce(into: [JJEntry](), parseRegularFileWrapper)
        return .init(entries: entries)
    }

    func parseRegularFileWrapper(_ results: inout [JJEntry], _ wrapper: Dictionary<String, FileWrapper>.Element) {
        do {
            guard let data = wrapper.value.regularFileContents
            else { logger?.log(error: LocalPersistenceError.unexpectedItemInUserDirectory(wrapper.key)); return }

            let entry = try EntrySaveContainer(fileData: data, decoder).parse(using: decoder)
            results.append(entry)
        } catch {
            logger?.log(error: LocalPersistenceError.unableToParse(file: wrapper.key, error: error))
        }
    }
}

// MARK: - Methods for Saving

private extension LocalPersistenceManager {

    func setupDebouncedWritePipeline() {
        writePipeline = writeScheduler
            .dropFirst()
            .throttle(for: 1, scheduler: DispatchQueue.global(), latest: true)
            .sink { [weak self] _ in
                do {
                    try self?.writeFileWrapperToDisk()
                } catch {
                    self?.logger?.log(error: error)
                }
            }
    }

    func writeFileWrapperToDisk() throws {
        guard let url = try? location.getAppUserDataFolder() else { return }
        guard wrapper?.matchesContents(of: url) == false else { return }
        try wrapper?.write(to: url, options: .withNameUpdating, originalContentsURL: url)
    }

    func saveToFileWrapper(_ wrapper: FileWrapper, entry: JJEntry) throws {
        let expectedFilename = convertModelIDToFileName(entry.id)

        // Invalidate if existing
        if let child = wrapper.fileWrappers?[expectedFilename] {
            wrapper.removeFileWrapper(child)
        }

        // Add back
        let data = try EntrySaveContainer.encode(entry: entry, with: encoder)
        let saveFileName = wrapper.addRegularFile(withContents: data, preferredFilename: expectedFilename)

        if saveFileName != expectedFilename {
            handleUnexpectedFilenameCollision(
                wrapper: wrapper,
                entryID: entry.id,
                saveFileName: saveFileName,
                data: data
            )
        }
    }

    func handleUnexpectedFilenameCollision(wrapper: FileWrapper,
                                           entryID: JJEntry.ID,
                                           saveFileName: String,
                                           data: Data) {

        if let child = wrapper.fileWrappers?[saveFileName] {
            wrapper.removeFileWrapper(child)
        }

        let newID = JJEntry.ID()
        let newKey = convertModelIDToFileName(newID)
        let newKeyUsed = wrapper.addRegularFile(withContents: data, preferredFilename: newKey)

        guard newKeyUsed == newKey else {
            // Two UUID conflicts?
            logger?.log(error: LocalPersistenceError.namingCollision(newKey))
            return
        }

        errorHandlingDelegate?.entryIDsDidChangeFromConflict([
            .init(oldID: entryID, newID: newID)
        ])
    }

    func convertModelIDToFileName(_ id: JJEntry.ID) -> String {
        id.uuidString
    }
}
