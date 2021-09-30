//  © 2021 Ryan Ferrell. github.com/importRyan

import Foundation
import ArgumentParser

/// Exposes subcommand interface and generates relevant help.
/// Replace `OptionsOnlyInterface` in main.swift to use.
struct Journal: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "Store and display personal journal entries.",
        shouldDisplay: true,
        subcommands: [Add.self, List.self],
        defaultSubcommand: Add.self,
        helpNames: .shortAndLong
    )
}
