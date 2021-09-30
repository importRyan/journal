//  © 2021 Ryan Ferrell. github.com/importRyan

import Foundation
import ArgumentParser
import XCTest

extension XCTestCase {
    static let appName = "journal"
}

struct CommandCase {

    let command: String
    let expectedOutput: String
    let exitCode: ExitCode

    func userInput() -> String {
        XCTestCase.appName + " " + command
    }

    func userInputWithLazyLoadOverride() -> String {
        [XCTestCase.appName, "--lazy", command].joined(separator: " ")
    }

    init(command: String, expectedOutput: String, exitCode: ExitCode) {
        self.command = command
        self.expectedOutput = expectedOutput
        self.exitCode = exitCode
    }

    init(valid: String, expectedOutput: String) {
        self.command = valid
        self.expectedOutput = expectedOutput
        self.exitCode = .success
    }

    init(incomplete: String, expectedOutput: String) {
        self.command = incomplete
        self.expectedOutput = expectedOutput
        self.exitCode = .validationFailure
    }

    init(failing: String, expectedOutput: String) {
        self.command = failing
        self.expectedOutput = expectedOutput
        self.exitCode = .failure
    }
}

