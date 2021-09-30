//  © 2021 Ryan Ferrell. github.com/importRyan


import Foundation
import os

public protocol Logging: AnyObject {
    var sessionEvents: [LoggedEvent] { get }
    var sessionErrors: [LoggedEvent] { get }
    func log(error: Error, priority: LoggedEvent.Priority)
    func log(event: String, priority: LoggedEvent.Priority)
}

public extension Logging {
    func log(error: Error, _ priority: LoggedEvent.Priority = .criticalError) {
        log(error: error, priority: priority)
    }

    func log(event: String, _ priority: LoggedEvent.Priority = .informational) {
        log(event: event, priority: priority)
    }
}


// MARK: - Model

public struct LoggedEvent: Hashable, Equatable, Codable {
    public let priority: Priority
    public let message: String
    public let time: Date

    public init(priority: Priority, message: String, time: Date = Date()) {
        self.message = message
        self.time = time
        self.priority = priority
    }

    public init(error: Error, priority: Priority = .criticalError, time: Date = Date()) {
        self.priority = priority
        self.message = error.localizedDescription
        self.time = time
    }

    public enum Priority: Int, Equatable, Codable {
        case informational
        case debugging
        case criticalError
        case systemFault
    }
}
