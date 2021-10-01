//  © 2021 Ryan Ferrell. github.com/importRyan

import Foundation
import Journaling

public struct TerminalJJEntryFormatter: JJEntryFormatting {
    public var id: JJEntryIDFormatting = IDs()
    public var date: JJDateFormatting = Dates()
    public var title: JJTitleFormatting = Titles()
}

public extension TerminalJJEntryFormatter {

    struct IDs: JJEntryIDFormatting {
        public func format(_ id: JJEntry.ID) -> String {
            id.uuidString
        }
    }

    struct Dates: JJDateFormatting {

        var abbreviatedDateTimeFormatter: DateFormatter = {
            var formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter
        }()

        public func format(_ date: Date) -> String {
            abbreviatedDateTimeFormatter.string(from: date)
        }

    }

    struct Titles: JJTitleFormatting {
        public func format(_ title: String) -> String {
            title.isEmpty ? "[Untitled]" : title
        }
    }
}
