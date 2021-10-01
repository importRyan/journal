//  © 2021 Ryan Ferrell. github.com/importRyan


import Foundation
import Combine

public class JournalApp {
    
    public let store: JJEntriesStore
    public let logger: JJLogging
    public let formatting: JJFormatting
    
    private let persistence: JJPersisting
    private var appStartup: AnyCancellable? = nil
    
    public required init(loader: JJAppLoader, config: JJAppConfig) throws {
        switch loader.load(with: config) {
            case .success(let loadables):
                self.store = loadables.store
                self.persistence = loadables.persistence
                self.logger = loadables.logger
                self.formatting = loadables.formatting
                
            case .failure(let error):
                throw error
        }
    }
}

extension JournalApp: JJJournaling {
    
    /// Returns on main thread with any error that interrupted loading
    public func start(tasksDidComplete: @escaping (Error?) -> Void) {
        appStartup = store.start()
            .receive(on: DispatchQueue.main, options: nil)
            .sink { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                self?.logger.log(error: error)
                
            } receiveValue: { [weak self] didSucceed in
                tasksDidComplete(nil)
                self?.logger.log(event: "Journal app started successfully.")
            }
    }
    
    /// Returns on requesting thread with any error that interrupted final tasks
    /// Enqueues termination behind any work in progress from the entries store and then persistence service
    public func appWillTerminate() -> Result<Void,Error> {
        store.appWillTerminate()
            .flatMap(persistence.appWillTerminate)
            .flatMapError { error in
                self.logger.log(error: error)
                return .failure(error)
            }
    }
}
