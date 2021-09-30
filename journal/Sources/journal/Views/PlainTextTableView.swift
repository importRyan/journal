//  © 2021 Ryan Ferrell. github.com/importRyan


import Foundation

/// Formats input of rows, with equal column counts, into a terminal-style String.
///
///
/// Calling `render` wraps or truncates text into columns based on
/// cached layout information.
///
/// Prior to calling render, call a `layout` to establish column guides.
/// Two methods layout based on intrinsic content size or only column
/// constraints. If content or columns cannot compress into a specified
/// viewport width, the minimum allowable layout width will be used.
///
/// Subsequent `render` calls will reuse previous column guides. However,
/// when set to display row numbers, if the new content's row count differs
/// enough to change the width of the row index column, the most flexible
/// columns will resize to accommodate the larger or smaller index column.
/// (You can also call `layoutByColumnAndViewportConstraints` to ensure column
/// sizes do not change.)
///
/// - Warning: A runtime error will occur:
///  * if no columns exist
///  * if column width constraints overlap
///  * if content is provided with rows with mismatched column counts.
///
/// **Right-to-Left Languages**
/// Layout resizing is designed for left-to-right languages.
///
public class PlainTextTableView: Codable {

    public private(set) var columns: [Column]
    public private(set) var options: Options

    /// Cached layout information
    private var indicesOfColumnsSortedByCompression: [SortedColumnIndex]
    internal typealias SortedColumnIndex = Int

    /// Constrained column Character widths
    public private(set) var columnWidths: [CharacterWidth]
    public private(set) var indexColumnWidth: CharacterWidth
    public typealias CharacterWidth = Int

    public init(columns: [Column], options: Options) {
        precondition(!columns.isEmpty, Error.minimumOneColumn.localizedDescription)
        self.columns = columns
        self.options = options
        self.columnWidths = columns.map { $0.minWidth ?? 0 }
        self.indexColumnWidth = options.rowLabeling.defaultWidth
        self.indicesOfColumnsSortedByCompression = Self.getIndicesSortedByCompression(of: columns)
    }
}

// MARK: - API

public extension PlainTextTableView {

    /// Counts current column layout widths and margin spacing
    func calculateTableWidth() -> CharacterWidth {
        let base = indexColumnWidth + options.calculateColumnMarginsTotalWidth(for: columns.endIndex)
        return columnWidths.reduce(base, +)
    }

    /// Attempts to expand or contract non-fixed columns to fit
    /// the desired screen width, obeying any column constraints.
    /// Right-most columns are changed before left-most columns of
    /// equal adjustability ranking.
    func layoutByColumnAndViewportConstraints(updatedTo newColumns: [Column] = [], viewportWidth: CharacterWidth) {
        if !newColumns.isEmpty { restartColumnConfiguration(newColumns) }
        let change = viewportWidth - calculateTableWidth()
        adjustLayoutForWidthChange(change)
    }

    /// Expands or contracts columns (within constraints) to fit the content
    /// provided, regardless of screen width.
    func layoutByContentSize(_ content: [[String]], updating newColumns: [Column] = []) {
        if !newColumns.isEmpty { restartColumnConfiguration(newColumns) }
        precondition(content.allSatisfy({ $0.endIndex == columns.endIndex }), Error.columnCountMismatch.localizedDescription)

        // Measure maximum content widths, starting with any enforced minimums
        var contentColumnMaxWidths = columns.map { $0.minWidth ?? 0 }
        for row in content {
            for columnIndex in row.indices {

                // Check if content size is longer than current column width
                let contentLength = row[columnIndex].count
                let currentWidth = contentColumnMaxWidths[columnIndex]
                guard contentLength > currentWidth else { continue }

                // Do not exceed any enforced maximums
                if let columnMax = columns[columnIndex].maxWidth {
                    contentColumnMaxWidths[columnIndex] = min(contentLength, columnMax)
                } else {
                    contentColumnMaxWidths[columnIndex] = contentLength
                }
            }
        }
        columnWidths = contentColumnMaxWidths
    }

    /// Renders content based on existing layout information and column content wrapping preferences.
    /// - Parameter content: Outer: Rows. Inner: Columns.
    /// - Returns: Multiline string with layout best matching requirements, but possibly narrower or wider than desired if its contents cannot compress or expand further.
    func render(content: [[String]]) -> String {
        precondition(content.allSatisfy({ $0.endIndex == columns.endIndex }), Error.columnCountMismatch.localizedDescription)

        // Update layout for row indexing, if used.
        let change = rowIndexesColumnWidthWillChange(rows: content.endIndex)
        adjustLayoutForWidthChange(-change) // Opposite sign


        var tableBase = ""
        if options.showColumnHeaders {
            tableBase = makeColumnHeaders()
        }

        // Offset: Row number. Element: array of columns in the row.
        let renderedContent = content.enumerated().map { row -> String in

            // Outer: column. Inner: Lines of wrapped cell contents, fit to column length.
            var wrappedCells = [[String]]()

            // A Include the row label column
            if options.rowLabeling.shouldShow {
                addRowLabel(offset: row.offset, to: &wrappedCells)
            }
            // B Loop over each column in a row, rendering text into a
            //   truncated line or an array of wrapped lines of a fixed length.
            applyWrappingOrTruncationToCells(inRowColumnContents: row.element, wrappedCells: &wrappedCells)

            // C Write cells line by line, making indentations
            //   if one column has fewer lines than others do.
            let row = makeMultilineStringRowFrom(wrappedCells)

            // D Write row into the rendered table
            return row
        }

        return tableBase + renderedContent.joined(separator: "")
    }

}

// MARK: - Private Rendering Methods

private extension PlainTextTableView {

    func addRowLabel(offset: Int, to wrappedCells: inout [[String]]) {
        let rowIndexLabel = String(offset + options.rowLabeling.startIndex).fitted(to: indexColumnWidth)
        wrappedCells.append([rowIndexLabel])
    }

    func makeColumnHeaders() -> String {
        // Outer: Columns. Inner: Lines of wrapped cells.
        var wrappedHeaderRowCells = [[String]]()

        if options.rowLabeling.shouldShow {
            let column = "#".fitted(to: indexColumnWidth)
            wrappedHeaderRowCells.append([column])
        }
        applyWrappingOrTruncationToCells(inRowColumnContents: columns.map(\.title), wrappedCells: &wrappedHeaderRowCells)
        let rendered = makeMultilineStringRowFrom(wrappedHeaderRowCells)
        return options.capitalizeColumnHeaders ? rendered.uppercased() : rendered
    }
}

private extension PlainTextTableView {

    /// Wrap or truncate cells into fixed-length rows.
    /// - Parameters:
    ///   - columnsInRow: Each column in this row forms a "cell"
    ///   - wrappedCells: Outer: column. Inner: Lines of wrapped cell contents.
    func applyWrappingOrTruncationToCells(inRowColumnContents: [String], wrappedCells: inout [[String]]) {

        // Iterate over each column
        for (columnIndex, columnContent) in inRowColumnContents.enumerated() {
            let width = columnWidths[columnIndex]

            // Just truncate, if required, into a single-member array
            guard columns[columnIndex].wrap == .wrapInsideColumn else {
                let line = columnContent.fitted(to: width, truncationMarker: .ellipsis)
                wrappedCells.append([line])
                continue
            }

            // Wrapped substrings, possibly shorter than required
            var wrappedCellLines = [Substring]()
            var index = columnContent.startIndex
            while index < columnContent.endIndex {
                var span = columnContent[index...].prefix(width)

                // Trim whitespaces from front of line
                while columnContent[span.startIndex].isWhitespace && !span.isEmpty {
                    span = columnContent[columnContent.index(after: span.startIndex)...].prefix(width)
                }

                // If span includes or its last character is a line break,
                // implement that break.
                if let breakIndex = span.firstIndex(where: { $0.isNewline }) {
                    wrappedCellLines.append(columnContent[index..<breakIndex])
                    index = columnContent.index(after: breakIndex)
                }

                // If end of content, stop
                else if span.endIndex == columnContent.endIndex {
                    guard !span.isEmpty else { break } // Don't add empty line
                    wrappedCellLines.append(span)
                    index = columnContent.endIndex
                }

                // If landed in middle of word, try to break to last available space
                else if span.last?.isWhitespace == false,
                        let spaceIndex = span.lastIndex(where: { $0.isWhitespace }),
                        spaceIndex != span.startIndex {

                    wrappedCellLines.append(span[..<spaceIndex])
                    index = columnContent.index(after: spaceIndex)
                }

                // If landed on a space or in the middle of word
                // (w/o a preceding space in the span),
                // just wrap (no hyphenation)
                else {
                    wrappedCellLines.append(span)
                    index = span.endIndex
                }
            }

            // Expand length of wrapped lines to the required width
            let fixedWidthCellLines = wrappedCellLines.map { String($0).fitted(to: width) }
            wrappedCells.append(fixedWidthCellLines)
        }
    }

    /// Combine a row's multi-line columns into a multiline string, incorporating margin spacing.
    /// - Parameter wrappedCells: Columns including index column. Outer: columns. Inner: cell lines.
    /// - Returns: String not ending in \n
    func makeMultilineStringRowFrom(_ wrappedCells: [[String]]) -> String {
        let columnMargin = options.makeColumnMargin()
        var rowLines = ""
        var lineWrapIndex = 0
        let lineWrapsInCells = wrappedCells.reduce(into: 0) { result, cell in result = max(result, cell.endIndex) }
        while lineWrapIndex < lineWrapsInCells { // i.e., is valid index

            // Loop through every column
            for i in wrappedCells.indices {

                // Check for content (i.e., line is present in cell), otherwise use indentation
                var cell = wrappedCells[i].indices.contains(lineWrapIndex)
                ? wrappedCells[i][lineWrapIndex]
                : String(repeating: " ", count: getColumnWidth(forColumnIndexAccountingForPossibleColumnOfRowIndexes: i))

                // Append column margin, except to last column
                if i != wrappedCells.endIndex - 1 {
                    cell.append(columnMargin)
                }

                // Add line fragment
                rowLines.append(cell)
            }

            // Advance to next line
            if lineWrapIndex != lineWrapsInCells { rowLines.append("\n") }
            lineWrapIndex += 1
        }
        return rowLines
    }

    func getColumnWidth(forColumnIndexAccountingForPossibleColumnOfRowIndexes i: Int) -> CharacterWidth {
        options.rowLabeling.shouldShow
        ? (i == 0 ? indexColumnWidth : columnWidths[i - 1])
        : columnWidths[i]
    }

}

// MARK: - Layout Methods

private extension PlainTextTableView {

    /// Adjust `columnWidths` based on column adjustability,
    /// with equal priority columns being equally adjusted.
    ///  Contraction is negative.
    func adjustLayoutForWidthChange(_ change: Int) {
        guard change != 0 else { return }

        var changeRemaining = change
        let step = change.signum()
        // Position in `indicesOfColumnsSortedByCompression`
        var i = 0

        func columnIndex(atSortedPosition: Int = i) -> Int {
            indicesOfColumnsSortedByCompression[atSortedPosition]
        }

        func column(atSortedPosition: Int = i) -> Column {
            columns[columnIndex(atSortedPosition: atSortedPosition)]
        }

    layout:
        while changeRemaining != 0 && i < indicesOfColumnsSortedByCompression.endIndex {

            // If column cannot adjust, stop (as is sorted by most adjustable)
            guard column().canAdjustWidth else { break layout }

            // Queue of i positions
            var queue = [Int]()

            // Gather any columns with the same priority
            queue.append(i)
            while i + 1 < columns.endIndex, column(atSortedPosition: i + 1).adjustability == column().adjustability {
                i += 1
                queue.append(i)
            }
            i += 1 // Ensure an index isn't hit twice on another loop
            queue.reverse() // Adjust rightmost columns first to maximize visual stability

            // Adjust columns in queue equally
            while !queue.isEmpty {

                // Remove any unavailable options
                switch step {
                    case -1: queue.removeAll { position in
                        let limit = column(atSortedPosition: position).minWidth ?? 0
                        let currentWidth = columnWidths[columnIndex(atSortedPosition: position)]
                        return currentWidth <= limit
                    }
                    case 1: queue.removeAll { position in
                        let limit = column(atSortedPosition: position).maxWidth ?? Int.max
                        let currentWidth = columnWidths[columnIndex(atSortedPosition: position)]
                        return currentWidth >= limit
                    }
                    default: assertionFailure("Step should be non-zero")
                }

                // Apply one step of adjustment, unless done adjusting
                for position in queue {
                    guard changeRemaining != 0 else { break layout }
                    columnWidths[columnIndex(atSortedPosition: position)] += step
                    changeRemaining -= step
                }
            }
        }
    }

    func restartColumnConfiguration(_ newColumns: [Column]) {
        self.columns = newColumns
        self.columnWidths = columns.map { $0.minWidth ?? 0 }
        self.indicesOfColumnsSortedByCompression = Self.getIndicesSortedByCompression(of: newColumns)
    }

    func rowIndexesColumnWidthWillChange(rows: Int) -> Int {
        guard options.rowLabeling.shouldShow else { return 0 }

        let newCount = String(rows).count
        let change = newCount - indexColumnWidth
        guard change != 0 else { return 0 }
        indexColumnWidth = newCount
        return change
    }

    static func getIndicesSortedByCompression(of columns: [Column]) -> [SortedColumnIndex] {
        columns.enumerated().sorted(by: { $0.element.adjustability < $1.element.adjustability }).map(\.offset)
    }

    // Any columns without a specified minimum or initial width will be set to zero width.
    static func getInitialColumnWidthsArray(for columns: [Column]) -> [CharacterWidth] {
        columns.map { max($0.minWidth ?? 0, $0.initialWidth ?? 0) }
    }
}

// MARK: - API Components

public extension PlainTextTableView {

    struct Options: Codable {
        public let rowLabeling: RowLabeling
        public let columnMarginWidth: Int
        public let showColumnHeaders: Bool
        public let capitalizeColumnHeaders: Bool

        public init(rowLabeling: PlainTextTableView.Options.RowLabeling, columnMarginWidth: Int, showColumnHeaders: Bool, capitalizeColumnHeaders: Bool) {
            self.rowLabeling = rowLabeling
            self.columnMarginWidth = columnMarginWidth
            self.showColumnHeaders = showColumnHeaders
            self.capitalizeColumnHeaders = capitalizeColumnHeaders
        }

        internal func makeColumnMargin() -> String {
            String(repeating: " ", count: columnMarginWidth)
        }

        internal func calculateColumnMarginsTotalWidth(for columns: Int) -> Int {
            let addRowLabelingColumn = rowLabeling.shouldShow ? 1 : 0
            return max(0, columns - 1 + addRowLabelingColumn) * columnMarginWidth
        }

        public enum RowLabeling: Codable {
            case noIndexes
            case showIndexesOneBased
            case showIndexesZeroBased

            public var startIndex: Int {
                self == .showIndexesOneBased ? 1 : 0
            }

            public var defaultWidth: Int {
                self.shouldShow ? 2 : 0
            }

            public var shouldShow: Bool { self != .noIndexes }
        }
    }

    struct Column: Codable {
        public let title: String
        public let minWidth: Int?
        public let initialWidth: Int?
        public let maxWidth: Int?
        public let adjustability: Adjustability
        public var wrap: WrappingOptions

        public var canAdjustWidth: Bool { adjustability != .fixed }

        /// If minimum width is not specified, adopts the title's length as the minimum width.
        public init(title: String, minWidth: Int?, initialWidth: Int?, maxWidth: Int?, adjustability: PlainTextTableView.Column.Adjustability, wrap: WrappingOptions = .truncateInsideColumn) {
            self.title = title
            self.minWidth = minWidth == nil ? title.count : minWidth
            self.initialWidth = initialWidth
            self.maxWidth = maxWidth
            self.adjustability = adjustability
            self.wrap = wrap
            do { try validateWidths() }
            catch { PlainTextTableView.report(error: error) }
        }

        /// Low adjustment resistance columns are resized before others during a layout pass
        public enum Adjustability: Codable {
            case fixed
            case resistance(Int)
        }

        public enum WrappingOptions: Codable {
            case wrapInsideColumn
            case truncateInsideColumn
        }

        private func validateWidths() throws {
            if let min = minWidth {
                let isValid = min <= (initialWidth ?? min) && min <= (maxWidth ?? min)
                guard isValid else { throw Error.invalidMinWidth }
            }

            if let max = maxWidth {
                let isValid = max >= (initialWidth ?? max) && max >= (minWidth ?? max)
                guard isValid else { throw Error.invalidMaxWidth }
            }

            if let initial = initialWidth {
                let isValid = initial >= (minWidth ?? initial) && initial <= (maxWidth ?? initial)
                guard isValid else { throw Error.invalidInitialWidth }
            }
        }
    }

}

extension PlainTextTableView.Column.Adjustability: Comparable {
    public static func <(lhs: PlainTextTableView.Column.Adjustability, rhs: PlainTextTableView.Column.Adjustability) -> Bool {
        switch (lhs, rhs) {
            case (.fixed, .fixed): return true
            case (_, .fixed): return true
            case (.fixed, _): return false
            case (.resistance(let left), .resistance(let right)): return left < right
        }
    }
}

// MARK: - Quick Error Handling

public extension PlainTextTableView {

    static func report(error: Swift.Error) {
        app.logger.log(error: error)
    }

    enum Error: String, Swift.Error {
        case invalidMinWidth = "Minimum width is less than or equal to other widths."
        case invalidMaxWidth = "Maximum width is more than or equal to other widths."
        case invalidInitialWidth = "Initial width is in between or equal to other widths."
        case columnCountMismatch = "Every table row must contain all columns."
        case minimumOneColumn = "Has at least one column."

        public var localizedDescription: String { rawValue }
    }
}
