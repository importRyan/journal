//  © 2021 Ryan Ferrell. github.com/importRyan


import Foundation
import Combine

public class JournalApp {

    public let store: JournalEntryStore
    public let logger: Logging
    public let formatting: JJFormatting

    private let persistence: Persisting
    private var appStartup: AnyCancellable? = nil

    public required init(loader: AppLoader, config: AppConfig) throws {
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

extension JournalApp: JournalingApp {

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

    /// Returns on main thread with any error that interrupted final tasks
    public func exit(tasksDidComplete: @escaping (Error?) -> Void) {
        persistence.performRemainingTasksBeforeTermination { [self] error in
            if let error = error {
                self.logger.log(error: error)
            }
            DispatchQueue.main.async {
                tasksDidComplete(error)
            }
        }
    }
}
