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
    let lazyLoadFlag = "--lazy"
    let useMockFlag = "--mock" // Doesn't read/write disk

    /// Adds the app name and inserts a mocking flag to read and write from a mock data store.
    func userInput(withoutMockFlag: Bool = false) -> String {
        [XCTestCase.appName,
         withoutMockFlag ? nil : useMockFlag,
         command
        ].compactMap{$0}.joined(separator: " ")
    }

    /// Adds the app name and inserts a mocking flag to read and write from a mock data store.
    func userInputWithLazyLoadOverride(withoutMockFlag: Bool = false) -> String {
        [XCTestCase.appName,
         withoutMockFlag ? nil : useMockFlag,
         lazyLoadFlag,
         command
        ].compactMap{$0}.joined(separator: " ")
    }

    init(command: String, expectedOutput: String = "", exitCode: ExitCode) {
        self.command = command
        self.expectedOutput = expectedOutput
        self.exitCode = exitCode
    }

    init(valid: String, expectedOutput: String = "") {
        self.command = valid
        self.expectedOutput = expectedOutput
        self.exitCode = .success
    }

    init(incomplete: String, expectedOutput: String = "") {
        self.command = incomplete
        self.expectedOutput = expectedOutput
        self.exitCode = .validationFailure
    }

    init(failing: String, expectedOutput: String = "") {
        self.command = failing
        self.expectedOutput = expectedOutput
        self.exitCode = .failure
    }
}

