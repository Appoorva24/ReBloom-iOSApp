import SwiftUI
import SwiftData

@main
struct ReBloomApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([
            UserProfile.self,
            MoodLog.self,
            ExerciseLog.self,
            PartnerMission.self,
            LoveNote.self,
            Memory.self
        ])
        let config = ModelConfiguration(schema: schema)

        do {
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            
            let url = config.url
            try? FileManager.default.removeItem(at: url)
            let dir = url.deletingLastPathComponent()
            let name = url.lastPathComponent
            try? FileManager.default.removeItem(at: dir.appendingPathComponent(name + "-wal"))
            try? FileManager.default.removeItem(at: dir.appendingPathComponent(name + "-shm"))

            container = try! ModelContainer(for: schema, configurations: config)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}

