//  © 2021 Ryan Ferrell. github.com/importRyan


import Foundation

public protocol JJAppLoader {
    func load(with configuration: JJAppConfig) -> Result<JJAppLoadables,Error>
}

public struct JJAppLoadables {
    public let persistence: JJPersisting
    public let store: JJEntriesStore
    public let logger: JJLogging
    public let formatting: JJFormatting

    public init(persistence: JJPersisting, store: JJEntriesStore, logger: JJLogging, formatting: JJFormatting) {
        self.persistence = persistence
        self.store = store
        self.logger = logger
        self.formatting = formatting
    }
}

public enum JJLoadingError: String, Error {
    case persistenceServiceUnavailable
}
