//  © 2021 Ryan Ferrell. github.com/importRyan

import Foundation
import ArgumentParser
import Journaling

/// Generates the assigned user-facing interface
/// of optional arguments with long labels.
///
/// Anticipating Monday's feature additions that may be more
/// ergonomic using subcommands, this forwards user intents
/// to such subcommands (that are not otherwise exposed) and
/// presents a --help prompt.
///
struct OptionsOnlyInterface: ParsableCommand {

    static var configuration = CommandConfiguration(
        commandName: "journal",
        abstract: Journal.configuration.abstract,
        shouldDisplay: true,
        helpNames: .shortAndLong
    )

    @Option(name: .customLong("create"), help: Add.Help.entry) var entry: String = ""
    @Option(name: .customLong("title"),  help: Add.Help.title) var title: String = ""
    @Flag  (name: .customLong("list"),   help: .init(List.configuration.abstract)) var enumerateEntries = false
    // Test usage
    @Flag  (name: .customLong("lazy"), help: .hidden) var lazilyLoadEntriesOverride = false
    @Flag  (name: .customLong("mock"), help: .hidden) var useMockLoader = false

    mutating func run() throws {
        #if DEBUG
        _handleDevelopmentFlags()
        #endif
        let add = forwardAddEntrySubcommand()
        let list = forwardListSubcommand()
        showHelpIfNoCommandsForwarded(add, list)
    }

    func _handleDevelopmentFlags() {
        if lazilyLoadEntriesOverride {
            _setConfigurationOverride(AddOnlyDevelopmentConfig())
        }
        if useMockLoader {
            _setLoaderOverride(MockLoader())
        }
    }
}

extension OptionsOnlyInterface {

    /// If relevant option(s) present, forward to Add subcommand
    func forwardAddEntrySubcommand() -> Bool {
        let isCreatingNewEntry = !entry.isEmpty || !title.isEmpty
        if isCreatingNewEntry {
            var options = Add.parseOrExit(["--title", title, "--entry", entry])
            options.run()
        }
        return isCreatingNewEntry
    }

    /// If relevant option present, forward to List subcommand
    func forwardListSubcommand() -> Bool {
        if enumerateEntries {
            var list = List()
            list.run()
        }
        return enumerateEntries
    }

    /// Workaround to surface a help prompt. In the ArgumentParser library,
    /// when all arguments are options, the help prompt does not trigger
    /// on empty user input (i.e., is seen as a valid input).
    func showHelpIfNoCommandsForwarded(_ commands: Bool...) {
        if commands.allSatisfy({ $0 == false }) {
            CommandLine.output(OptionsOnlyInterface.helpMessage())
            Self.exit(withError: ExitCode.validationFailure)
        }
    }
}
