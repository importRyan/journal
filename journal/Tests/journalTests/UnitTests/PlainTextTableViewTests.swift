//  © 2021 Ryan Ferrell. github.com/importRyan

import Foundation
import XCTest
@testable import journal

final class PlainTextTableViewTests: XCTestCase {

    // MARK: - Column Wrapping

    func test_ColumnWrapping_1Column_ViewportBreaksWords() {
        let exp1 = """
        # TITLE
        0 Imagine all the
          people
        1 A brotherhood of
          man
        2 No need for greed
          or hunger
        3 I wonder if you
          can
        4 Imagine no
          possessions

        """

        let options = Mocks.Options.zeroBasedColumnsShowingInCaps
        let columns = Mocks.Columns.makeZeroResistanceTitleOnlyColumn()
        let test    = Mocks.Input.makeSingleColumnLennonTable(reversed: true)

        let sut = PlainTextTableView(columns: columns, options: options)
        sut.layoutByColumnAndViewportConstraints(updatedTo: [], viewportWidth: 20)
        let result1 = sut.render(content: test)

            AssertMultilineStringsEqual(exp: exp1, result: result1, tolerateEndOfLineWhitespaces: true)
    }

    func test_ColumnWrapping_3Column_ViewportBreaksWords_DoesNotSTartNewLineWithCommas() {
        let exp1 = """
        # TITLE      CREATED    MODIFIED
        0 Imagine    27/02/1970 27/02/1970,
          all the    , 12:53    12:53
          people
        1 A          12/01/1970 27/02/1970,
          brotherhoo , 05:46    12:53
          d of man
        2 No need    31/12/1969 27/02/1970,
          for greed  , 16:00    12:53
          or hunger
        3 I wonder   31/12/1969 12/01/1970,
          if you can , 16:00    05:46
        4 Imagine    31/12/1969 31/12/1969,
          no         , 16:00    16:00
          possession
          s

        """

        let options = Mocks.Options.zeroBasedColumnsShowingInCaps
        let columns = Mocks.Columns.makeZeroResistanceTitleDateDateColumns()
        let test    = Mocks.Input.makeTripleColumnLennonTable(reversed: true)

        let sut = PlainTextTableView(columns: columns, options: options)
        sut.layoutByColumnAndViewportConstraints(updatedTo: [], viewportWidth: 20)
        let result1 = sut.render(content: test)

            AssertMultilineStringsEqual(exp: exp1, result: result1, tolerateEndOfLineWhitespaces: true)
    }

    func test_ColumnWrapping_1Column_BreaksOnLastSpace() {
        let exp1 = """
        # TITLE
        0 Imagine all the people
        1 A brotherhood of man
        2 No need for greed or
          hunger
        3 I wonder if you can
        4 Imagine no possessions

        """

        let options = Mocks.Options.zeroBasedColumnsShowingInCaps
        let columns = Mocks.Columns.makeZeroResistanceTitleOnlyColumn()
        let test    = Mocks.Input.makeSingleColumnLennonTable(reversed: true)

        let sut = PlainTextTableView(columns: columns, options: options)
        sut.layoutByColumnAndViewportConstraints(updatedTo: [], viewportWidth: 28)
        let result1 = sut.render(content: test)

            AssertMultilineStringsEqual(exp: exp1, result: result1, tolerateEndOfLineWhitespaces: true)
    }

    func test_ColumnWrapping_3Column_DoesNotStartNewLineWithSpaces() {
        let exp1 = """
        # TITLE       CREATED      MODIFIED
        0 Imagine     27/02/1970,  27/02/1970,
          all the     12:53        12:53
          people
        1 A           12/01/1970,  27/02/1970,
          brotherhood 05:46        12:53
          of man
        2 No need     31/12/1969,  27/02/1970,
          for greed   16:00        12:53
          or hunger
        3 I wonder    31/12/1969,  12/01/1970,
          if you can  16:00        05:46
        4 Imagine no  31/12/1969,  31/12/1969,
          possessions 16:00        16:00

        """

        let options = Mocks.Options.zeroBasedColumnsShowingInCaps
        let columns = Mocks.Columns.makeZeroResistanceTitleDateDateColumns()
        let test    = Mocks.Input.makeTripleColumnLennonTable(reversed: true)

        let sut = PlainTextTableView(columns: columns, options: options)
        sut.layoutByColumnAndViewportConstraints(updatedTo: [], viewportWidth: 40)
        let result1 = sut.render(content: test)

        AssertMultilineStringsEqual(exp: exp1, result: result1, tolerateEndOfLineWhitespaces: true)
    }

    // MARK: - Row Index & Column Labels

    func testTableView_ColumnLabels_CanBeHidden() {
        let exp1 = """
    0 R0C0 R0C1 R0C2
    1 R1C0 R1C1 R1C2

    """
        let options = PlainTextTableView.Options(
            rowLabeling: .showIndexesZeroBased,
            columnMarginWidth: 1,
            showColumnHeaders: false,
            capitalizeColumnHeaders: true)
        let columns = Mocks.Columns.makeZeroResistanceColumns(count: 3)
        let test    = Mocks.Input.makeNestedTableViewContent(rows: 2, columns: 3)

        let sut = PlainTextTableView(columns: columns, options: options)
        sut.layoutByContentSize(test)
        let result1 = sut.render(content: test)

        AssertMultilineStringsEqual(exp: exp1, result: result1, tolerateEndOfLineWhitespaces: true)
    }

    func testTableView_ColumnLabels_AppearVerbatim() {
        let exp1 = """
    # Test Test
    0 R0C0 R0C1
    1 R1C0 R1C1

    """
        let options = PlainTextTableView.Options(
            rowLabeling: .showIndexesZeroBased,
            columnMarginWidth: 1,
            showColumnHeaders: true,
            capitalizeColumnHeaders: false)
        let columns: [PlainTextTableView.Column] = [
            .init(title: "Test", minWidth: nil, initialWidth: nil, maxWidth: nil, adjustability: .fixed),
            .init(title: "Test", minWidth: nil, initialWidth: nil, maxWidth: nil, adjustability: .fixed)
        ]
        let test    = Mocks.Input.makeNestedTableViewContent(rows: 2, columns: 2)

        let sut = PlainTextTableView(columns: columns, options: options)
        sut.layoutByContentSize(test)
        let result1 = sut.render(content: test)

        AssertMultilineStringsEqual(exp: exp1, result: result1, tolerateEndOfLineWhitespaces: true)
    }

    func testTableView_RowLabels_CanBeHidden() {
        let exp1 = """
    C0   C1   C2
    R0C0 R0C1 R0C2
    R1C0 R1C1 R1C2

    """
        let options = PlainTextTableView.Options(
            rowLabeling: .noIndexes,
            columnMarginWidth: 1,
            showColumnHeaders: true,
            capitalizeColumnHeaders: false)
        let columns = Mocks.Columns.makeZeroResistanceColumns(count: 3)
        let test    = Mocks.Input.makeNestedTableViewContent(rows: 2, columns: 3)

        let sut = PlainTextTableView(columns: columns, options: options)
        sut.layoutByContentSize(test)
        let result1 = sut.render(content: test)

        AssertMultilineStringsEqual(exp: exp1, result: result1, tolerateEndOfLineWhitespaces: true)
    }

    func testTableView_RowLabels_OneIndexed() {
        let exp1 = """
    # C0   C1   C2
    1 R0C0 R0C1 R0C2
    2 R1C0 R1C1 R1C2

    """
        let options = PlainTextTableView.Options(
            rowLabeling: .showIndexesOneBased,
            columnMarginWidth: 1,
            showColumnHeaders: true,
            capitalizeColumnHeaders: false)
        let columns = Mocks.Columns.makeZeroResistanceColumns(count: 3)
        let test    = Mocks.Input.makeNestedTableViewContent(rows: 2, columns: 3)

        let sut = PlainTextTableView(columns: columns, options: options)
        sut.layoutByContentSize(test)
        let result1 = sut.render(content: test)

        AssertMultilineStringsEqual(exp: exp1, result: result1, tolerateEndOfLineWhitespaces: true)
    }

    // MARK: - Column Margins

    func testTableView_ColumnMargins_RespectedDuringResize() {
        let exp1 = """
 #     C0     C1     C2
 0     R…     R…     R0…
 1     R…     R…     R1…

 """

        let exp2 = """
 #     C0              C1              C2
 0     R0C0            R0C1            R0C2
 1     R1C0            R1C1            R1C2

 """
        let options = PlainTextTableView.Options(
            rowLabeling: .showIndexesZeroBased,
            columnMarginWidth: 5,
            showColumnHeaders: true,
            capitalizeColumnHeaders: true)
        let columns = Mocks.Columns.makeZeroResistanceColumns(count: 3)
        let test    = Mocks.Input.makeNestedTableViewContent(rows: 2, columns: 3)

        let sut = PlainTextTableView(columns: columns, options: options)
        sut.layoutByColumnAndViewportConstraints(updatedTo: [], viewportWidth: 16)

        XCTAssertEqual(sut.options.makeColumnMargin().count, 5)
        XCTAssertEqual(sut.indexColumnWidth, 2)
        XCTAssertEqual(sut.columnWidths, [2, 2, 2])
        XCTAssertEqual(sut.columns.map(\.minWidth), [2, 2, 2])
        XCTAssertEqual(sut.calculateTableWidth(), 2 + 2 * 3 + 5 * 3)

        let result1 = sut.render(content: test)
        AssertMultilineStringsEqual(exp: exp1, result: result1, tolerateEndOfLineWhitespaces: true)

        // Change viewport
        sut.layoutByColumnAndViewportConstraints(updatedTo: [], viewportWidth: 50)

        XCTAssertEqual(sut.options.makeColumnMargin().count, 5)
        XCTAssertEqual(sut.indexColumnWidth, 1)
        XCTAssertEqual(sut.columnWidths, [11, 11, 12])
        XCTAssertEqual(sut.columns.map(\.minWidth), [2, 2, 2])
        XCTAssertEqual(sut.calculateTableWidth(), 50)

        let result2 = sut.render(content: test)
        AssertMultilineStringsEqual(exp: exp2, result: result2, tolerateEndOfLineWhitespaces: true)
    }

    // MARK: - Content Truncating Layout

    func testTableView_Layout_TruncatesContent_WithColumnChanges_ObeyingColumnAdjustabilityPriorities() {
        let exp1 = """
 # SLOW  RIGID GREEDY
 0 R0C0… R0C1… R0C2V…
 1 R1C0… R1C1… R1C2V…

 """
        let exp2 = """
 # SLOW  RIGID GREEDY
 0 R0C0… R0C1… R0C2Vi…
 1 R1C0… R1C1… R1C2Vi…

 """
        let exp3 = """
 # SLOW     RIGID GREEDY
 0 R0C0Vie… R0C1… R0C2Vi…
 1 R1C0Vie… R1C1… R1C2Vi…

 """
        let options = Mocks.Options.zeroBasedColumnsShowingInCaps
        let columns1: [PlainTextTableView.Column] = [
            .init(title: "Slow", minWidth: 5, initialWidth: 6, maxWidth: 10, adjustability: .resistance(3)),
            .init(title: "Rigid", minWidth: 5, initialWidth: 5, maxWidth: 5, adjustability: .resistance(2)),
            .init(title: "Greedy", minWidth: 4, initialWidth: 6, maxWidth: 7, adjustability: .resistance(-1))
        ]
        let columns3: [PlainTextTableView.Column] = [
            .init(title: "Slow", minWidth: 5, initialWidth: 6, maxWidth: 8, adjustability: .resistance(-1)),
            .init(title: "Rigid", minWidth: 5, initialWidth: 5, maxWidth: 5, adjustability: .resistance(2)),
            .init(title: "Greedy", minWidth: 4, initialWidth: 6, maxWidth: 7, adjustability: .resistance(-1))
        ]
        let test    = Mocks.Input.makeNestedTableViewContent(rows: 2, columns: 3, extraString: "Viewport")

        let sut = PlainTextTableView(columns: columns1, options: options)
        XCTAssertEqual(sut.columnWidths, [5, 5, 4])

        sut.layoutByColumnAndViewportConstraints(updatedTo: [], viewportWidth: 20)

        XCTAssertEqual(sut.options.makeColumnMargin().count, 1)
        XCTAssertEqual(sut.indexColumnWidth, 2)
        XCTAssertEqual(sut.columnWidths, [5, 5, 5])
        XCTAssertEqual(sut.columns.map(\.minWidth), [5, 5, 4])
        XCTAssertEqual(sut.calculateTableWidth(), 5 + 5 + 5 + 2 + (1 * 3))

        let result1 = sut.render(content: test)
        AssertMultilineStringsEqual(exp: exp1, result: result1, tolerateEndOfLineWhitespaces: true)

        // Change viewport width to test adjustability
        sut.layoutByColumnAndViewportConstraints(updatedTo: [], viewportWidth: 21)

        XCTAssertEqual(sut.options.makeColumnMargin().count, 1)
        XCTAssertEqual(sut.indexColumnWidth, 1)
        XCTAssertEqual(sut.columnWidths, [5, 5, 7])
        XCTAssertEqual(sut.columns.map(\.minWidth), [5, 5, 4])
        XCTAssertEqual(sut.calculateTableWidth(), 5 + 5 + 7 + 1 + (1 * 3))

        let result2 = sut.render(content: test)
        AssertMultilineStringsEqual(exp: exp2, result: result2, tolerateEndOfLineWhitespaces: true)

        // Change viewport width + columns
        sut.layoutByColumnAndViewportConstraints(updatedTo: columns3, viewportWidth: 40)

        XCTAssertEqual(sut.options.makeColumnMargin().count, 1)
        XCTAssertEqual(sut.indexColumnWidth, 1)
        XCTAssertEqual(sut.columnWidths, [8, 5, 7])
        XCTAssertEqual(sut.columns.map(\.minWidth), [5, 5, 4])
        XCTAssertEqual(sut.calculateTableWidth(), 8 + 5 + 7 + 1 + (1 * 3))

        let result3 = sut.render(content: test)
        AssertMultilineStringsEqual(exp: exp3, result: result3, tolerateEndOfLineWhitespaces: true)
    }

    func testTableView_Layout_TruncatesContent_WithViewportChanges() {
        let exp1 = """
 # C0    C1    C2
 0 R0C0… R0C1… R0C2V…
 1 R1C0… R1C1… R1C2V…

 """
        let exp2 = """
 # C0          C1           C2
 0 R0C0Viewpo… R0C1Viewport R0C2Viewport
 1 R1C0Viewpo… R1C1Viewport R1C2Viewport

 """
        let options = Mocks.Options.zeroBasedColumnsShowingInCaps
        let columns = Mocks.Columns.makeZeroResistanceColumns(count: 3)
        let test    = Mocks.Input.makeNestedTableViewContent(rows: 2, columns: 3, extraString: "Viewport")

        let sut = PlainTextTableView(columns: columns, options: options)
        sut.layoutByColumnAndViewportConstraints(updatedTo: [], viewportWidth: 20)

        XCTAssertEqual(sut.options.makeColumnMargin().count, 1)
        XCTAssertEqual(sut.indexColumnWidth, 2)
        XCTAssertEqual(sut.columnWidths, [5, 5, 5])
        XCTAssertEqual(sut.columns.map(\.minWidth), [2, 2, 2])
        XCTAssertEqual(sut.calculateTableWidth(), 20)

        let result1 = sut.render(content: test)
        AssertMultilineStringsEqual(exp: exp1, result: result1, tolerateEndOfLineWhitespaces: true)

        // Change viewport width
        sut.layoutByColumnAndViewportConstraints(updatedTo: [], viewportWidth: 40)

        XCTAssertEqual(sut.options.makeColumnMargin().count, 1)
        XCTAssertEqual(sut.indexColumnWidth, 1)
        XCTAssertEqual(sut.columnWidths, [11, 12, 13])
        XCTAssertEqual(sut.columns.map(\.minWidth), [2, 2, 2])
        XCTAssertEqual(sut.calculateTableWidth(), 40)

        let result2 = sut.render(content: test)
        AssertMultilineStringsEqual(exp: exp2, result: result2, tolerateEndOfLineWhitespaces: true)
    }

    // MARK: - Content Fitting Layout

    func testTableView_Layout_FitsContent_1Column2Rows() {
        let exp = """
 # C0
 0 R0C0
 1 R1C0

 """
        let options = Mocks.Options.zeroBasedColumnsShowingInCaps
        let columns = Mocks.Columns.makeZeroResistanceColumns(count: 1)
        let test    = Mocks.Input.makeNestedTableViewContent(rows: 2, columns: 1)

        let sut = PlainTextTableView(columns: columns, options: options)
        sut.layoutByContentSize(test)

        XCTAssertEqual(sut.options.makeColumnMargin().count, 1)
        XCTAssertEqual(sut.indexColumnWidth, 2)
        XCTAssertEqual(sut.columnWidths, [4])
        XCTAssertEqual(sut.columns.map(\.minWidth), [2])
        XCTAssertEqual(sut.calculateTableWidth(), 4+1+2)

        let result = sut.render(content: test)
        AssertMultilineStringsEqual(exp: exp, result: result, tolerateEndOfLineWhitespaces: true)
    }

    func testTableView_Layout_FitsContent_100Columns1Row() {
        let exp = """
 # C0   C1   C2   C3   C4   C5   C6   C7   C8   C9   C10   C11   C12   C13   C14   C15   C16   C17   C18   C19   C20   C21   C22   C23   C24   C25   C26   C27   C28   C29   C30   C31   C32   C33   C34   C35   C36   C37   C38   C39   C40   C41   C42   C43   C44   C45   C46   C47   C48   C49   C50   C51   C52   C53   C54   C55   C56   C57   C58   C59   C60   C61   C62   C63   C64   C65   C66   C67   C68   C69   C70   C71   C72   C73   C74   C75   C76   C77   C78   C79   C80   C81   C82   C83   C84   C85   C86   C87   C88   C89   C90   C91   C92   C93   C94   C95   C96   C97   C98   C99
 0 R0C0 R0C1 R0C2 R0C3 R0C4 R0C5 R0C6 R0C7 R0C8 R0C9 R0C10 R0C11 R0C12 R0C13 R0C14 R0C15 R0C16 R0C17 R0C18 R0C19 R0C20 R0C21 R0C22 R0C23 R0C24 R0C25 R0C26 R0C27 R0C28 R0C29 R0C30 R0C31 R0C32 R0C33 R0C34 R0C35 R0C36 R0C37 R0C38 R0C39 R0C40 R0C41 R0C42 R0C43 R0C44 R0C45 R0C46 R0C47 R0C48 R0C49 R0C50 R0C51 R0C52 R0C53 R0C54 R0C55 R0C56 R0C57 R0C58 R0C59 R0C60 R0C61 R0C62 R0C63 R0C64 R0C65 R0C66 R0C67 R0C68 R0C69 R0C70 R0C71 R0C72 R0C73 R0C74 R0C75 R0C76 R0C77 R0C78 R0C79 R0C80 R0C81 R0C82 R0C83 R0C84 R0C85 R0C86 R0C87 R0C88 R0C89 R0C90 R0C91 R0C92 R0C93 R0C94 R0C95 R0C96 R0C97 R0C98 R0C99

 """
        let options = Mocks.Options.zeroBasedColumnsShowingInCaps
        let columns = Mocks.Columns.makeZeroResistanceColumns(count: 100)
        let test    = Mocks.Input.makeNestedTableViewContent(rows: 1, columns: 100)

        let sut = PlainTextTableView(columns: columns, options: options)
        sut.layoutByContentSize(test)

        XCTAssertEqual(sut.options.makeColumnMargin().count, 1)
        XCTAssertEqual(sut.indexColumnWidth, 2)
        XCTAssertEqual(sut.columnWidths, Array(repeating: 4, count: 10) + Array(repeating: 5, count: 90))
        XCTAssertEqual(sut.columns.map(\.minWidth), Array(repeating: 2, count: 10) + Array(repeating: 3, count: 90))
        XCTAssertEqual(sut.calculateTableWidth(), 2 + 1 + (4 * 10 + 5 * 90) + 99)

        let result = sut.render(content: test)
        AssertMultilineStringsEqual(exp: exp, result: result, tolerateEndOfLineWhitespaces: true)
    }

    func testTableView_Layout_FitsContent_3Columns0Rows() {
        let exp = """
 # C0 C1 C2

 """
        let options = Mocks.Options.zeroBasedColumnsShowingInCaps
        let columns = Mocks.Columns.makeZeroResistanceColumns(count: 3)
        let test    = Mocks.Input.makeNestedTableViewContent(rows: 0, columns: 3)

        let sut = PlainTextTableView(columns: columns, options: options)
        sut.layoutByContentSize(test)

        XCTAssertEqual(sut.options.makeColumnMargin().count, 1)
        XCTAssertEqual(sut.indexColumnWidth, 2)
        XCTAssertEqual(sut.columnWidths, [2, 2, 2])
        XCTAssertEqual(sut.columns.map(\.minWidth), [2, 2, 2])
        XCTAssertEqual(sut.calculateTableWidth(), 2+(2*3)+(1*3))

        let result = sut.render(content: test)
        AssertMultilineStringsEqual(exp: exp, result: result, tolerateEndOfLineWhitespaces: true)
    }

    func testTableView_Layout_FitsContent_WithColumnChanges() {
        let exp1 = """
 # C0
 0 R0C0
 1 R1C0
 2 R2C0

 """
        let exp2 = """
 # C0         C1
 0 R0C0Larger R0C1Larger
 1 R1C0Larger R1C1Larger
 2 R2C0Larger R2C1Larger

 """
        let options = Mocks.Options.zeroBasedColumnsShowingInCaps
        let columns1 = Mocks.Columns.makeZeroResistanceColumns(count: 1)
        let columns2 = Mocks.Columns.makeZeroResistanceColumns(count: 2)
        let test1    = Mocks.Input.makeNestedTableViewContent(rows: 3, columns: 1)
        let test2    = Mocks.Input.makeNestedTableViewContent(rows: 3, columns: 2, extraString: "Larger")

        let sut = PlainTextTableView(columns: columns1, options: options)
        sut.layoutByContentSize(test1)

        XCTAssertEqual(sut.options.makeColumnMargin().count, 1)
        XCTAssertEqual(sut.indexColumnWidth, 2)
        XCTAssertEqual(sut.columnWidths, [4])
        XCTAssertEqual(sut.columns.map(\.minWidth), [2])
        XCTAssertEqual(sut.calculateTableWidth(), 7)

        let result1 = sut.render(content: test1)
        AssertMultilineStringsEqual(exp: exp1, result: result1, tolerateEndOfLineWhitespaces: true)

        // Change columns
        sut.layoutByContentSize(test2, updating: columns2)

        XCTAssertEqual(sut.options.makeColumnMargin().count, 1)
        XCTAssertEqual(sut.indexColumnWidth, 1) // From prior render
        XCTAssertEqual(sut.columnWidths, [10, 10])
        XCTAssertEqual(sut.columns.map(\.minWidth), [2, 2])
        XCTAssertEqual(sut.calculateTableWidth(), 23)

        let result2 = sut.render(content: test2)
        AssertMultilineStringsEqual(exp: exp2, result: result2, tolerateEndOfLineWhitespaces: true)
    }

    func testTableView_Layout_FitsContent_WithColumnChanges_ObeyingColumnBounds() {
        let exp1 = """
 # C0
 0 R0C0
 1 R1C0
 2 R2C0

 """
        let exp2 = """
 # C0         C1
 0 R0C0Larger R0…
 1 R1C0Larger R1…
 2 R2C0Larger R2…

 """
        let options = Mocks.Options.zeroBasedColumnsShowingInCaps
        let columns1 = Mocks.Columns.makeZeroResistanceColumns(count: 1)
        let columns2 = columns1 + Mocks.Columns.makeFixedResistanceColumns(count: 1, maxWidth: 3, startingAt: 1)
        let test1    = Mocks.Input.makeNestedTableViewContent(rows: 3, columns: 1)
        let test2    = Mocks.Input.makeNestedTableViewContent(rows: 3, columns: 2, extraString: "Larger")

        let sut = PlainTextTableView(columns: columns1, options: options)
        sut.layoutByContentSize(test1)

        XCTAssertEqual(sut.options.makeColumnMargin().count, 1)
        XCTAssertEqual(sut.indexColumnWidth, 2)
        XCTAssertEqual(sut.columnWidths, [4])
        XCTAssertEqual(sut.columns.map(\.minWidth), [2])
        XCTAssertEqual(sut.calculateTableWidth(), 7)

        let result1 = sut.render(content: test1)
        AssertMultilineStringsEqual(exp: exp1, result: result1, tolerateEndOfLineWhitespaces: true)

        // Change columns
        sut.layoutByContentSize(test2, updating: columns2)

        XCTAssertEqual(sut.options.makeColumnMargin().count, 1)
        XCTAssertEqual(sut.indexColumnWidth, 1) // From prior render
        XCTAssertEqual(sut.columnWidths, [10, 3])
        XCTAssertEqual(sut.columns.map(\.minWidth), [2, 2])
        XCTAssertEqual(sut.calculateTableWidth(), 16)

        let result2 = sut.render(content: test2)
        AssertMultilineStringsEqual(exp: exp2, result: result2, tolerateEndOfLineWhitespaces: true)
    }

    func testTableView_HandlesRepeatedContentUpdates_RenderingCorrectly_UsingLayoutByContentSize() {
        // Base case (test again at end of updates)
        let exp1 = """
 # C0   C1   C2
 0 R0C0 R0C1 R0C2
 1 R1C0 R1C1 R1C2
 2 R2C0 R2C1 R2C2

 """
        // Adjusts index column only w/ content expansion
        let exp2 = """
 #  C0   C1   C2
 0  R0C0 R0C1 R0C2
 1  R1C0 R1C1 R1C2
 2  R2C0 R2C1 R2C2
 3  R3C0 R3C1 R3C2
 4  R4C0 R4C1 R4C2
 5  R5C0 R5C1 R5C2
 6  R6C0 R6C1 R6C2
 7  R7C0 R7C1 R7C2
 8  R8C0 R8C1 R8C2
 9  R9C0 R9C1 R9C2
 10 R10… R10… R10…

 """
        // Calling layout for content restores visibility
        let exp2B = """
 #  C0    C1    C2
 0  R0C0  R0C1  R0C2
 1  R1C0  R1C1  R1C2
 2  R2C0  R2C1  R2C2
 3  R3C0  R3C1  R3C2
 4  R4C0  R4C1  R4C2
 5  R5C0  R5C1  R5C2
 6  R6C0  R6C1  R6C2
 7  R7C0  R7C1  R7C2
 8  R8C0  R8C1  R8C2
 9  R9C0  R9C1  R9C2
 10 R10C0 R10C1 R10C2

 """
        // Calling layout for larger content
        let exp3 = """
 # C0          C1          C2
 0 R0C0Journal R0C1Journal R0C2Journal
 1 R1C0Journal R1C1Journal R1C2Journal
 2 R2C0Journal R2C1Journal R2C2Journal

 """
        let options = Mocks.Options.zeroBasedColumnsShowingInCaps
        let columns = Mocks.Columns.makeZeroResistanceColumns(count: 3)
        let test1   = Mocks.Input.makeNestedTableViewContent(rows: 3, columns: 3)
        let test2   = Mocks.Input.makeNestedTableViewContent(rows: 11, columns: 3)
        let test3   = Mocks.Input.makeNestedTableViewContent(rows: 3, columns: 3, extraString: "Journal")

        // 0 - Setup
        let sut = PlainTextTableView(columns: columns, options: options)
        sut.layoutByContentSize(test1)

        XCTAssertEqual(sut.columnWidths, [4, 4, 4])
        XCTAssertEqual(sut.indexColumnWidth, 2)


        // 1 - Render content test 1 (adjusts index column)
        let result1 = sut.render(content: test1)

        XCTAssertEqual(sut.columnWidths, [4, 4, 5])
        XCTAssertEqual(sut.indexColumnWidth, 1)
        AssertMultilineStringsEqual(exp: exp1, result: result1, tolerateEndOfLineWhitespaces: true)


        // 2 - Render content test 2 (adjusts index column only)
        let result2 = sut.render(content: test2)

        XCTAssertEqual(sut.columnWidths, [4, 4, 4])
        XCTAssertEqual(sut.indexColumnWidth, 2)
        AssertMultilineStringsEqual(exp: exp2, result: result2, tolerateEndOfLineWhitespaces: true)


        // 2B - Render content test 2 (adjusts content columns sizes)
        sut.layoutByContentSize(test2)
        let result2B = sut.render(content: test2)
        
        XCTAssertEqual(sut.columnWidths, [5, 5, 5])
        XCTAssertEqual(sut.indexColumnWidth, 2)
        AssertMultilineStringsEqual(exp: exp2B, result: result2B, tolerateEndOfLineWhitespaces: true)


        // 3 - Render expanded cell content sizes
        sut.layoutByContentSize(test3)
        let result3 = sut.render(content: test3)

        XCTAssertEqual(sut.columnWidths, [11, 11, 12])
        XCTAssertEqual(sut.indexColumnWidth, 1)
        AssertMultilineStringsEqual(exp: exp3, result: result3, tolerateEndOfLineWhitespaces: true)


        // 1B - Render first content test again (reduced cell content size)
        sut.layoutByContentSize(test1)
        let result1B = sut.render(content: test1)

        XCTAssertEqual(sut.columnWidths, [4, 4, 4])
        XCTAssertEqual(sut.indexColumnWidth, 1)
        AssertMultilineStringsEqual(exp: exp1, result: result1B, tolerateEndOfLineWhitespaces: true)
    }
}

// MARK: - Mock Setups

enum Mocks {

    enum Options {
        static let zeroBasedColumnsShowingInCaps = PlainTextTableView.Options(
            rowLabeling: .showIndexesZeroBased,
            columnMarginWidth: 1,
            showColumnHeaders: true,
            capitalizeColumnHeaders: true
        )
    }

    enum Input {
        static func makeNestedTableViewContent(rows: Int, columns: Int, extraString: String = "") -> [[String]] {
            let baseRow = (0..<columns).map { "C\($0)" }
            let cells = (0..<rows).map { rowNumber in
                baseRow.map { column in "R\(rowNumber)\(column)\(extraString)" }
            }
            return cells
        }

        static func makeSingleColumnLennonTable(reversed: Bool) -> [[String]] {
            let lyrics = [
                "Imagine no possessions",
                "I wonder if you can",
                "No need for greed or hunger",
                "A brotherhood of man",
                "Imagine all the people",
            ]
            let asEntries = reversed ? lyrics.reversed() : lyrics
            return asEntries.map { [$0] }
        }

        static func makeTripleColumnLennonTable(reversed: Bool) -> [[String]] {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            formatter.locale = Locale(identifier: "en_GB")
            let seventies = formatter.string(from: Date(timeIntervalSince1970: 0))
            let later = formatter.string(from: Date(timeIntervalSince1970: 1_000_000))
            let evenLater = formatter.string(from: Date(timeIntervalSince1970: 5_000_000))
            let lyrics = [
                ["Imagine no possessions", seventies, seventies],
                ["I wonder if you can", seventies, later],
                ["No need for greed or hunger", seventies, evenLater],
                ["A brotherhood of man", later, evenLater],
                ["Imagine all the people", evenLater, evenLater]
            ]
            return reversed ? lyrics.reversed() : lyrics
        }
    }

    enum Columns {

        static func makeZeroResistanceTitleOnlyColumn() -> [PlainTextTableView.Column] {
            [.init(
                title: "Title",
                minWidth: 10, initialWidth: nil, maxWidth: nil,
                adjustability: .resistance(0),
                wrap: .wrapInsideColumn
            )]
        }

        static func makeZeroResistanceTitleDateDateColumns() -> [PlainTextTableView.Column] {
            [.init(
                title: "Title",
                minWidth: 10, initialWidth: nil, maxWidth: nil,
                adjustability: .resistance(0),
                wrap: .wrapInsideColumn
            ),
             .init(
                 title: "Created",
                 minWidth: 10, initialWidth: nil, maxWidth: nil,
                 adjustability: .resistance(0),
                 wrap: .wrapInsideColumn
             ),
             .init(
                 title: "Modified",
                 minWidth: 10, initialWidth: nil, maxWidth: nil,
                 adjustability: .resistance(0),
                 wrap: .wrapInsideColumn
             )
            ]
        }

        static func makeZeroResistanceColumns(count: Int, startingAt: Int = 0) -> [PlainTextTableView.Column] {
            (startingAt..<count).map {
                .init(title: "C\($0)",
                      minWidth: nil,
                      initialWidth: nil,
                      maxWidth: nil,
                      adjustability: .resistance(0))
            }
        }

        static func makeFixedResistanceColumns(count: Int, maxWidth: Int?, startingAt: Int = 0) -> [PlainTextTableView.Column] {
            (startingAt..<count + startingAt).map {
                .init(title: "C\($0)",
                      minWidth: nil,
                      initialWidth: nil,
                      maxWidth: maxWidth,
                      adjustability: .fixed)
            }
        }
    }
}
