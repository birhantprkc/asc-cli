import ArgumentParser

struct ReviewSubmissionItemsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "items",
        abstract: "Add, remove and inspect the items in a review submission (find which item Apple rejected)",
        subcommands: [ReviewSubmissionItemsList.self, ReviewSubmissionItemsAdd.self, ReviewSubmissionItemsRemove.self]
    )
}
