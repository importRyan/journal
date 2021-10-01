//  © 2021 Ryan Ferrell. github.com/importRyan


import Foundation
import Combine

public class MockPersistenceManager {

    public weak var errorHandlingDelegate: PersistingErrorHandlingDelegate? = nil
    public private(set) weak var logger: Logging?
    public let queue: DispatchQueue
    public let mode: EntryLoadingMode
    public let location: JournalLibraryLocation

    public init(mode: EntryLoadingMode,
                location: JournalLibraryLocation,
                logger: Logging,
                queue: DispatchQueue = .init(label: "\(appIdentifier).mockPersistence",
                                             qos: .background)) {
        self.queue = queue
        self.mode = mode
        self.logger = logger
        self.location = location
    }
}

extension MockPersistenceManager: Persisting {

    public func loadJournalLibrary() -> AnyPublisher<JournalLibraryLoadable, Error> {
        switch mode {
            case .writeOnlyMode:
                return Deferred { Future { [weak self] promise in
                    self?.queue.async {
                        let loadable = Self.makeMockLoadable(overridingEntries: [])
                        promise(.success(loadable))
                    }
                }}.eraseToAnyPublisher()

            case .immediatelyLoadUserEntryLibrary:
                return Just(Self.makeMockLoadable())
                    .setFailureType(to: Error.self)
                    .delay(for: 0.25, tolerance: nil, scheduler: queue)
                    .eraseToAnyPublisher()
        }
    }

    public func save(entries: [JJEntry]) {
        logger?.log(event: "Persistence saved \(entries.endIndex) entries")
        Self.mockEntries.append(contentsOf: entries)
    }

    public func appWillTerminate() -> Result<Void, Error> {
        queue.sync { [self] in
            self.logger?.log(event: "Persistence finished saving files.")
            return .success(())
        }
    }
}

// MARK: - Mock Data State

extension MockPersistenceManager {

    /// Updated on "saves"
    public static var mockEntries: [JJEntry] = makeMockEntries(count: 5)

}

// MARK: - Fake Data Generation Methods

extension MockPersistenceManager {

    private static func makeMockLoadable(overridingEntries: [JJEntry]? = nil) -> JournalLibraryLoadable {
        JournalLibraryLoadable(entries: overridingEntries ?? Self.mockEntries)
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

Nam eget vehicula augue. Pellentesque tincidunt ipsum sit amet fermentum consectetur. Praesent a rhoncus felis. Mauris eu luctus quam, eu dignissim enim. In ut justo ac sapien semper molestie. Maecenas efficitur, turpis et fermentum imperdiet, tellus enim laoreet arcu, nec rutrum felis risus quis quam. Etiam in scelerisque purus. Donec suscipit turpis in condimentum consectetur. Vivamus id cursus nunc. Phasellus a dictum libero, sit amet dapibus tellus. In porttitor risus enim, sed sollicitudin tortor mollis faucibus. Vestibulum sed lacus sed nibh pretium posuere quis sed sem. Cras egestas enim lorem, ac condimentum erat pellentesque ut.

Nullam rhoncus velit sed turpis elementum, ut elementum lacus tempor. Maecenas condimentum ultricies eros, aliquet viverra sapien maximus sit amet. Morbi et nisl pretium, finibus lacus in, consequat massa. Vestibulum sagittis placerat tellus, vel placerat purus gravida et. Suspendisse potenti. Pellentesque euismod tincidunt nulla, aliquam porttitor augue ullamcorper at. Nunc sollicitudin semper nisl nec vestibulum. Nulla dictum velit pulvinar, porttitor nisl eu, hendrerit libero. In iaculis eros ut laoreet viverra. Suspendisse arcu elit, commodo viverra semper in, feugiat eget enim.

Etiam aliquam massa id tortor facilisis, sit amet suscipit nulla bibendum. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Sed non accumsan lorem. Etiam ut sapien elit. Maecenas convallis dapibus lacus nec luctus. Quisque porttitor nisi id neque vehicula lobortis. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Donec non purus scelerisque purus rutrum feugiat vel volutpat enim. Fusce pretium leo in est accumsan vulputate.

Fusce a dui nibh. Cras vel sollicitudin nisi, non venenatis velit. Suspendisse et vulputate quam, nec iaculis justo. Nulla tortor metus, ultrices malesuada nisi nec, iaculis facilisis arcu. Aenean quam velit, cursus eu mollis et, lacinia et sem. Fusce accumsan neque vel orci tristique tristique. Phasellus vel aliquam sem. Vivamus placerat lacus nibh, tincidunt tincidunt quam eleifend et. Vivamus porttitor mi justo, vehicula consectetur erat vestibulum in. Nunc bibendum convallis malesuada. Cras gravida ut arcu sit amet pretium. Quisque malesuada ligula mauris, porttitor ultrices tellus efficitur in. Praesent nisl massa, vulputate ac pretium ut, maximus in ipsum.
""", """
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Maecenas faucibus mauris consectetur, tincidunt ipsum in, fringilla ligula. Mauris ex justo, ultricies et nisi vehicula, molestie commodo turpis. Pellentesque ultricies dignissim posuere. Aliquam porta tincidunt lorem. Vestibulum vitae nunc purus. Nullam consequat augue et arcu lobortis interdum. Integer ac facilisis nibh, quis convallis orci.

Suspendisse viverra ullamcorper dui, et efficitur massa egestas vitae. Donec fermentum quis nibh id facilisis. Sed vulputate pulvinar magna, quis mollis mauris cursus mattis. Suspendisse faucibus sit amet nisl vel convallis. Phasellus eu tincidunt lectus. Nam vestibulum nibh sed massa hendrerit scelerisque. Nunc semper molestie dui, maximus luctus sem faucibus eu. Cras bibendum lobortis mauris, at maximus enim rutrum non. Vivamus fermentum erat sapien, eget fermentum nisi fringilla a. Pellentesque fringilla massa in lorem sodales varius. Integer at leo urna. Nulla diam lectus, accumsan sit amet nibh vitae, iaculis iaculis massa. Sed ac condimentum nisl, nec sodales mi. Vivamus bibendum sollicitudin convallis. Etiam volutpat dolor vitae ex dapibus, vel condimentum nisl ullamcorper. Maecenas vulputate dui fermentum sem eleifend interdum.

Cras tempus, felis eget fermentum interdum, diam nisi finibus turpis, in facilisis arcu urna id lorem. Nunc nisl ligula, ultrices in ante sit amet, dictum faucibus orci. Maecenas pellentesque massa tellus, a feugiat dolor vehicula id. Proin non condimentum risus. Sed velit augue, dapibus facilisis libero sit amet, venenatis rhoncus urna. Mauris gravida dolor imperdiet tempor hendrerit. Integer non congue sem. Quisque tincidunt iaculis urna, feugiat aliquam turpis posuere vel. Morbi eu sapien non massa aliquam dapibus. Duis in molestie nisl, quis luctus lacus.

Vestibulum eu felis consectetur, tincidunt orci tempor, porta dui. Sed mattis eros risus, id vestibulum urna viverra non. Etiam facilisis nec lorem eget lacinia. Sed sodales ligula mollis dapibus condimentum. Etiam efficitur dapibus ipsum, vel egestas velit. Sed sit amet ipsum sit amet tellus molestie aliquet. Curabitur a ex tristique, tincidunt ex nec, convallis enim. Mauris faucibus elit et imperdiet aliquet. Aenean euismod consectetur mauris in vestibulum. Aliquam pellentesque ligula vestibulum nibh bibendum, ac pellentesque nibh faucibus. Vestibulum at magna porta, mattis nisl at, vulputate erat.

Nam ut mauris non metus faucibus egestas. Fusce tincidunt est non nulla luctus, vel maximus magna sagittis. Cras sodales dignissim ipsum eu ultrices. Aenean vel enim erat. Etiam rutrum, felis eu lacinia sagittis, ante augue pellentesque libero, eu facilisis lacus elit id quam. Phasellus ac tellus lobortis, hendrerit enim vitae, congue leo. Integer ut porttitor dui, at luctus risus. Fusce vulputate eros vel sem laoreet, sit amet eleifend lectus porta. Ut congue nulla sit amet lobortis fringilla. Ut in tellus velit. Praesent quis nisl vehicula, feugiat enim vel, elementum justo. Sed sollicitudin malesuada posuere. Curabitur diam quam, rutrum id efficitur et, euismod nec metus. Suspendisse sed orci auctor sem luctus faucibus.
"""
    ]
}
