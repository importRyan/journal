//  © 2021 Ryan Ferrell. github.com/importRyan


import Foundation

public protocol AppConfig {
    var loadEntries: EntryLoadingMode { get }
}

// MARK: - Model

public enum EntryLoadingMode {
    case immediatelyLoadUserEntryLibrary
    case writeOnlyMode
}

// MARK: - Configurations

public struct DevelopmentConfig: AppConfig {
    public init() { }
    public let loadEntries: EntryLoadingMode = .immediatelyLoadUserEntryLibrary
}

public struct AddOnlyDevelopmentConfig: AppConfig {
    public init() { }
    public let loadEntries: EntryLoadingMode = .writeOnlyMode
}
