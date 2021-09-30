//  © 2021 Ryan Ferrell. github.com/importRyan


import Foundation

public struct MockLoader: AppLoader {

    public init() { }

    public func load(with configuration: AppConfig) -> Result<AppLoadables,Error> {

        let logger = SystemLogger(label: "mocks")
        let persistence = MockPersistenceManager(mode: configuration.loadEntries, logger: logger)
        let store = MockJournalStore(persistence: persistence, logger: logger)
        let formatter = JJStaticFormattingStore(formatter: configuration.formatting)

        return .success(
            .init(persistence: persistence,
                  store: store,
                  logger: logger,
                  formatting: formatter)
        )
    }
}
