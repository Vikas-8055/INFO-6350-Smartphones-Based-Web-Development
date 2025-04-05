import UIKit
import CoreData
import Network
import BackgroundTasks // Add this import

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private let monitor = NWPathMonitor()
    private let apiQueue = DispatchQueue(label: "com.yourcompany.YourAppName.apiMonitor")

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Configure network monitoring
        setupNetworkMonitoring()
        
        // Initial data sync
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.attemptInitialSync()
        }
        
        return true
    }

    // MARK: - Network Monitoring
    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            let isReachable = path.status == .satisfied
            print("Network reachability changed: \(isReachable)")
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .networkReachabilityChanged,
                    object: nil,
                    userInfo: ["reachable": isReachable]
                )
                
                if isReachable {
                    self?.attemptDataSync()
                } else {
                    self?.showAlert(message: "Please check your Data")
                }
            }
        }
        monitor.start(queue: apiQueue)
    }
    
    private func showAlert(message: String) {
        DispatchQueue.main.async {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = scene.windows.first,
                  let rootViewController = window.rootViewController else { return }
            
            let alert = UIAlertController(title: "Network Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            
            rootViewController.present(alert, animated: true, completion: nil)
        }
    }


    
    // MARK: - Data Sync
    private func attemptInitialSync() {
        if monitor.currentPath.status == .satisfied {
            attemptDataSync()
        }
    }
    
    private func attemptDataSync() {
        DataManager.shared.syncDestinations { [weak self] success, error in
            if success {
                DataManager.shared.syncTrips { _, _ in
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .dataDidUpdate, object: nil)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .dataDidUpdate, object: nil)
                }
            }
        }
    }

    // MARK: - Core Data Stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "CoreData")
        
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("No persistent store descriptions found")
        }
        
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                print("Core Data load error: \(error)")
                self.handleCoreDataError(error)
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.handleRemoteChange(_:)),
            name: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator
        )
        
        return container
    }()
    
    @objc private func handleRemoteChange(_ notification: Notification) {
        print("Received remote Core Data change notification")
    }
    
    private func handleCoreDataError(_ error: NSError) {
        // Implement your error recovery strategy
        print("Unresolved Core Data error: \(error)")
    }
    
    // Add this method to handle app coming to foreground
    func applicationWillEnterForeground(_ application: UIApplication) {
        attemptDataSync()
    }

    // MARK: - Core Data Saving
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Core Data save error: \(nsError)")
                context.rollback()
            }
        }
    }
}

// Add this extension at the bottom of AppDelegate.swift
extension Notification.Name {
    static let dataDidUpdate = Notification.Name("DataDidUpdate")
    static let networkReachabilityChanged = Notification.Name("NetworkReachabilityChanged")
}
