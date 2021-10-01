//  © 2021 Ryan Ferrell. github.com/importRyan


import Foundation
import os

public class JJSystemLogger {

    public var sessionEvents: [JJLoggedEvent] = []
    public var sessionErrors: [JJLoggedEvent] = []

    private let logger: Logger

    public init(label: String = "Journaling") {
        self.logger = Logger(subsystem: appIdentifier, category: label)
    }
}

extension JJSystemLogger: JJLogging {

    public func log(event: String, priority: JJLoggedEvent.Priority = .informational) {
        logger.log(level: priority.oslog, "\(event)")
        #if DEBUG
        sessionEvents.append(.init(priority: priority, message: event))
        #endif
    }

    public func log(error: Error, priority: JJLoggedEvent.Priority = .criticalError) {
        logger.log(level: priority.oslog, "\(error.localizedDescription)")
        #if DEBUG
        sessionErrors.append(.init(error: error, priority: priority))
        #endif
    }
}

fileprivate extension JJLoggedEvent.Priority {
    var oslog: OSLogType {
        switch self {
            case .systemFault: return .fault
            case .criticalError: return .error
            case .debugging: return .debug
            case .informational: return .info
        }
    }
}
