//  © 2021 Ryan Ferrell. github.com/importRyan


import Foundation
import Journaling

extension DevelopmentConfig {
    init() {
        self.init(formatting: TerminalJJEntryFormatter())
    }
}

extension AddOnlyDevelopmentConfig {
    init() {
        self.init(formatting: TerminalJJEntryFormatter())
    }
}
