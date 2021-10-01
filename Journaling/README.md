# Journaling

The core components and contracts for the app include:
`JJournaling` - Root app object, coordinates start and exit sequences.
`JJAppLoader` and `JJConfig` — Inject concrete instances and launch settings
`JJEntriesStore` - In-memory store of journal entries
`JJEntry` - Journal entry model
`JJFormatting` — Formatters for entry contents
`JJPersisting`, `JJLogging` — As named

The concrete implementation `ConcurrentJournalStore` uses a concurrent DispatchQueue and barrier flags on write to protect its dictionary of entries. Mocks for persistence and app loading are used for testing behavior without hitting the disk.


# JournalingPersistence

The `LocalPersistenceManager` saves user data to a directory preference, which currently is:
```
~/Desktop/Journal/UserData 
```

## Data format

Entries are saved as JSON data wrapped in a versioning container (`EntrySaveContainer` and various `JJEntryDTO`). 

These containers attempt to decode themselves recursively in a "singly linked list" of `JJEntryDTO` associated types, bubbling up any terminating error. If updating from very old versions, this approach is expensive and a versioning sentinel could be used to provide intermediate entry points. 

File names reflect the `JJEntry` identifiers (UUIDs) and some basic provision is made to recover from and communicate an ID collision via `PersistingErrorHandlingDelegate`.


## Save method

The `FileWrapper` API is used to minimize disk use (if thinking ahead to a more complex UI) and coalesces bursts of save requests into one save action per second. 

App termination triggers a write of any remaining updates. A "write only mode" for commands like --create will skip parsing the data of a directory's entry files. 


## Testing

The manager is tested behaviorally by injecting a spy `FileWrapper` and logger.
