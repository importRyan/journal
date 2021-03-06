//  © 2021 Ryan Ferrell. github.com/importRyan

import Foundation
import Journaling
import ArgumentParser

// Overrides for dependency injection via private command line flags
fileprivate var loader: JJAppLoader = CommandLineLoader()
fileprivate var overrideConfig: JJAppConfig? = nil

// App lazily is loaded after parsing command line input.
fileprivate(set) var app: JJJournaling! = nil

// Launches the command line user interface.
OptionsOnlyInterface.main()

// Holds loop open for any async background tasks (e.g., persistence).
RunLoop.main.run()

// MARK: - Launch/Close Methods

/// Initializes the app with any overrides
/// parsed from command line arguments
///
func startApp<T: ParsableCommand>(
    from command: T,
    config: JJAppConfig = JJDevelopmentConfig(),
    didStart: @escaping () -> Void) {

        guard app == nil else {
            reportLoadAttempt()
            return
        }
        do {
            app = try JournalApp(
                loader: loader,
                config: overrideConfig ?? config
            )
            app.start { error in
                if let error = error { T.exit(withError: error) }
                else { didStart() }
            }
        } catch { T.exit(withError: error) }
    }

/// Waits for any asynchronous work and
/// calls ArgumentParser exit commands once done.
///
func exitApp<T: ParsableCommand>(from command: T) {
    switch app.appWillTerminate() {
        case .success:
            T.exit()

        case .failure(let error):
            T.exit(withError: error)
    }
}

fileprivate func reportLoadAttempt() {
    app.logger.log(event: "Attempted to load app more than once.")
}

// MARK: - Overrides for dependency injection via private/public command line flags

func _setConfigurationOverride(_ override: JJAppConfig) {
    overrideConfig = override
}

func _setLoaderOverride(_ override: JJAppLoader) {
    loader = override
}
