import SwiftUI
import SwiftData

@main
struct ReBloomApp: App {
    let container: ModelContainer
    
    // Services
    @State private var authManager = AuthManager()
    @State private var connectionManager: ConnectionManager
    @State private var syncManager: SyncManager

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
        
        // Initialize services with dependencies
        let auth = AuthManager()
        let conn = ConnectionManager(authManager: auth)
        let sync = SyncManager(authManager: auth)
        
        _authManager = State(initialValue: auth)
        _connectionManager = State(initialValue: conn)
        _syncManager = State(initialValue: sync)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authManager)
                .environment(connectionManager)
                .environment(syncManager)
        }
        .modelContainer(container)
    }
}
