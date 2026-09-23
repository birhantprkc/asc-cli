import ArgumentParser

struct ReviewSubmissionsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "review-submissions",
        abstract: "Build, submit and inspect App Store review submissions (app versions plus IAP and subscription versions)",
        subcommands: [
            ReviewSubmissionsList.self,
            ReviewSubmissionsGet.self,
            ReviewSubmissionsCreate.self,
            ReviewSubmissionsSubmit.self,
            ReviewSubmissionItemsCommand.self,
        ]
    )
}
