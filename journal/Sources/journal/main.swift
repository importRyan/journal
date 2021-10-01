//  © 2021 Ryan Ferrell. github.com/importRyan

import Foundation
import Journaling
import ArgumentParser

// App lazily loaded after parsing command line input.
fileprivate(set) var app: JournalingApp! = nil

// Launch a command line user interface.
OptionsOnlyInterface.main()

// Hold loop open for any async background tasks (e.g., persistence).
RunLoop.main.run()


// MARK: - Helper Methods

func startApp(config: AppConfig = DevelopmentConfig(), didStart: @escaping () -> Void) {
    guard app == nil else { reportLoadAttempt(); return }
    do {
        app = try JournalApp(loader: loader, config: overrideConfig ?? config)
        app.start { error in
            if let error = error { exit(with: error) }
            else { didStart() }
        }
    } catch { exit(with: error) }
}

}

fileprivate func reportLoadAttempt() {
    app.logger.log(event: "Attempted to load app more than once.")
}

fileprivate func exit(with error: Error) {
    NSLog("Journal app failed to load.")
    NSLog(error.localizedDescription)
    exit(EXIT_FAILURE)

// MARK: - Overrides for dependency injection via private/public command line flags

fileprivate var loader: AppLoader = CommandLineLoader()
fileprivate var overrideConfig: AppConfig? = nil

func _setConfigurationOverride(_ override: AppConfig) {
    overrideConfig = override
}

func _setLoaderOverride(_ override: AppLoader) {
    loader = override
}
