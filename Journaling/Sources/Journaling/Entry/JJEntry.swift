import Foundation

public struct JJEntry: Equatable, Hashable {

    public typealias ID = UUID

    public private(set) var id: ID
    public private(set) var title: String
    public private(set) var content: String
    public private(set) var dateCreated: Date
    public private(set) var dateEdited: Date

    public init(id: JJEntry.ID = .init(),
                title: String,
                content: String,
                edited: Date = Date(),
                created: Date = Date()) {
        self.id = id
        self.title = title
        self.content = content
        self.dateEdited = edited
        self.dateCreated = created
    }
}

public extension JJEntry {

    /// Edits an entry, automatically updating the last edit date.
    /// - Parameters:
    ///   - title: Replaces existing title. Pass nil to skip editing.
    ///   - content: Replaces existing content. Pass nil to skip editing.
    ///
    mutating func update(title: String? = nil, content: String? = nil) {
        if let newTitle = title {
            self.title = newTitle
        }
        if let newContent = content {
            self.content = newContent
        }
        if title != nil || content != nil {
            dateEdited = Date()
        }
    }
}

