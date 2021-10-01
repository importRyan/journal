//  © 2021 Ryan Ferrell. github.com/importRyan


import Foundation

public protocol AppConfig {
    var journalLocation: JournalLibraryLocation { get }
    var loadEntries: EntryLoadingMode { get }
    var formatting: JJEntryFormatting { get }
}

// MARK: - Model

public enum EntryLoadingMode {
    case immediatelyLoadUserEntryLibrary
    case writeOnlyMode
}

public enum JournalLibraryLocation {
    case desktop
}

// MARK: - Configurations

public struct DevelopmentConfig: AppConfig {

    public let loadEntries: EntryLoadingMode = .immediatelyLoadUserEntryLibrary
    public let formatting: JJEntryFormatting
    public let journalLocation: JournalLibraryLocation

    public init(formatting: JJEntryFormatting,
                journal: JournalLibraryLocation = .desktop) {
        self.formatting = formatting
        self.journalLocation = journal
    }
}

public struct AddOnlyDevelopmentConfig: AppConfig {

    public let loadEntries: EntryLoadingMode = .writeOnlyMode
    public let formatting: JJEntryFormatting
    public let journalLocation: JournalLibraryLocation

    public init(formatting: JJEntryFormatting,
                journal: JournalLibraryLocation = .desktop) {
        self.formatting = formatting
        self.journalLocation = journal
    }
}
