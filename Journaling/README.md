# Journaling



# JournalingPersistence

Provides one implementation of the `Persisting` protocol: a `LocalPersistenceManager` that saves user data to a preferred directory. For simplicity right now, that is:
```
~/Desktop/Journal/UserData 
```

## Data format

Entries are saved as JSON data wrapped in a versioning container (`EntrySaveContainer` and various `JJEntryDTO`). 

These containers attempt to decode themselves recursively in a "singly linked list" of `JJEntryDTO` associated types, bubbling up any terminating error. If updating from very old versions, this approach is expensive and a versioning sentinel could be used to provide intermediate entry points. 

File names reflect the `JJEntry` identifiers (UUIDs) and some basic provision is made to recover from and communicate ID collision via `PersistingErrorHandlingDelegate`.


## Save method

The implemented `LocalPersistenceManager` uses the `FileWrapper` API to minimize disk use and coalesces bursts of save requests into one save action per second. 

App termination can cancel the queue and then writes any remaining updates. It has a "write only mode" for commands like --create, which skips parsing the data of a directory's entry files. 

All activity is dispatched to an internal serial queue.


## Testing

The manager is tested behaviorally by injecting a spy `FileWrapper` and logger.
