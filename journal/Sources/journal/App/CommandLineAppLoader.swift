//  © 2021 Ryan Ferrell. github.com/importRyan


import Foundation
import Journaling
import JournalingPersistence

internal class CommandLineLoader: AppLoader {

    init() { }

    func load(with configuration: AppConfig) -> Result<AppLoadables, Error> {

        let logger = SystemLogger(label: "commandline")

        let persistence = LocalPersistenceManager(
            mode: configuration.loadEntries,
            location: configuration.journalLocation,
            logger: logger
        )

        let store = MockJournalStore(
            persistence: persistence,
            logger: logger
        )

        let formatter = JJStaticFormattingStore(
            formatter: configuration.formatting
        )

        return .success(
            .init(persistence: persistence,
                  store: store,
                  logger: logger,
                  formatting: formatter)
        )
    }

}
