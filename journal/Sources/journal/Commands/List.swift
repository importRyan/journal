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
        startApp { [self] in
            let entries = app.store.listEntries()

            // Format entries into text table
            let vm = EntryListViewModel(entries: entries)
            let tableViewContent = vm.parseForTableView()
            render(tableViewContent: tableViewContent)

            app.exit { _ in
                Self.exit()
            }
        }
    }

    private var tableView = PlainTextTableView(
        columns: List.EntryListViewModel.tableViewColumns,
        options: List.EntryListViewModel.tableViewOptions
    )

    private func render(tableViewContent: [[String]]) {
        let width = CommandLine.getViewportColumnWidthOrDefault()
        tableView.layoutByColumnAndViewportConstraints(viewportWidth: width)
        let table = tableView.render(content: tableViewContent)
        CommandLine.output(table)
    }
}

// MARK: - View Model

extension List {

    struct EntryListViewModel {

        private var entries: [JJEntry]

        init(entries: [JJEntry]) {
            self.entries = entries
        }

        /// Outer: Rows. Inner: Columns.
        func parseForTableView() -> [[String]] {
            entries.map { entry in
                [entry.title]
            }
        }

        static let tableViewColumns: [PlainTextTableView.Column] = [
            .init(
                title: "Title",
                minWidth: 10, initialWidth: nil, maxWidth: nil,
                adjustability: .resistance(0),
                wrap: .wrapInsideColumn
            )
        ]

        static let tableViewOptions = PlainTextTableView.Options(
            rowLabeling: .showIndexesZeroBased,
            columnMarginWidth: 1,
            showColumnHeaders: true,
            capitalizeColumnHeaders: true
        )
    }
}
