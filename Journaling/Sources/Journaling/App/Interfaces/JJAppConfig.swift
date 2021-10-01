//  © 2021 Ryan Ferrell. github.com/importRyan


import Foundation

public protocol JJAppConfig {
    var journalLocation: JJJournalLibraryLocation { get }
    var loadEntries: JJEntryLoadingMode { get }
    var formatting: JJEntryFormatting { get }
}

// MARK: - Model

public enum JJEntryLoadingMode {
    case immediatelyLoadUserEntryLibrary
    case writeOnlyMode
}

public enum JJJournalLibraryLocation {
    case desktop
}

// MARK: - Configurations

public struct JJDevelopmentConfig: JJAppConfig {

    public let loadEntries: JJEntryLoadingMode = .immediatelyLoadUserEntryLibrary
    public let formatting: JJEntryFormatting
    public let journalLocation: JJJournalLibraryLocation

    public init(formatting: JJEntryFormatting,
                journal: JJJournalLibraryLocation = .desktop) {
        self.formatting = formatting
        self.journalLocation = journal
    }
}

public struct JJAddEntriesOnlyDevelopmentConfig: JJAppConfig {

    public let loadEntries: JJEntryLoadingMode = .writeOnlyMode
    public let formatting: JJEntryFormatting
    public let journalLocation: JJJournalLibraryLocation

    public init(formatting: JJEntryFormatting,
                journal: JJJournalLibraryLocation = .desktop) {
        self.formatting = formatting
        self.journalLocation = journal
    }
}
