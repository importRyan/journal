import Foundation
import XCTest
import ArgumentParser
@testable import journal
@testable import Journaling

final class OptionsOnlyInterfaceTests: XCTestCase {

    func test_ExitsByWallClock_WithValidCommands() {
        let commands = [
            "",
            "--list",
            "--create \"entry\"",
            "--create \"entry\" --title \"heading\"",
        ]

        commands.forEach { command in
            XCTExpectFailure("Troubleshooting sporadic exit code 5 after Monterey beta 21A5534d update", options: .nonStrict()) {
                AssertExecuteCommand(
                    command: Self.appName + " " + command,
                    exitCodes: [.success, .validationFailure],
                    maximumRunTime: 1
                )
            }
        }
    }

    // MARK: - Root

    func test_RootCommand_SansArguments_OutputsHelpAndExitsWithValidationFailure() {
        let helpText = """
OVERVIEW: Store and display personal journal entries.

USAGE: journal [--create <entry body>] [--title <entry title>] [--list]

OPTIONS:
  --create <entry body>   Add an entry with a body.
  --title <entry title>   Add an entry with a title.
  --list                  Enumerate your journal entries.
  -h, --help              Show help information.
"""
        XCTExpectFailure("Troubleshooting sporadic exit code 5 after Monterey beta 21A5534d update", options: .nonStrict()) {
            AssertExecuteCommand(
                command: "journal",
                expected: helpText,
                exitCodes: [.validationFailure], // Seems to be macOS Beta
                includeErrorOutput: false
            )
        }
    }

    // MARK: - Create

    func test_CreateCommand_WithInvalidOptions_OutputsHelpAndExitsWithValidationFailure() {
        let missingValueForCreate = """
        Error: Missing value for '--create <entry body>'
        Help:  --create <entry body>  Add an entry with a body.
        Usage: journal [--create <entry body>] [--title <entry title>] [--list]
          See 'journal --help' for more information.
        """

        let missingValueForTitle = """
        Error: Missing value for '--title <entry title>'
        Help:  --title <entry title>  Add an entry with a title.
        Usage: journal [--create <entry body>] [--title <entry title>] [--list]
          See 'journal --help' for more information.
        """

        let tests = [
            CommandCase(incomplete: "--create", expectedOutput: missingValueForCreate),
            CommandCase(incomplete: "--title", expectedOutput: missingValueForTitle)
        ]

        tests.forEach { command in
            AssertExecuteCommand(
                command: command.userInput(),
                expected: command.expectedOutput,
                exitCodes: [command.exitCode],
                maximumRunTime: 1,
                includeErrorOutput: true
            )
        }
    }

    func test_CreateCommands_ValidCommands_DoNotOutputText() {
        let tests = [
            CommandCase(valid: "--create \"entry\"", expectedOutput: ""),
            CommandCase(valid: "--title \"heading\"", expectedOutput: ""),
            CommandCase(valid: "--create \"entry\" --title \"heading\"", expectedOutput: "")
        ]

        tests.forEach { command in
            AssertExecuteCommand(
                command: command.userInput(),
                expected: command.expectedOutput,
                exitCodes: [command.exitCode],
                maximumRunTime: 1,
                includeErrorOutput: false
            )
        }
    }

    // MARK: - List

    func test_ListCommand_EmptyMockData_DisplaysEmptyMessage() {
        let test = CommandCase(valid: "--list", expectedOutput: "No entries available.")

        AssertExecuteCommand(
            command: test.userInputWithLazyLoadOverride(),
            expected: test.expectedOutput,
            exitCodes: [test.exitCode],
            maximumRunTime: 1,
            includeErrorOutput: false
        )
    }

    func test_ListCommand_JohnLennonMockData_DisplaysEntries() {
        let lennonList = """
        # TITLE
        0 Imagine all the people
        1 A brotherhood of man
        2 No need for greed or hunger
        3 I wonder if you can
        4 Imagine no possessions
        """

        let test = CommandCase(valid: "--list", expectedOutput: lennonList)
        AssertExecuteCommand(
            command: test.userInput(),
            expected: test.expectedOutput,
            exitCodes: [test.exitCode],
            maximumRunTime: 20,
            includeErrorOutput: false
        )
    }
}
