//  © 2021 Ryan Ferrell. github.com/importRyan


import Foundation
import Journaling
import Combine

internal typealias AddAction = (data: Data, name: String, collisionRevisedName: String)
internal typealias WriteAction = (url: URL, filenames: [String])
internal typealias RemovalAction = FileWrapper

internal class FileWrapperSpy: FileWrapper {

    // Mutate live state
    var doesMatchContentsOfAnyURLProvided = false

    // Setup
    var allowSystemWrites: Bool
    var useProvidedWrappersOnly: Bool

    // Logged info
    let originalChildWrappers: [String:FileWrapper]
    var mutatedOriginalChildWrappers: [String:FileWrapper]
    var addedFiles: [AddAction] = []
    var writes: [WriteAction] = []
    var removals: [RemovalAction] = []
    var matchContentsChecks: [URL] = []
    var keyMismatches = 0

    var didWrite: CurrentValueSubject<WriteAction, Never> = .init((URL(fileURLWithPath: ""),[]))
    var didAdd: CurrentValueSubject<AddAction, Never> = .init((Data(), "", ""))
    var didRemove: CurrentValueSubject<RemovalAction, Never> = .init(.init())

    var countDiskWritesPerformed: Int { writes.endIndex }
    var countMutationsToWrappers: Int { addedFiles.endIndex + removals.endIndex }
    var countContentsMatches: Int { matchContentsChecks.endIndex }

    // Spy methods
    func replaceFileWrappers(with new: [String:FileWrapper]) {
        mutatedOriginalChildWrappers = new
    }

    // Overridden methods for spying
    override func removeFileWrapper(_ child: FileWrapper) {
        removals.append(child)
        mutatedOriginalChildWrappers.removeValue(forKey: getKeyForChild(child))
        didRemove.send(child)
        if !useProvidedWrappersOnly {
            super.removeFileWrapper(child)
        }
    }

    override func matchesContents(of url: URL) -> Bool {
        matchContentsChecks.append(url)
        if useProvidedWrappersOnly {
            return doesMatchContentsOfAnyURLProvided
        } else {
            return super.matchesContents(of: url)
        }
    }

    override func addRegularFile(withContents data: Data, preferredFilename fileName: String) -> String {

        func getCollisionName() -> String {
            if useProvidedWrappersOnly {
                return mutatedOriginalChildWrappers[fileName] == nil
                ? fileName
                : JJEntry.ID.init().uuidString
            } else {
                return super.addRegularFile(withContents: data, preferredFilename: fileName)
            }
        }

        let collisionName = getCollisionName()
        let newWrapper = FileWrapper(regularFileWithContents: data)
        newWrapper.preferredFilename = collisionName

        mutatedOriginalChildWrappers[collisionName] = newWrapper
        let action = (data, fileName, collisionName)
        addedFiles.append(action)
        didAdd.send(action)
        return collisionName
    }

    override func write(to url: URL, options: FileWrapper.WritingOptions = [], originalContentsURL: URL?) throws {
        if self.isDirectory {
            let children = fileWrappers ?? [:]
            let action = (url, children.map(\.key))
            writes.append(action)
            didWrite.send(action)
        } else {
            let action = (url, [preferredFilename ?? ""])
            writes.append(action)
            didWrite.send(action)
        }

        guard allowSystemWrites else { return }
        try super.write(to: url, options: options, originalContentsURL: originalContentsURL)
    }

    private func getKeyForChild(_ child: FileWrapper) -> String {
        let key = self.keyForChildFileWrapper(child) ?? child.preferredFilename
        guard let key = key else { keyMismatches += 1; return "" }
        return key
    }

    init(directory: URL, childWrappers: [String:FileWrapper], allowSystemWrites: Bool, useProvidedWrappersOnly: Bool) {
        self.originalChildWrappers = childWrappers
        self.mutatedOriginalChildWrappers = childWrappers
        self.allowSystemWrites = allowSystemWrites
        self.useProvidedWrappersOnly = useProvidedWrappersOnly
        super.init(directoryWithFileWrappers: childWrappers)
    }

    required init?(coder inCoder: NSCoder) { fatalError("") }
}
