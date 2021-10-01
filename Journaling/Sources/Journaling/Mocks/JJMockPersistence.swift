//  © 2021 Ryan Ferrell. github.com/importRyan


import Foundation
import Combine

public class JJMockPersistence {

    public var mockEntries: [JJEntry]
    public var saveActions: [[JJEntry]] = []
    public var loadActions: [JournalLibraryLoadable] = []

    public weak var errorHandlingDelegate: PersistingErrorHandlingDelegate? = nil
    public private(set) weak var logger: JJLogging?
    public let queue: DispatchQueue
    public let mode: JJEntryLoadingMode
    public let location: JJJournalLibraryLocation

    public init(
        seedEntries: [JJEntry],
        mode: JJEntryLoadingMode,
        location: JJJournalLibraryLocation,
        logger: JJLogging,
        queue: DispatchQueue = .init(label: "\(appIdentifier).mockPersistence",
                                     qos: .background)) {
        self.mockEntries = seedEntries
        self.queue = queue
        self.mode = mode
        self.logger = logger
        self.location = location
    }
}

extension JJMockPersistence: JJPersisting {

    public func loadJournalLibrary() -> AnyPublisher<JournalLibraryLoadable, Error> {
        switch mode {
            case .writeOnlyMode:
                return Deferred { Future { [weak self] promise in
                    self?.queue.async { [weak self] in
                        let loadable = Self.makeMockLoadable(overridingEntries: [])
                        self?.loadActions.append(loadable)
                        promise(.success(loadable))
                    }
                }}.eraseToAnyPublisher()

            case .immediatelyLoadUserEntryLibrary:
                return Just(Self.makeMockLoadable(overridingEntries: mockEntries))
                    .handleEvents(receiveOutput: { [weak self] in
                        self?.loadActions.append($0)
                    })
                    .setFailureType(to: Error.self)
                    .delay(for: 0.25, tolerance: nil, scheduler: queue)
                    .eraseToAnyPublisher()
        }
    }

    public func save(entries: [JJEntry]) {
        logger?.log(event: "Persistence saved \(entries.endIndex) entries")
        saveActions.append(entries)

        for entry in entries {
            if let i = mockEntries.firstIndex(where: { $0.id == entry.id }) {
                mockEntries[i] = entry
            }
        }
    }

    public func appWillTerminate() -> Result<Void, Error> {
        queue.sync { [self] in
            self.logger?.log(event: "Persistence finished saving files.")
            return .success(())
        }
    }
}

// MARK: - Fake Data Generation Methods

extension JJMockPersistence {

    public static func makeMockLoadable(overridingEntries: [JJEntry]? = nil) -> JournalLibraryLoadable {
        JournalLibraryLoadable(entries: overridingEntries ?? makeMockEntries(count: 5))
    }

    public static func makeMockEntries(count: Int, randomize: Bool = false) -> [JJEntry] {
        let titleBankMax = mockTitles.endIndex - 1
        let contentBankMax = mockContents.endIndex - 1

        func getEntry(loopingOver index: Int) -> JJEntry {
            JJEntry(
                title: Self.mockTitles[index % titleBankMax],
                content: Self.mockContents[index % contentBankMax],
                edited: Date(timeIntervalSince1970: TimeInterval(index)),
                created: Date(timeIntervalSince1970: TimeInterval(index))
            )
        }

        if randomize {
            var queue = Set((0..<count).map{$0})
            var entries = [JJEntry]()
            while !queue.isEmpty {
                guard let index = queue.popFirst() else { break }
                entries.append(getEntry(loopingOver: index))
            }
            return entries

        } else {
            return (0..<count).map(getEntry(loopingOver:))
        }
    }

    private static let mockTitles: [String] = [
        "Imagine no possessions",
        "I wonder if you can",
        "No need for greed or hunger",
        "A brotherhood of man",
        "Imagine all the people",
        "Sharing all the world",
        "You may say I'm a dreamer",
        "But I'm not the only one",
        "I hope someday you'll join us",
        "And the world will live as one",
    ]

    private static let mockContents: [String] = ["""
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed in mauris metus. Suspendisse vel mauris nisl. Nullam quis nisl vel ante ultricies gravida. Donec eu suscipit nisi. Vestibulum odio lectus, feugiat nec efficitur quis, ultricies a nibh. Cras tempus fermentum tellus, et viverra nulla consectetur vel. Sed tincidunt sed arcu pellentesque efficitur.

""", """
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Maecenas faucibus mauris consectetur, tincidunt ipsum in, fringilla ligula. Mauris ex justo, ultricies et nisi vehicula, molestie commodo turpis. Pellentesque ultricies dignissim posuere. Aliquam porta tincidunt lorem. Vestibulum vitae nunc purus. Nullam consequat augue et arcu lobortis interdum. Integer ac facilisis nibh, quis convallis orci.

""","""
Nullam rhoncus velit sed turpis elementum, ut elementum lacus tempor. Maecenas condimentum ultricies eros, aliquet viverra sapien maximus sit amet. Morbi et nisl pretium, finibus lacus in, consequat massa. Vestibulum sagittis placerat tellus, vel placerat purus gravida et. Suspendisse potenti. Pellentesque euismod tincidunt nulla, aliquam porttitor augue ullamcorper at. Nunc sollicitudin semper nisl nec vestibulum. Nulla dictum velit pulvinar, porttitor nisl eu, hendrerit libero. In iaculis eros ut laoreet viverra. Suspendisse arcu elit, commodo viverra semper in, feugiat eget enim.

""", """
Nam eget vehicula augue. Pellentesque tincidunt ipsum sit amet fermentum consectetur. Praesent a rhoncus felis. Mauris eu luctus quam, eu dignissim enim. In ut justo ac sapien semper molestie. Maecenas efficitur, turpis et fermentum imperdiet, tellus enim laoreet arcu, nec rutrum felis risus quis quam. Etiam in scelerisque purus. Donec suscipit turpis in condimentum consectetur. Vivamus id cursus nunc. Phasellus a dictum libero, sit amet dapibus tellus. In porttitor risus enim, sed sollicitudin tortor mollis faucibus. Vestibulum sed lacus sed nibh pretium posuere quis sed sem. Cras egestas enim lorem, ac condimentum erat pellentesque ut.

"""
    ]
}
