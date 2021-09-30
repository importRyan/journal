//  © 2021 Ryan Ferrell. github.com/importRyan


import Foundation

public protocol JournalingApp: AnyObject {

    init(loader: AppLoader, config: AppConfig) throws
    
    var store: JournalEntryStore { get }
    var logger: Logging { get }
    var formatting: JJFormatting { get }

    func start(tasksDidComplete: @escaping (Error?) -> Void)
    func exit(tasksDidComplete: @escaping (Error?) -> Void)
}

public let appIdentifier = "com.ryanferrell.journaling"
