import ArgumentParser

struct AppsPricePointsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "price-points",
        abstract: "List the prices an app can be sold at in a territory",
        subcommands: [AppsPricePointsList.self]
    )
}
