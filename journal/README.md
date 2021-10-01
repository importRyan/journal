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


## Dependencies

Command line interaction is coordinated via Apple's ArgumentParser library, which uses reflection on wrapped properties to make and parse a tree of commands with type safety guarantees. 

Some downsides the library are pertinent at larger scales than the current context. Reflection parsing takes some computation, for example. Binary size is also somewhat larger, particularly in Debug mode.

A local fork of Argument Parser is linked to this app. The fork adds support for subcommand aliases (I am preparing a PR for issue #248) and pads help prompts with an extra line of padding to personal taste.

[ArgumentParser](https://github.com/apple/swift-argument-parser)
[Enhancement Issue 248](https://github.com/apple/swift-argument-parser/issues/248)
[My Fork](https://github.com/importRyan/swift-argument-parser/commits/commandAliasing)

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
