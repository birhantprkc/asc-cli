import ArgumentParser

struct ExperimentsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "experiments",
        abstract: "Manage product page optimization tests (App Store version experiments)",
        subcommands: [
            ExperimentsList.self,
            ExperimentsGet.self,
            ExperimentsCreate.self,
            ExperimentsUpdate.self,
            ExperimentsStart.self,
            ExperimentsStop.self,
            ExperimentsDelete.self,
        ]
    )
}

struct ExperimentTreatmentsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "experiment-treatments",
        abstract: "Manage treatments (product page variants) of a product page optimization test",
        subcommands: [
            ExperimentTreatmentsList.self,
            ExperimentTreatmentsCreate.self,
            ExperimentTreatmentsUpdate.self,
            ExperimentTreatmentsDelete.self,
        ]
    )
}

struct ExperimentTreatmentLocalizationsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "experiment-treatment-localizations",
        abstract: "Manage the locales included in a treatment",
        subcommands: [
            ExperimentTreatmentLocalizationsList.self,
            ExperimentTreatmentLocalizationsCreate.self,
            ExperimentTreatmentLocalizationsDelete.self,
        ]
    )
}
