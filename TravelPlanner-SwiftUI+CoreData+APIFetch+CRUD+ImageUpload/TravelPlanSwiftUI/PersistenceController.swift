import CoreData

struct PersistenceController {
    // Singleton instance for app-wide usage
    static let shared = PersistenceController()

    // Preview instance for SwiftUI previews (uses in-memory storage)
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext
        // Add sample data for preview if needed
        return controller
    }()

    let container: NSPersistentContainer

    // Initializer for both in-memory and on-device configurations
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "DataModel")
        
        // Configure persistent storage
        if inMemory {
            // Use in-memory store for previews and testing
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Enable lightweight migration (auto migration)
            if let description = container.persistentStoreDescriptions.first {
                description.shouldMigrateStoreAutomatically = true
                description.shouldInferMappingModelAutomatically = true
            }
        }
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                // Handle persistent store loading errors
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            print("Persistent store loaded: \(storeDescription.url?.absoluteString ?? "Unknown location")")
        }
    }
}
