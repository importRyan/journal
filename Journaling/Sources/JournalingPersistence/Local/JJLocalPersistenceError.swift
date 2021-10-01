//  © 2021 Ryan Ferrell. github.com/importRyan


import Foundation

public enum JJLocalPersistenceError: Error {
    case chosenDirectoryNotReachable
    case directoryContentsReadError
    case parsingFailedForDTO(String)
    case unableToParse(file: String, error: Error?)
    case unexpectedItemInUserDirectory(String)
    case persistenceServiceUnavailable
    case namingCollision(String)

    public var localizedDescription: String {
        switch self {
            case .chosenDirectoryNotReachable: return "Unable to access the selected library folder."
            case .directoryContentsReadError: return "Library folder contents could not be read."
            case .unableToParse(let file, let error): return "\(file) could not be read. Reason: \(error?.localizedDescription ?? "none")"
            case .parsingFailedForDTO(let dto):return "Parsing failed at \(dto)."
            case .unexpectedItemInUserDirectory(let file): return "Unexpected item in user directory \(file)"
            case .persistenceServiceUnavailable: return "Persistence service unavailable."
            case .namingCollision(let name): return "Filename collision \(name)"
        }
    }
}

