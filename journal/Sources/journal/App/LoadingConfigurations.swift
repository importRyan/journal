//  © 2021 Ryan Ferrell. github.com/importRyan


import Foundation
import Journaling

// MARK: - Convenience to provide a default formatter to the loading configuration inits

extension JJDevelopmentConfig {
    init() {
        self.init(formatting: TerminalJJEntryFormatter())
    }
}

extension JJAddEntriesOnlyDevelopmentConfig {
    init() {
        self.init(formatting: TerminalJJEntryFormatter())
    }
}
