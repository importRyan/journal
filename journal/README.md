# journal

## Usage

To create and store a new journal entry:
```
./journal --create "Contents of a new journal entry" --title "Title of entry"
```

To list journal entries stored by the application:
```
./journal --list
```

## About

Command line interactions use Apple's ArgumentParser library, which reflects wrapped properties to create a tree of commands with type safety guarantees. It also offers typo suggestions based on edit distance.*

As some recompense for using a dependency, a local fork of Argument Parser is linked to this app. The fork adds support for subcommand aliases (I am preparing a PR for issue #248) and pads help prompts with an extra line of padding to personal taste.

[Fork](https://github.com/importRyan/swift-argument-parser/commits/commandAliasing)
[Enhancement Issue 248](https://github.com/apple/swift-argument-parser/issues/248)
[ArgumentParser](https://github.com/apple/swift-argument-parser)

`journal` starts by calling `.main()` on a ParsableCommand that acts as a router, forwarding relevant parsed arguments. The destination ParsableCommand acts like both an AppDelegate and ViewController in coordinating user input, model output to a table view, and configuring some aspects of the app's launch. A `PlainTextTableView` handles constraint-based column layout and in-column text wrapping.

To ensure async disk writes finish before the process terminates, the RunLoop is held open. Serial and concurrent queues run the persistent and in-memory model data stores, respectively. App exit schedules itself first behind any in-memory store writes to ensure any edits reach the persistent store. (For a command line app this simple, non-synchronous design is rather comical, maybe deleterious. It may be relevant for a UI layer with more expensive features and opportunities for race conditions.)

The persistent store writes entries as separate JSON files inside versioned containers, which recursively try to decode older containers by a "singly linked list" of associate types. A list of objects in the non-UI portion are in the `Journaling` package readme.

* Some downsides of the library are pertinent at larger scales than the current context. Reflection parsing takes some computation, for example. Binary size is also somewhat larger, particularly in Debug mode.


## Assignment Requirements

1. There should be a way to record a new journal entry with a title.
2. The user should be able to view a list of the titles of all of the entries that the user has stored in the app.
3. The app should also have some way to persist journal entries. For example, saving them as JSON in a simple text file.
4. Command line app should adhere to the interface in `Usage`

## Clarifications Made

1. No view entry command or follow-up prompt in --list
2. No export feature

## Features and Functionality Interviewers May Later Require

1. Showing a list of entries, sorted based on certain criteria (date, title, ascending, descending)
2. Searching the list of entries and returning a filtered list based on certain criteria
3. Deleting entries
4. Consideration for testing plans or adding tests
5. A design component
