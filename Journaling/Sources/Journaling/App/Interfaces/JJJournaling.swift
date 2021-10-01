//  © 2021 Ryan Ferrell. github.com/importRyan


import Foundation

public let appIdentifier = "com.ryanferrell.journaling"

public protocol JJJournaling: AnyObject {

    init(loader: JJAppLoader, config: JJAppConfig) throws
    
    var store: JJEntriesStore { get }
    var logger: JJLogging { get }
    var formatting: JJFormatting { get }

    func start(tasksDidComplete: @escaping (Error?) -> Void)
    func appWillTerminate() -> Result<Void,Error>
}
