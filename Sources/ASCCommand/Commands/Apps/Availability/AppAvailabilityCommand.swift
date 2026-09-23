import ArgumentParser

struct AppAvailabilityCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "app-availability",
        abstract: "Manage app territory availability",
        subcommands: [
            AppAvailabilityGet.self,
            AppAvailabilityCreate.self,
        ],
        defaultSubcommand: AppAvailabilityGet.self
    )
}
