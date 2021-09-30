////  © 2021 Ryan Ferrell. github.com/importRyan
//
//import Foundation
//@testable import InclusiveJournalCore
//
//internal typealias JournalDictionary = [IJEntry.ID : IJEntry]
//
//class PersistenceSpy: IJJournalPersisting {
//
//
//    /// Captures each persistence request in an array.
//    /// - Parameters:
//    ///   - initial: User data as if previously saved to disk/cloud
//    ///   - trackEverySave: Pass false to save memory when storing the contents of each save method call is not important to your test
//    ///
//    init(initial: JournalDictionary? = nil, trackEverySave: Bool) {
//        self.initial = initial
//        self.trackEverySave = trackEverySave
//    }
//
//    var initial: JournalDictionary? = nil
//    var saves: [JournalDictionary] = []
//    var trackEverySave: Bool
//
//    let queue = DispatchQueue(label: "com.wingovers.inclusivejournal.persistence")
//
//    func save(_ entries: JournalDictionary) {
//        guard trackEverySave else { return }
//        queue.async {
//            self.saves.append(entries)
//        }
//    }
//
//    func load() -> JournalDictionary {
//        Thread.sleep(forTimeInterval: 0.2)
//        return saves.last ?? initial ?? [:]
//    }
//
//}
