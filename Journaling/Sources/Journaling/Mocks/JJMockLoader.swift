//  © 2021 Ryan Ferrell. github.com/importRyan


import Foundation

public class JJMockLoader: JJAppLoader {

    public let seedEntries: [JJEntry]

    public init(seedEntries: [JJEntry] = JJMockPersistenceManager.makeMockEntries(count: 5)) {
        self.seedEntries = seedEntries
    }
    public var overrideConfig: JJAppConfig? = nil
    public weak var loggerReference: JJSystemLogger? = nil
    public weak var persistenceReference: JJMockPersistenceManager? = nil

    public func load(with configuration: JJAppConfig) -> Result<JJAppLoadables,Error> {

        let config = overrideConfig ?? configuration

        let logger = JJSystemLogger(label: "mocks")

        let persistence = JJMockPersistenceManager(
            seedEntries: seedEntries,
            mode: config.loadEntries,
            location: config.journalLocation,
            logger: logger
        )

        let store = ConcurrentJournalStore(
            persistence: persistence,
            logger: logger
        )

        let formatter = JJStaticFormattingStore(
            formatter: config.formatting
        )

        self.loggerReference = logger
        self.persistenceReference = persistence

        return .success(
            .init(persistence: persistence,
                  store: store,
                  logger: logger,
                  formatting: formatter)
        )
    }
}
