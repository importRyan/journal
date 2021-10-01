//  © 2021 Ryan Ferrell. github.com/importRyan


import Foundation
import Journaling
import JournalingPersistence

internal class CommandLineLoader: JJAppLoader {

    init() { }

    func load(with configuration: JJAppConfig) -> Result<JJAppLoadables, Error> {

        let logger = JJSystemLogger(label: "commandline")

        let persistence = JJLocalPersistenceManager(
            mode: configuration.loadEntries,
            location: configuration.journalLocation,
            logger: logger
        )

        let store = ConcurrentJournalStore(
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
