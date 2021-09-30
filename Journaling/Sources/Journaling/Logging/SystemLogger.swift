//  © 2021 Ryan Ferrell. github.com/importRyan


import Foundation
import os

public class SystemLogger {

    public var sessionEvents: [LoggedEvent] = []
    public var sessionErrors: [LoggedEvent] = []

    private let logger: Logger

    public init(label: String = "Journaling") {
        self.logger = Logger(subsystem: appIdentifier, category: label)
    }
}

extension SystemLogger: Logging {

    public func log(event: String, priority: LoggedEvent.Priority = .informational) {
        logger.log(level: priority.oslog, "\(event)")
        #if DEBUG
        sessionEvents.append(.init(priority: priority, message: event))
        #endif
    }

    public func log(error: Error, priority: LoggedEvent.Priority = .criticalError) {
        logger.log(level: priority.oslog, "\(error.localizedDescription)")
        #if DEBUG
        sessionErrors.append(.init(error: error, priority: priority))
        #endif
    }
}

fileprivate extension LoggedEvent.Priority {
    var oslog: OSLogType {
        switch self {
            case .systemFault: return .fault
            case .criticalError: return .error
            case .debugging: return .debug
            case .informational: return .info
        }
    }
}
