import ArgumentParser

struct SubscriptionVersionsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "versions",
        abstract: "List review versions of a subscription (add a submittable one to a review submission)",
        subcommands: [SubscriptionVersionsList.self]
    )
}
