//  © 2021 Ryan Ferrell. github.com/importRyan

import Foundation
import ArgumentParser
import Journaling

struct Add: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "Add entries to your journal.",
        shouldDisplay: true,
        helpNames: .shortAndLong
    )

    @Option(name: .shortAndLong, help: Help.title) var title: String = ""
    @Option(name: .shortAndLong, help: Help.entry) var entry: String = ""

    mutating func run() {
        startApp(config: AddOnlyDevelopmentConfig()) { [self] in

            app.store.addEntry(title: title, content: entry)

            app.exit { _ in
                Self.exit()
            }
        }
    }

    enum Help {
        static let entry = ArgumentHelp(
            "Add an entry with a body.",
            valueName: "entry body"
        )
        static let title = ArgumentHelp(
            "Add an entry with a title.",
            valueName: "entry title"
        )
    }
}
