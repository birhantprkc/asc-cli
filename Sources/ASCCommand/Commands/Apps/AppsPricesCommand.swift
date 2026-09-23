import ArgumentParser

struct AppsPricesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "prices",
        abstract: "Set an app's price",
        subcommands: [AppsPricesSet.self]
    )
}
