//  © 2021 Ryan Ferrell. github.com/importRyan


import Foundation
import Journaling
import Darwin

internal extension CommandLine {

    static func getViewportColumnWidth() -> Int? {
        var w = winsize()
        guard ioctl(STDOUT_FILENO, TIOCGWINSZ, &w) == 0 else { return nil }
        return Int(w.ws_col)
    }

    static func getViewportColumnWidthOrDefault() -> Int {
        getViewportColumnWidth() ?? 30
    }

    static func output(_ string: String) {
        print(string)
    }
}
