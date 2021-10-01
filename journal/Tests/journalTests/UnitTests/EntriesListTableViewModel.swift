//  © 2021 Ryan Ferrell. github.com/importRyan

import XCTest
@testable import journal
@testable import Journaling

final class EntriesListTableViewModel: XCTestCase {

    func test_NoInput_GeneratesEmptyOutput() {
        let sut: EntriesListTextOnlyViewModel = List.TableViewModel(
            entries: [],
            formatting: TerminalJJEntryFormatter()
        )

        let result = sut.parseForTableView()
        XCTAssertEqual(result, [])
    }

    func test_ThreeEntries_GeneratesExpectedOutput() {
        let entries: [JJEntry] = [
            .init(id: UUID(uuidString: "24BDBC0A-FA98-497C-A15F-81099A782C11")!,
                  title: "Possessions are imaginary",
                  content: "If I wonder you can",
                  edited: Date(timeIntervalSince1970: 3_111_111),
                  created: Date(timeIntervalSince1970: 1_111_111)
                 ),
            .init(id: UUID(uuidString: "8D47DEBB-F328-45CB-B4B5-678BB52D5C2F")!,
                  title: "No need for greed or hunger",
                  content: "A brotherhood of man",
                  edited: Date(timeIntervalSince1970: 1_111_111),
                  created: Date(timeIntervalSince1970: 1_111_111)
                 ),
            .init(id: UUID(uuidString: "F3B80477-BC1B-43A2-BFAA-50A4AFD40698")!,
                  title: "Imagine all the people",
                  content: "Sharing all the world",
                  edited: Date(timeIntervalSince1970: 2_111_111),
                  created: Date(timeIntervalSince1970: 1_111_111)
                 )
            ]
        let sut: EntriesListTextOnlyViewModel = List.TableViewModel(
            entries: entries,
            formatting: TerminalJJEntryFormatter()
        )

        let result = sut.parseForTableView()
        XCTAssertEqual(result.count, 3)
        XCTAssertTrue(result.allSatisfy { columns in columns.count == 1 })
        XCTAssertEqual(result.map { $0[0] }, entries.map(\.title))
    }

    func test_ColumnHeaderLabels() {
        // Immutable and Codable aspects of ParsableCommand led to a static variable workaround to reuse the table view.
        let options = List.TableViewModel.tableViewOptions
        let columns = List.TableViewModel.tableViewColumns
        XCTAssertTrue(options.capitalizeColumnHeaders)
        XCTAssertTrue(options.showColumnHeaders)
        XCTAssertEqual(columns.count, 1)
        XCTAssertEqual(columns.map(\.title), ["Title"])
    }

}
