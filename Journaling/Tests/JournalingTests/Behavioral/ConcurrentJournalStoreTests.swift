//  © 2021 Ryan Ferrell. github.com/importRyan

import Combine
import XCTest
@testable import Journaling

final class ConcurrentJournalStoreTests: XCTestCase {

    // MARK: - Initialization

    func test_Inits_EmptyLibraryWithoutRequestingSave() {
        let (sut, logger, persistence) = makeSUT(seedEntries: [])
        let expectedLoggedEvents = [
            "JournalStore received 0 entries",
            "JournalStore served entry list of 0"
        ]

        let error = performStart(sut)
        let result = sut.listEntries()

        XCTAssertNil(error)
        XCTAssertTrue(result.isEmpty)
        XCTAssertTrue(persistence.saveActions.isEmpty)
        XCTAssertEqual(logger.sessionErrors.map(\.message), [])
        XCTAssertEqual(logger.sessionEvents.map(\.message), expectedLoggedEvents)
    }

    func test_Inits_WithProvidedEntries_WithoutRequestingSave() {
        let seed = JJMockPersistence.makeMockEntries(count: 3)
        let expectedLoadActions = [JJMockPersistence.makeMockLoadable(overridingEntries: seed)]
        let expectedLoggedEvents = [
            "JournalStore received 3 entries",
            "JournalStore served entry list of 3"
        ]
        let (sut, logger, persistence) = makeSUT(seedEntries: seed)

        let error = performStart(sut)
        let result = sut.listEntries()

        XCTAssertEqual(persistence.mockEntries, seed)
        XCTAssertEqual(persistence.loadActions, expectedLoadActions)
        XCTAssertNil(error)
        XCTAssertEqual(Set(result), Set(seed))
        XCTAssertTrue(persistence.saveActions.isEmpty)
        XCTAssertEqual(logger.sessionErrors.map(\.message), [])
        XCTAssertEqual(logger.sessionEvents.map(\.message), expectedLoggedEvents)
    }

    func test_Inits_ReportsFailureIfPersistenceUnavailable() throws {
        let (sut, _, _) = makeSUT(seedEntries: []) // Don't keep reference to cause failure
        let expectedError: JJLoadingError = .persistenceServiceUnavailable

        let error = try XCTUnwrap(performStart(sut, timeout: 1, invertExpectation: true))

        XCTAssertEqual(error.localizedDescription, expectedError.localizedDescription)
    }

    // MARK: - JJEntryProviding

    func test_List_DoesNotProvideNonExistentEntry() {
        let seed = JJMockPersistence.makeMockEntries(count: 2)
        let (sut, _, persistence) = makeSUT(seedEntries: seed)

        let error = performStart(sut)
        let result1 = sut.getEntry(id: .init())
        let result2 = sut.listEntries()

        XCTAssertNil(error)
        XCTAssertNil(result1)
        XCTAssertTrue(result2.allSatisfy { seed.contains($0)} )
        XCTAssertEqual(persistence.loadActions.count, 1)
    }

    func test_ConcurrentReads_OccurSafely() {
        let seed = JJMockPersistence.makeMockEntries(count: 10)
        let (sut, _, persistence) = makeSUT(seedEntries: seed)
        let error = performStart(sut)

        let group = DispatchGroup()
        let testCount = 100_000

        for _ in 0...testCount {
            group.enter()
            DispatchQueue.global().async {
                let duration = arc4random() % 1000
                usleep(duration)
                let _ = sut.listEntries()
                group.leave()
            }
        }
        let outcome = group.wait(timeout: .now() + 5)

        XCTAssertNil(error)
        XCTAssertEqual(outcome, .success)
        XCTAssertEqual(persistence.loadActions.count, 1)
    }

    // MARK: - JJEntryEditing

    func test_Add_DoesPersistAndStoreNewEntries() {
        let seed = JJMockPersistence.makeMockEntries(count: 2)
        let expectedLoggedEvents = [
            "JournalStore received 0 entries",
            "Persistence saved 1 entries",
            "JournalStore saved entry Imagine no possessions",
            "Persistence saved 1 entries",
            "JournalStore saved entry I wonder if you can",
            "JournalStore served entry list of 2"
        ]
        let (sut, logger, persistence) = makeSUT(seedEntries: [])

        let error = performStart(sut)
        sut.addEntry(title: seed[0].title, content: seed[0].content)
        sut.addEntry(title: seed[1].title, content: seed[1].content)
        let result = sut.listEntries()


        XCTAssertNil(error)
        XCTAssertEqual(Set(result.map(\.title)), Set(seed.map(\.title)))
        XCTAssertEqual(persistence.saveActions.count, 2)
        XCTAssertTrue(persistence.saveActions.allSatisfy { $0.count == 1})
        XCTAssertEqual(logger.sessionErrors.map(\.message), [])
        XCTAssertEqual(logger.sessionEvents.map(\.message), expectedLoggedEvents)
    }

    func test_Add_AcceptsWriteRequestsSafelyFromMultipleQueues() {
        let (sut, _, persistence) = makeSUT(seedEntries: [])
        let error = performStart(sut)

        let group = DispatchGroup()
        let testCount = 100_000

        for _ in 0..<testCount {
            group.enter()
            DispatchQueue.global().async {
                let duration = arc4random() % 1000
                usleep(duration)
                sut.addEntry(title: "\(Int(duration))", content: "")
                group.leave()
            }
        }
        let outcome = group.wait(timeout: .now() + 5)
        let entryCount = sut.listEntries().endIndex

        XCTAssertNil(error)
        XCTAssertEqual(outcome, .success)
        XCTAssertEqual(persistence.loadActions.count, 1)
        XCTAssertEqual(entryCount, testCount)
    }

    func test_ConcurrentReadWrites_OccurSafely() {
        let (sut, _, persistence) = makeSUT(seedEntries: [])
        let error = performStart(sut)
        let testCount = 100_000
        let writeMultiple = 1_000

        DispatchQueue.concurrentPerform(iterations: testCount) { i in
            let _ = sut.listEntries()
            guard i.isMultiple(of: writeMultiple) else { return }
            sut.addEntry(title: "\(i)", content: "")
        }
        let entryCount = sut.listEntries().endIndex

        XCTAssertEqual(entryCount, testCount / writeMultiple)
        XCTAssertNil(error)
        XCTAssertEqual(persistence.loadActions.count, 1)
    }

    // MARK: - Termination

    func test_Termination_OccursAfterWrites() {
        let addition = JJMockPersistence.makeMockEntries(count: 2)
        let expectedLoggedEvents = [
            "JournalStore received 0 entries",
            "Persistence saved 1 entries",
            "JournalStore saved entry Imagine no possessions",
            "Persistence saved 1 entries",
            "JournalStore saved entry I wonder if you can"
        ]
        let (sut, logger, persistence) = makeSUT(seedEntries: [])

        let loadError = performStart(sut)
        sut.addEntry(title: addition[0].title, content: addition[0].content)
        sut.addEntry(title: addition[1].title, content: addition[1].content)
        let terminateError = performTerminate(sut, timeout: 0.25)

        XCTAssertNil(loadError)
        XCTAssertNil(terminateError)
        XCTAssertEqual(persistence.saveActions.count, 2)
        XCTAssertTrue(persistence.saveActions.allSatisfy { $0.count == 1})
        XCTAssertEqual(logger.sessionErrors.map(\.message), [])
        XCTAssertEqual(logger.sessionEvents.map(\.message), expectedLoggedEvents)
    }

}

// MARK: - Helpers

extension ConcurrentJournalStoreTests {

    func performStart(_ sut: JJEntriesStore, timeout seconds: TimeInterval = 2, invertExpectation: Bool = false) -> Error? {
        let completesTask = XCTestExpectation(description: "Completes start task")
        if invertExpectation {
            completesTask.isInverted = true
        } else {
            completesTask.expectedFulfillmentCount = 1
        }

        var tasks = Set<AnyCancellable>()
        var awaitedError: Error? = nil
        sut.start().sink { completion in
            if case let .failure(error) = completion {
                awaitedError = error
            }
        } receiveValue: { _ in
            completesTask.fulfill()
        }
        .store(in: &tasks)

        wait(for: [completesTask], timeout: seconds)
        return awaitedError
    }

    func performTerminate(_ sut: JJEntriesStore, timeout seconds: TimeInterval = 1) -> Error? {
        let completesTask = XCTestExpectation(description: "Completes start task")
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

    func makeSUT(seedEntries: [JJEntry]) -> (sut: JJEntriesStore,
                                             logger: JJSystemLogger,
                                             persistence: JJMockPersistence) {

        let logger = JJSystemLogger(label: "tests")
        let persistence = JJMockPersistence(
            seedEntries: seedEntries,
            mode: .immediatelyLoadUserEntryLibrary,
            location: .desktop,
            logger: logger
        )
        let sut = ConcurrentJournalStore(persistence: persistence, logger: logger)

        assertNoLocalRetainCycle(logger)
        assertNoLocalRetainCycle(persistence)
        assertNoLocalRetainCycle(sut)
        return (sut, logger, persistence)
    }
}
