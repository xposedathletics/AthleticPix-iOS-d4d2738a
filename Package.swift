// swift-tools-version: 5.9
import PackageDescription
 
let package = Package(
    name: "AthletixPro",
    platforms: [.iOS(.v17), .macOS(.v12)],
    targets: [
        .executableTarget(
            name: "AthletixPro",
            path: "Sources",
            sources: [
                "App/AthletixProApp.swift",
                "Brand/Brand.swift",
                "Config/SportConfig.swift",
                "Models/Models.swift",
                "Models/DrillDatabase.swift",
                "Engine/PlanEngine.swift",
                "Engine/AthleteStore.swift",
                "Engine/TechManager.swift",
                "Session/TrainingSession.swift",
                "Views/ContentRoot.swift",
                "Views/HomeView.swift",
                "Views/SportsPositionFlow.swift",
                "Views/ActivesSession.swift",
                "Views/CompleteView.swift"
            ]
        )
    ]
)
