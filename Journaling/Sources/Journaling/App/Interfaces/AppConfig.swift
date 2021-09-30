//  © 2021 Ryan Ferrell. github.com/importRyan


import Foundation

public protocol AppConfig {
    var loadEntries: EntryLoadingMode { get }
    var formatting: JJEntryFormatting { get }
}

// MARK: - Model

public enum EntryLoadingMode {
    case immediatelyLoadUserEntryLibrary
    case writeOnlyMode
}

// MARK: - Configurations

public struct DevelopmentConfig: AppConfig {
    public init(formatting: JJEntryFormatting) {
        self.formatting = formatting
    }
    public let loadEntries: EntryLoadingMode = .immediatelyLoadUserEntryLibrary
    public let formatting: JJEntryFormatting
}

public struct AddOnlyDevelopmentConfig: AppConfig {
    public init(formatting: JJEntryFormatting) {
        self.formatting = formatting
    }
    public let loadEntries: EntryLoadingMode = .writeOnlyMode
    public let formatting: JJEntryFormatting
}
