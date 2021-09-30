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
        public func format(_ date: Date) -> String {
            TerminalJJEntryFormatter.Dates.abbreviatedDateTimeFormatter.string(from: date)
        }

        static fileprivate(set) var abbreviatedDateTimeFormatter: DateFormatter = {
            var formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter
        }()
    }

    struct Titles: JJTitleFormatting {
        public func format(_ title: String) -> String {
            title.isEmpty ? "[Untitled]" : title
        }
    }
}
