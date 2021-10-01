//  © 2021 Ryan Ferrell. github.com/importRyan

import XCTest
@testable import JournalingPersistence
@testable import Journaling
import Combine

class LocalPersistenceManagerBehavioralTests: XCTestCase {

    // MARK: - Init

    func test_Initialization_PerformsNoActions() throws {
        let (logger, _, diskSpy) = try setupUtilities()

        let _ = LocalPersistenceManager(
            mode: .writeOnlyMode,
            location: .desktop,
            logger: logger,
            wrapper: diskSpy
        )

        AssertNoActivity(spy: diskSpy, logger: logger)
    }

    // MARK: - Load Library

    func test_Loading_WriteOnlyMode_ReturnsEmptyLibrary_AndPerformsNoWritesOrLogs() throws {
        let (logger, _, diskSpy) = try setupUtilities()

        let sut_mode = EntryLoadingMode.writeOnlyMode
        let sut = LocalPersistenceManager(
            mode: sut_mode,
            location: .desktop,
            logger: logger,
            wrapper: diskSpy
        )

        // Act
        let loadable = performLoadLibraryWithTimeout(sut)

        XCTAssertNotNil(loadable)
        XCTAssertEqual(JournalLibraryLoadable(), loadable)
        AssertNoActivity(spy: diskSpy, logger: logger)
    }

    func test_Loading_ImmediateMode_ReturnsEmptyLibraryWhenDiskEmpty_AndPerformsNoWritesOrLogs() throws {
        let (logger, _, diskSpy) = try setupUtilities()

        let sut_mode = EntryLoadingMode.immediatelyLoadUserEntryLibrary
        let sut = LocalPersistenceManager(
            mode: sut_mode,
            location: .desktop,
            logger: logger,
            wrapper: diskSpy
        )

        // Act
        let loadable = performLoadLibraryWithTimeout(sut)

        XCTAssertNotNil(loadable)
        XCTAssertEqual(JournalLibraryLoadable(), loadable)
        AssertNoActivity(spy: diskSpy, logger: logger)
    }

    func test_Loading_ImmediateMode_LibraryContents_AndPerformsNoWritesOrLogs() throws {
        let mockLibrary = TestCases.mockLibraryEntries
        let fileWrappers = TestCases.makeRegularFileWrappers(from: mockLibrary)
        let (logger, _, diskSpy) = try setupUtilities(childWrappers: fileWrappers)

        let sut_mode = EntryLoadingMode.immediatelyLoadUserEntryLibrary
        let sut = LocalPersistenceManager(
            mode: sut_mode,
            location: .desktop,
            logger: logger,
            wrapper: diskSpy
        )

        // Act
        let loadable = performLoadLibraryWithTimeout(sut)

        let loadedEntries = try Set(XCTUnwrap(loadable?.entries))
        XCTAssertEqual(Set(mockLibrary), loadedEntries)
        AssertNoActivity(spy: diskSpy, logger: logger)
    }

    // MARK: - Save Entries

    func test_Save_NoEntries_DoesNotPerformWrite() throws {
        let (logger, _, diskSpy) = try setupUtilities()

        let sut = LocalPersistenceManager(
            mode: .immediatelyLoadUserEntryLibrary,
            location: .desktop,
            logger: logger,
            wrapper: diskSpy
        )

        // Act
        performSaveEntries(actions: [], timeOut: 1, waitRegardlessOfWrites: true, writeCountsExpected: nil, sut, diskSpy)

        AssertNoActivity(spy: diskSpy, logger: logger)
    }

    func test_Save_WritesValidJSON_Once() throws {
        let mockLibrary = TestCases.mockLibraryEntries
        let (logger, _, diskSpy) = try setupUtilities()

        let sut = LocalPersistenceManager(
            mode: .immediatelyLoadUserEntryLibrary,
            location: .desktop,
            logger: logger,
            wrapper: diskSpy
        )

        // Act
        performSaveEntries(actions: [mockLibrary], timeOut: 3, waitRegardlessOfWrites: true, writeCountsExpected: 1, sut, diskSpy)

        XCTAssertEqual([], logger.sessionErrors)
        XCTAssertEqual(1, logger.sessionEvents.count)
        XCTAssertTrue(logger.sessionEvents.contains { $0.message == "Persistence scheduled to save 3 entries" })
        XCTAssertEqual(diskSpy.countDiskWritesPerformed, 1)
        XCTAssertEqual(diskSpy.countMutationsToWrappers, 3)
        XCTAssertEqual(diskSpy.countContentsMatches, 1)

        let expectedEntryJSONs: [String:String] = [
            "F3B80477-BC1B-43A2-BFAA-50A4AFD40698" : """
{"id":"F3B80477-BC1B-43A2-BFAA-50A4AFD40698","title":"Imagine all the people","content":"Sharing all the world","dateCreated":-972084978,"dateEdited":-976196089}
""",
            "8D47DEBB-F328-45CB-B4B5-678BB52D5C2F" : """
{"id":"8D47DEBB-F328-45CB-B4B5-678BB52D5C2F","title":"No need for greed or hunger","content":"A brotherhood of man","dateCreated":-973084978,"dateEdited":-977196089}
""",
            "24BDBC0A-FA98-497C-A15F-81099A782C11" : """
{"id":"24BDBC0A-FA98-497C-A15F-81099A782C11","title":"Imagine no possessions","content":"I wonder if you can","dateCreated":-974084978,"dateEdited":-978307200}
""",
        ]

        let decoder = JSONDecoder()
        try diskSpy.addedFiles.forEach { file in

            let container = try decoder.decode(EntrySaveContainer.self, from: file.data)
            let entryJSON = try XCTUnwrap(String(data: container.data, encoding: .utf8))
            let expectedEntryJSON = try XCTUnwrap(expectedEntryJSONs[file.collisionRevisedName])
            XCTAssertEqual(entryJSON, expectedEntryJSON)
            XCTAssertEqual(container.versionSentinel, 1)
        }
    }

    func test_Save_CoalescesConcurrentWriteRequestsIntoTwoWrites() throws {
        let mockLibrary = TestCases.mockLibraryEntries
        let oneDifference = TestCases.mockLibraryEntriesWithOneVariant
        let repeatedUserInput = [mockLibrary, mockLibrary, oneDifference, mockLibrary, mockLibrary]
        let (logger, _, diskSpy) = try setupUtilities()

        let sut = LocalPersistenceManager(
            mode: .immediatelyLoadUserEntryLibrary,
            location: .desktop,
            logger: logger,
            wrapper: diskSpy
        )

        // Act
        performSaveEntries(actions: repeatedUserInput, withSpacing: 0, timeOut: 3, waitRegardlessOfWrites: true, writeCountsExpected: 2, sut, diskSpy)

        XCTAssertEqual([], logger.sessionErrors)
        XCTAssertEqual(5, logger.sessionEvents.count)
        XCTAssertEqual(5, logger.sessionEvents.filter { $0.message == "Persistence scheduled to save 3 entries" }.count)
        XCTAssertEqual(diskSpy.countDiskWritesPerformed, 2)
        XCTAssertEqual(diskSpy.countMutationsToWrappers, 26)
        XCTAssertEqual(diskSpy.countContentsMatches, 2)
    }

    // MARK: - Termination

    func test_Termination_DoesNotCausesWrite_WhenNotRequired() throws {
        let mockLibrary = TestCases.mockLibraryEntries
        let oneDifference = TestCases.mockLibraryEntriesWithOneVariant
        let repeatedUserInput = [mockLibrary, mockLibrary, oneDifference, mockLibrary, mockLibrary]
        let (logger, _, diskSpy) = try setupUtilities()

        let expectedLogMessages = ["Persistence scheduled to save 3 entries", "Persistence scheduled to save 3 entries", "Persistence scheduled to save 3 entries", "Persistence scheduled to save 3 entries", "Persistence scheduled to save 3 entries", "Persistence finished saving files."]

        let sut = LocalPersistenceManager(
            mode: .immediatelyLoadUserEntryLibrary,
            location: .desktop,
            logger: logger,
            wrapper: diskSpy
        )

        // Act
        performSaveEntries(actions: repeatedUserInput, withSpacing: 0, timeOut: 3, waitRegardlessOfWrites: false, writeCountsExpected: 2, sut, diskSpy)
        let error = performRemainingTasksBeforeTerminationWithTimeout(of: 1, sut)

        XCTAssertNil(error, "\(error?.localizedDescription ?? "Unknown error")")
        XCTAssertEqual(logger.sessionErrors, [])
        XCTAssertEqual(logger.sessionEvents.count, 6)
        XCTAssertEqual(logger.sessionEvents.map(\.message), expectedLogMessages)
        XCTAssertEqual(diskSpy.countDiskWritesPerformed, 2)
        XCTAssertEqual(diskSpy.countMutationsToWrappers, 26)
        XCTAssertEqual(diskSpy.countContentsMatches, 2)
    }

    func test_Termination_CausesWrite_WhenRequired() throws {
        let (logger, _, diskSpy) = try setupUtilities()
        diskSpy.replaceFileWrappers(with: TestCases.makeRegularFileWrappers(from: TestCases.mockLibraryEntries))
        let expectedLogMessages = ["Persistence finished saving files."]

        let sut = LocalPersistenceManager(
            mode: .immediatelyLoadUserEntryLibrary,
            location: .desktop,
            logger: logger,
            wrapper: diskSpy
        )

        // Act
        let error = performRemainingTasksBeforeTerminationWithTimeout(of: 1, sut)

        XCTAssertNil(error, "\(error?.localizedDescription ?? "Unknown error")")
        XCTAssertEqual(logger.sessionErrors, [])
        XCTAssertEqual(logger.sessionEvents.count, 1)
        XCTAssertEqual(logger.sessionEvents.map(\.message), expectedLogMessages)
        XCTAssertEqual(diskSpy.countDiskWritesPerformed, 1)
        XCTAssertEqual(diskSpy.countMutationsToWrappers, 0)
        XCTAssertEqual(diskSpy.countContentsMatches, 1)
    }

}

fileprivate extension XCTestCase {

    func performRemainingTasksBeforeTerminationWithTimeout(of seconds: TimeInterval, _ sut: Persisting) -> Error? {
        let completesTask = XCTestExpectation(description: "Completes termination task")
        var awaitedError: Error? = nil
        switch sut.appWillTerminate() {
            case .failure(let error):
                awaitedError = error
                fallthrough
            case .success:
                completesTask.fulfill()

        }
        wait(for: [completesTask], timeout: seconds)
        return awaitedError
    }

    func performSaveEntries(actions: [[JJEntry]],
                            withSpacing: TimeInterval = 0,
                            timeOut: TimeInterval = 3,
                            waitRegardlessOfWrites: Bool = true,
                            writeCountsExpected: Int? = nil,
                            _ sut: Persisting,
                            _ spy: FileWrapperSpy) {

        let countDescription = writeCountsExpected == nil ? "" : "\(writeCountsExpected!) times"
        var expectations = [XCTestExpectation(description: "Wrote to disk \(countDescription)")]
        if let count = writeCountsExpected {
            expectations[0].expectedFulfillmentCount = count
        }
        if waitRegardlessOfWrites {
            let ensureWait = XCTestExpectation(description: "Wait regardless")
            ensureWait.isInverted = true
            expectations.append(ensureWait)
        }

        // Watch for writes
        var tasks = Set<AnyCancellable>()
        spy.didWrite.sink { _ in
            expectations[0].fulfill()
        }.store(in: &tasks)

        // Perform SUT action(s)
        for action in actions {
            DispatchQueue.main.asyncAfter(deadline: .now() + withSpacing) {
                sut.save(entries: action)
            }
        }
        wait(for: expectations, timeout: timeOut)
    }

    func performLoadLibraryWithTimeout(of seconds: TimeInterval = 0.5, _ sut: Persisting) -> JournalLibraryLoadable? {

        let expLoadsLibrary = XCTestExpectation(description: "Loads library")
        var tasks = Set<AnyCancellable>()
        var loadable: JournalLibraryLoadable? = nil
        sut.loadJournalLibrary().sink { completion in
            switch completion {
                case .failure(let error):
                    XCTAssertEqual("", error.localizedDescription)
                    fallthrough
                case .finished: expLoadsLibrary.fulfill()
            }
        } receiveValue: { result in
            loadable = result
        }.store(in: &tasks)
        wait(for: [expLoadsLibrary], timeout: seconds)
        return loadable
    }

    func AssertNoActivity(spy: FileWrapperSpy, logger: Logging, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(logger.sessionErrors, [], file: file, line: line)
        XCTAssertEqual(logger.sessionEvents, [], file: file, line: line)
        XCTAssertEqual(spy.countDiskWritesPerformed, 0, file: file, line: line)
        XCTAssertEqual(spy.countMutationsToWrappers, 0, file: file, line: line)
        XCTAssertEqual(spy.countContentsMatches, 0, file: file, line: line)
    }

    func setupUtilities(
        location: JournalLibraryLocation = .desktop,
        childWrappers: [String:FileWrapper] = [:],
        allowSystemWrites: Bool = false,
        useProvidedWrappersOnly: Bool = true
    ) throws -> (logger: SystemLogger, url: URL, diskSpy: FileWrapperSpy)  {

        let logger = SystemLogger(label: "testing")
        let url = try JournalLibraryLocation.desktop.getAppUserDataFolder()
        let diskSpy = FileWrapperSpy(directory: url,
                                     childWrappers: childWrappers,
                                     allowSystemWrites: allowSystemWrites,
                                     useProvidedWrappersOnly: useProvidedWrappersOnly)
        return (logger, url, diskSpy)
    }
}

enum TestCases {

    static let ids: [UUID] = [
        "24BDBC0A-FA98-497C-A15F-81099A782C11",
        "8D47DEBB-F328-45CB-B4B5-678BB52D5C2F",
        "F3B80477-BC1B-43A2-BFAA-50A4AFD40698",
        "33CE0404-31C3-4D8E-AC03-41709A6F39A4"
    ].compactMap(UUID.init(uuidString:))

    static let datesA: [Date] = [
        Date(timeIntervalSince1970: 0),
        Date(timeIntervalSince1970: 1_111_111),
        Date(timeIntervalSince1970: 2_111_111),
        Date(timeIntervalSince1970: 3_111_111),
    ]

    static let datesB: [Date] = [
        Date(timeIntervalSince1970: 4_222_222),
        Date(timeIntervalSince1970: 5_222_222),
        Date(timeIntervalSince1970: 6_222_222),
        Date(timeIntervalSince1970: 7_222_222),
    ]

    static let mockLibraryEntries: [JJEntry] = [
        .init(id: ids[0],
              title: "Imagine no possessions",
              content: "I wonder if you can",
              edited: datesA[0],
              created: datesB[0]
             ),
        .init(id: ids[1],
              title: "No need for greed or hunger",
              content: "A brotherhood of man",
              edited: datesA[1],
              created: datesB[1]
             ),
        .init(id: ids[2],
              title: "Imagine all the people",
              content: "Sharing all the world",
              edited: datesA[2],
              created: datesB[2]
             )
    ]

    static let mockLibraryEntriesWithOneVariant: [JJEntry] = [
        .init(id: ids[3],
              title: "Possessions are imaginary",
              content: "If I wonder you can",
              edited: datesA[3],
              created: datesB[3]
             ),
        .init(id: ids[1],
              title: "No need for greed or hunger",
              content: "A brotherhood of man",
              edited: datesA[1],
              created: datesB[1]
             ),
        .init(id: ids[2],
              title: "Imagine all the people",
              content: "Sharing all the world",
              edited: datesA[2],
              created: datesB[2]
             )
    ]

    static func makeRegularFileWrappers(from entries: [JJEntry]) -> [String:FileWrapper] {
        let encoder = JSONEncoder()
        let keyValues = zip(entries.map { $0.id.uuidString }, entries).map { ($0, $1)}
        let entryDict = Dictionary(keyValues) { lhs, _ in lhs }
        return entryDict.mapValues { entry in
            try! FileWrapper(regularFileWithContents: EntrySaveContainer.encode(entry: entry, with: encoder))
        }
    }
}
