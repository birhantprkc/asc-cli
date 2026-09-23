import ArgumentParser

struct IAPVersionsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "versions",
        abstract: "List review versions of an in-app purchase (add a submittable one to a review submission)",
        subcommands: [IAPVersionsList.self]
    )
}
