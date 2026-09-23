import ArgumentParser

struct SubscriptionGroupVersionsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "versions",
        abstract: "List review versions of a subscription group (add a submittable one to a review submission)",
        subcommands: [SubscriptionGroupVersionsList.self]
    )
}
