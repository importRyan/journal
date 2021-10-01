import XCTest
import ArgumentParser

// MARK: - New methods

public extension XCTestCase {

    /// Test a command is executed and the process exits before a time limit (default: 3 seconds). Includes a wall clock expectation.
    func AssertExecuteCommand(
        command: String,
        expected: String? = nil,
        exitCodes: [ExitCode] = [.success],
        waitForExpectations: [XCTestExpectation] = [],
        maximumRunTime: TimeInterval = 3,
        includeErrorOutput: Bool,
        file: StaticString = #file, line: UInt = #line)
    {
        let splitCommand = command.split(separator: " ")
        let arguments = splitCommand.dropFirst().map(String.init)

        let commandName = String(splitCommand.first!)
        let commandURL = debugURL.appendingPathComponent(commandName)
        guard (try? commandURL.checkResourceIsReachable()) ?? false else {
            XCTFail("No executable at '\(commandURL.standardizedFileURL.path)'.",
                    file: (file), line: line)
            return
        }

        let process = Process()
        if #available(macOS 10.13, *) {
            process.executableURL = commandURL
        } else {
            process.launchPath = commandURL.path
        }
        process.arguments = arguments

        let output = Pipe()
        process.standardOutput = output
        let error = Pipe()
        process.standardError = error

        let doesExitByMaximumWaitTime = expectation(description: "Program terminates itself.")
        process.terminationHandler = { process in
            doesExitByMaximumWaitTime.fulfill()
        }

        if #available(macOS 10.13, *) {
            guard (try? process.run()) != nil else {
                XCTFail("Couldn't run command process.", file: (file), line: line)
                return
            }
        } else {
            process.launch()
        }
        wait(for: [doesExitByMaximumWaitTime], timeout: maximumRunTime)
        let status = Int(process.terminationStatus)
        process.terminate()

        let outputData = output.fileHandleForReading.readDataToEndOfFile()
        let outputActual = String(data: outputData, encoding: .utf8)!.trimmingCharacters(in: .whitespacesAndNewlines)

        let errorData = error.fileHandleForReading.readDataToEndOfFile()
        let errorActual = String(data: errorData, encoding: .utf8)!.trimmingCharacters(in: .whitespacesAndNewlines)

        let combinedOutput = includeErrorOutput ? errorActual + outputActual : outputActual

        if let expected = expected {
            AssertEqualStringsIgnoringTrailingWhitespace(expected, combinedOutput, file: file, line: line)
        }

        XCTAssertTrue(exitCodes.map { Int($0.rawValue) }.contains(status),
                      "Process terminated with code \(status)", file: (file), line: line)
    }

    /// Test the process exits before a time limit (default: 3 seconds). Includes a wall clock expectation. Does not evaluate outputs.
    func AssertExecuteCommand(
        command: String,
        exitCodes: [ExitCode] = [.success],
        maximumRunTime: TimeInterval = 3,
        file: StaticString = #file, line: UInt = #line)
    {
        let splitCommand = command.split(separator: " ")
        let arguments = splitCommand.dropFirst().map(String.init)

        let commandName = String(splitCommand.first!)
        let commandURL = debugURL.appendingPathComponent(commandName)
        guard (try? commandURL.checkResourceIsReachable()) ?? false else {
            XCTFail("No executable at '\(commandURL.standardizedFileURL.path)'.",
                    file: (file), line: line)
            return
        }

        let process = Process()
        if #available(macOS 10.13, *) {
            process.executableURL = commandURL
        } else {
            process.launchPath = commandURL.path
        }
        process.arguments = arguments

        let output = Pipe()
        process.standardOutput = output
        let error = Pipe()
        process.standardError = error

        let doesExitByMaximumWaitTime = expectation(description: "Program terminates itself.")
        process.terminationHandler = { process in
            doesExitByMaximumWaitTime.fulfill()
        }

        if #available(macOS 10.13, *) {
            guard (try? process.run()) != nil else {
                XCTFail("Couldn't run command process for: \(command)", file: file, line: line)
                return
            }
        } else {
            process.launch()
        }
        wait(for: [doesExitByMaximumWaitTime], timeout: maximumRunTime)
        process.terminate()

        XCTAssertTrue(exitCodes.map(\.rawValue).contains(process.terminationStatus), "Command: \(command) Code: \(process.terminationStatus)", file: file, line: line)
    }
}

// MARK: - Temporarily Customized

public func AssertEqualStringsIgnoringTrailingWhitespace(_ string1: String, _ string2: String, file: StaticString = #file, line: UInt = #line) {
    let lines1 = string1.split(separator: "\n", omittingEmptySubsequences: false)
    let lines2 = string2.split(separator: "\n", omittingEmptySubsequences: false)

    XCTAssertEqual(lines1.count, lines2.count, "Strings have different numbers of lines.", file: (file), line: line)
    if lines1.endIndex != lines2.endIndex || string1 != string2 {
        print("---ACTUAL---")
        print(string2)
        print("---EXPECTED---")
        print(string1)
    }
    for (line1, line2) in zip(lines1, lines2) {
        XCTAssertEqual(line1.trimmed(), line2.trimmed(), file: (file), line: line)
    }
}
