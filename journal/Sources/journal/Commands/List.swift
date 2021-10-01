//  © 2021 Ryan Ferrell. github.com/importRyan

import Foundation
import ArgumentParser
import Journaling

struct List: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "Enumerate your journal entries.",
        shouldDisplay: true,
        helpNames: .shortAndLong
    )

    mutating func run() {
        startApp(from: self) { [self] in
            let entries = app.store.listEntries()

            if entries.isEmpty {
                displayEmptyMessage()
            } else {
                render(entries: entries)
            }

            exitApp(from: self)
        }
    }

    private var tableView = PlainTextTableView(
        columns: List.EntriesTableViewModel.tableViewColumns,
        options: List.EntriesTableViewModel.tableViewOptions
    )

    private func displayEmptyMessage() {
        CommandLine.output("No entries available.")
    }

    private func render(entries: [JJEntry]) {
        // Format entries into text table
        let vm: EntriesListTextOnlyViewModel = List.EntriesTableViewModel(
            entries: entries,
            formatting: app.formatting.current
        )
        let tableViewContent = vm.parseForTableView()

        // Render
        let width = CommandLine.getViewportColumnWidthOrDefault()
        tableView.layoutByColumnAndViewportConstraints(viewportWidth: width)
        let table = tableView.render(content: tableViewContent)
        CommandLine.output(table)
    }
}

// MARK: - View Model

public protocol EntriesListTextOnlyViewModel {
    init(entries: [JJEntry], formatting: JJEntryFormatting)
    /// Outer: Rows. Inner: Columns.
    func parseForTableView() -> [[String]]
}

extension List {
    public struct EntriesTableViewModel {

        private var entries: [JJEntry]
        private let formatting: JJEntryFormatting

        public init(entries: [JJEntry], formatting: JJEntryFormatting) {
            self.entries = entries
            self.formatting = formatting
        }

        public static let tableViewColumns: [PlainTextTableView.Column] = [
            .init(
                title: "Title",
                minWidth: 10, initialWidth: nil, maxWidth: nil,
                adjustability: .resistance(0),
                wrap: .wrapInsideColumn
            )
        ]

        public static let tableViewOptions = PlainTextTableView.Options(
            rowLabeling: .showIndexesZeroBased,
            columnMarginWidth: 1,
            showColumnHeaders: true,
            capitalizeColumnHeaders: true
        )
    }
}

extension List.EntriesTableViewModel: EntriesListTextOnlyViewModel {

    /// Outer: Rows. Inner: Columns.
    public func parseForTableView() -> [[String]] {
        entries.map { entry in
            [formatting.title.format(entry.title)]
        }
    }
}
