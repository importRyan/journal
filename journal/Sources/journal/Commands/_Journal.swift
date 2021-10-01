//  © 2021 Ryan Ferrell. github.com/importRyan

import Foundation
import ArgumentParser

/// Exposes subcommand interface and generates relevant help.
/// To adopt, replace `OptionsOnlyInterface` in main.swift and
/// route --mock and --lazy flags for tests.
/// 
struct Journal: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "Store and display personal journal entries.",
        shouldDisplay: true,
        subcommands: [Add.self, List.self],
        defaultSubcommand: Add.self,
        helpNames: .shortAndLong
    )
}
