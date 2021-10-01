//  © 2021 Ryan Ferrell. github.com/importRyan


import Foundation

public class MockLoader: AppLoader {

    public init() { }
    public var overrideConfig: AppConfig? = nil
    public weak var loggerReference: SystemLogger? = nil
    public weak var persistenceReference: MockPersistenceManager? = nil

    public func load(with configuration: AppConfig) -> Result<AppLoadables,Error> {

        let config = overrideConfig ?? configuration

        let logger = SystemLogger(label: "mocks")
        let persistence = MockPersistenceManager(mode: config.loadEntries,
                                                 location: config.journalLocation,
                                                 logger: logger)
        let store = MockJournalStore(persistence: persistence, logger: logger)
        let formatter = JJStaticFormattingStore(formatter: config.formatting)

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
