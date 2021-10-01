//  © 2021 Ryan Ferrell. github.com/importRyan


import Foundation
import Journaling

internal extension JJJournalLibraryLocation {

    static let localAppDirectoryName = "Journal"
    static let librarySubfolderName = "UserData"

    func getAppUserDataFolder() throws -> URL {
        let fm = FileManager.default
        guard let url = self.localURLs().first else {
            throw JJLocalPersistenceError.chosenDirectoryNotReachable
        }

        let appDirectoryName = Self.localAppDirectoryName
        let libraryDirectoryName = Self.librarySubfolderName
        let libraryURL = url
            .appendingPathComponent(appDirectoryName, isDirectory: true)
            .appendingPathComponent(libraryDirectoryName, isDirectory: true)

        var pathIsDirectory = ObjCBool(false)
        if !fm.fileExists(atPath: libraryURL.path, isDirectory: &pathIsDirectory) {
            try fm.createDirectory(at: libraryURL, withIntermediateDirectories: true, attributes: nil)
        }

        return libraryURL
    }

    func localURLs() -> [URL] {
        FileManager.default.urls(for: self.localSearchPath, in: .userDomainMask)
    }

    var localSearchPath: FileManager.SearchPathDirectory {
        switch self {
            case .desktop: return .desktopDirectory
        }
    }
}
