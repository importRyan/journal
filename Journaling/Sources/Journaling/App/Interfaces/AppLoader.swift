//  © 2021 Ryan Ferrell. github.com/importRyan


import Foundation

public protocol AppLoader {
    func load(with configuration: AppConfig) -> Result<AppLoadables,Error>
}

public struct AppLoadables {
    public let persistence: Persisting
    public let store: JournalEntryStore
    public let logger: Logging
    public let formatting: JJFormatting
}

enum LoadingError: String, Error {
    case persistenceServiceUnavailable
}
