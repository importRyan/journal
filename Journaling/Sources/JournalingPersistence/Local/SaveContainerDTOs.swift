//  © 2021 Ryan Ferrell. github.com/importRyan


import Foundation
import Journaling

struct EntrySaveContainer: Codable {
    let versionSentinel: Int
    let data: Data

    /// Encode
    init(entry: JJEntry, encoder: JSONEncoder) throws {
        self.versionSentinel = LatestDTO.versionSentinel
        self.data = try LatestDTO.encodeJJEntry(entry, json: encoder)
    }

    static func encode(entry: JJEntry, with encoder: JSONEncoder) throws -> Data {
        try encoder.encode(self.init(entry: entry, encoder: encoder))
    }

    /// Decode
    init(fileData: Data, _ decoder: JSONDecoder) throws {
        self = try decoder.decode(EntrySaveContainer.self, from: fileData)
    }

    func parse(using decoder: JSONDecoder) throws -> JJEntry {
        guard let dto = try LatestDTO(data: data, json: decoder)
        else { throw LocalPersistenceError.parsingFailedForDTO("\(LatestDTO.self)") }
        return dto.makeJJEntry()
    }
}

// MARK: - Entry DTO Protocol

// For ease of model changes on Monday, this approach recursively finds a
// decodable object, converting the older model at each node. This sacrifices
// runtime efficiency for having to write less code.
//
// A real application opening legacy files could balance speed and verbosity
// by using the `versionSentinel` to enter this linked list at different nodes.
//
protocol JJEntryDTO: Codable {
    associatedtype PreviousDTO: JJEntryDTO
    init?(data: Data, json: JSONDecoder) throws
}

// MARK: - Latest Model-to-DTO-to-Model Conversions

typealias LatestDTO = EntryDTO1
extension LatestDTO {
    static let versionSentinel = 1

    func makeJJEntry() -> JJEntry {
        .init(
            id: self.id,
            title: self.title,
            content: self.content,
            edited: self.dateEdited,
            created: self.dateCreated
        )
    }

    static func encodeJJEntry(_ model: JJEntry, json: JSONEncoder) throws -> Data {
        let dto = self.init(
            id: model.id,
            title: model.title,
            content: model.content,
            dateCreated: model.dateCreated,
            dateEdited: model.dateEdited
        )
        return try json.encode(dto)
    }
}

// MARK: - DTO-to-DTO Conversions

internal struct EntryDTO1: JJEntryDTO {

    typealias PreviousDTO = EntryDTO1

    public let id: UUID
    public private(set) var title: String
    public private(set) var content: String
    public private(set) var dateCreated: Date
    public private(set) var dateEdited: Date

    init?(data: Data, json: JSONDecoder) throws {
        guard let current = try? json.decode(Self.self, from: data) else {
            guard Self.self != PreviousDTO.self,
                  let previous = try PreviousDTO(data: data, json: json)
            else { throw LocalPersistenceError.parsingFailedForDTO("\(Self.self)") }

            self.id = previous.id
            self.title = previous.title
            self.content = previous.content
            self.dateEdited = previous.dateEdited
            self.dateCreated = previous.dateCreated
            return
        }
        self = current
    }

    internal init(id: UUID, title: String, content: String, dateCreated: Date, dateEdited: Date) {
        self.id = id
        self.title = title
        self.content = content
        self.dateCreated = dateCreated
        self.dateEdited = dateEdited
    }
}
