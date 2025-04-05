import Foundation
import CoreData
import UIKit

class DataManager {
    static let shared = DataManager()
    private init() {}
    
    private let baseURL = "https://67ea0dbfbdcaa2b7f5bac9fc.mockapi.io/shravan/"
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    // MARK: - Network Operations
    private func fetchFromAPI<T: Codable>(endpoint: String, completion: @escaping (Result<[T], Error>) -> Void) {
        let fullURL = baseURL + endpoint
        print("Attempting to fetch from: \(fullURL)")  // This will show the exact URL being called
        
        guard let url = URL(string: fullURL) else {
            print("Invalid URL constructed: \(fullURL)")
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -2, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let decodedData = try JSONDecoder().decode([T].self, from: data)
                completion(.success(decodedData))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Sync Methods
    func syncDestinations(completion: @escaping (Bool, Error?) -> Void) {
        fetchFromAPI(endpoint: "destination") { [weak self] (result: Result<[APIDestination], Error>) in
            guard let self = self else { return }
            
            switch result {
            case .success(let apiDestinations):
                self.context.perform {
                    do {
                        print("Syncing destinations from API")
                        // Get existing destinations
                        let existingDestinations = try self.context.fetch(Destination.fetchRequest()) as! [Destination]
                        
                        // Update or create
                        for apiDest in apiDestinations {
                            if let existing = existingDestinations.first(where: { $0.id == apiDest.id }) {
                                // Update existing
                                existing.city = apiDest.city
                                existing.country = apiDest.country
                                existing.pictureURL = apiDest.pictureURL
                            } else {
                                // Create new
                                let newDest = Destination(context: self.context)
                                newDest.id = apiDest.id
                                newDest.city = apiDest.city
                                newDest.country = apiDest.country
                                newDest.pictureURL = apiDest.pictureURL
                            }
                        }
                        
                        try self.context.save()
                        print("Saved \(apiDestinations.count) destinations to Core Data")
                        completion(true, nil)
                    } catch {
                        completion(false, error)
                    }
                }
                
            case .failure(let error):
                completion(false, error)
            }
        }
    }
    
    func syncTrips(completion: @escaping (Bool, Error?) -> Void) {
        fetchFromAPI(endpoint: "trips") { [weak self] (result: Result<[APITrip], Error>) in
            guard let self = self else { return }
            
            switch result {
            case .success(let apiTrips):
                self.context.perform {
                    do {
                        // Get existing trips and destinations
                        let existingTrips = try self.context.fetch(Trip.fetchRequest()) as! [Trip]
                        let existingDestinations = try self.context.fetch(Destination.fetchRequest()) as! [Destination]
                        
                        // Update or create
                        for apiTrip in apiTrips {
                            if let existing = existingTrips.first(where: { $0.id == apiTrip.id }) {
                                // Update existing
                                existing.title = apiTrip.title
                                existing.startDate = apiTrip.startDate
                                existing.endDate = apiTrip.endDate
                                
                                // Find and set destination
                                if let destination = existingDestinations.first(where: { $0.id == apiTrip.destinationID }) {
                                    existing.destination = destination
                                }
                            } else {
                                // Create new
                                let newTrip = Trip(context: self.context)
                                newTrip.id = apiTrip.id
                                newTrip.title = apiTrip.title
                                newTrip.startDate = apiTrip.startDate
                                newTrip.endDate = apiTrip.endDate
                                newTrip.destinationID = apiTrip.destinationID
                                
                                // Find and set destination
                                if let destination = existingDestinations.first(where: { $0.id == apiTrip.destinationID }) {
                                    newTrip.destination = destination
                                }
                            }
                        }
                        
                        try self.context.save()
                        completion(true, nil)
                    } catch {
                        completion(false, error)
                    }
                }
                
            case .failure(let error):
                completion(false, error)
            }
        }
    }
    // MARK: - Destination
    func fetchDestinations() -> [Destination] {
        let request: NSFetchRequest<Destination> = Destination.fetchRequest()
        do {
            print("fetching destinations: \(request)")
            return try context.fetch(request)
        } catch {
            print("Error fetching destinations: \(error)")
            return []
        }
    }

    func addDestination(id: Int32, city: String, country: String, pictureURL: String) {
        let request: NSFetchRequest<Destination> = Destination.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", id)
        if let result = try? context.fetch(request), result.isEmpty {
            let destination = Destination(context: context)
            destination.id = id
            destination.city = city
            destination.country = country
            destination.pictureURL = pictureURL
            saveContext()
        }
    }

    func updateDestination(id: Int32, newCity: String, newImage: String) {
        let request: NSFetchRequest<Destination> = Destination.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", id)
        if let destination = try? context.fetch(request).first {
            destination.city = newCity
            destination.pictureURL = newImage
            saveContext()
        }
    }

    func deleteDestination(id: Int32) -> Bool {
        let request: NSFetchRequest<Destination> = Destination.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", id)
        if let destination = try? context.fetch(request).first {
            let linkedTrips = fetchTrips().filter { $0.destinationID == id }
            if !linkedTrips.isEmpty {
                return false
            }
            context.delete(destination)
            saveContext()
            return true
        }
        return false
    }

    // MARK: - Trip
    func fetchTrips() -> [Trip] {
        let request: NSFetchRequest<Trip> = Trip.fetchRequest()
        do {
            print("fetching trips: \(request)")
            return try context.fetch(request)
        } catch {
            print("Error fetching trips: \(error)")
            return []
        }
    }

    func addTrip(id: Int32, destinationID: Int32, title: String, startDate: String, endDate: String) {
        let request: NSFetchRequest<Trip> = Trip.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", id)
        if let result = try? context.fetch(request), result.isEmpty {
            let trip = Trip(context: context)
            trip.id = id
            trip.destinationID = destinationID
            trip.title = title
            trip.startDate = startDate
            trip.endDate = endDate
            saveContext()
        }
    }

    func updateTrip(id: Int32, newTitle: String, newEndDate: String) {
        let request: NSFetchRequest<Trip> = Trip.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", id)
        if let trip = try? context.fetch(request).first {
            trip.title = newTitle
            trip.endDate = newEndDate
            saveContext()
        }
    }

    func deleteTrip(id: Int32) -> Bool {
        let request: NSFetchRequest<Trip> = Trip.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", id)
        if let trip = try? context.fetch(request).first {
            let linkedActivities = fetchActivities().filter { $0.trip_id == id }
            let linkedExpenses = fetchExpenses().filter { $0.trip_id == id }
            if !linkedActivities.isEmpty || !linkedExpenses.isEmpty {
                return false
            }
            context.delete(trip)
            saveContext()
            return true
        }
        return false
    }

    // MARK: - Activity
    func fetchActivities() -> [Activity] {
        let request: NSFetchRequest<Activity> = Activity.fetchRequest()
        return (try? context.fetch(request)) ?? []
    }

    func addActivity(id: Int32, tripId: Int32, name: String, date: String, time: String, location: String) {
        let request: NSFetchRequest<Activity> = Activity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", id)
        if let result = try? context.fetch(request), result.isEmpty {
            let activity = Activity(context: context)
            activity.id = id
            activity.trip_id = tripId
            activity.name = name
            activity.date = date
            activity.time = time
            activity.location = location
            saveContext()
        }
    }

    func updateActivity(id: Int32, newName: String, newDate: String, newTime: String, newLocation: String) {
        let request: NSFetchRequest<Activity> = Activity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", id)
        if let activity = try? context.fetch(request).first {
            activity.name = newName
            activity.date = newDate
            activity.time = newTime
            activity.location = newLocation
            saveContext()
        }
    }

    func deleteActivity(id: Int32) -> Bool {
        let request: NSFetchRequest<Activity> = Activity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", id)
        if let activity = try? context.fetch(request).first {
            if !isActivityDeletable(date: activity.date ?? "", time: activity.time ?? "") {
                print("Cannot delete past activity.")
                return false
            }
            context.delete(activity)
            saveContext()
            return true
        }
        return false
    }

    // MARK: - Expense
    func fetchExpenses() -> [Expense] {
        let request: NSFetchRequest<Expense> = Expense.fetchRequest()
        return (try? context.fetch(request)) ?? []
    }

    func addExpense(id: Int32, tripId: Int32, title: String, amount: Double, date: String) {
        let request: NSFetchRequest<Expense> = Expense.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", id)
        if let result = try? context.fetch(request), result.isEmpty {
            let expense = Expense(context: context)
            expense.id = id
            expense.trip_id = tripId
            expense.title = title
            expense.amount = amount
            expense.date = date
            saveContext()
        }
    }

    func updateExpense(id: Int32, newTitle: String, newAmount: Double, newDate: String) {
        let request: NSFetchRequest<Expense> = Expense.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", id)
        if let expense = try? context.fetch(request).first {
            expense.title = newTitle
            expense.amount = newAmount
            expense.date = newDate
            saveContext()
        }
    }

    func deleteExpense(id: Int32) -> Bool {
        let request: NSFetchRequest<Expense> = Expense.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", id)
        if let expense = try? context.fetch(request).first {
            if !isExpenseDeletable(date: expense.date ?? "") {
                print("Cannot delete expense older than 30 days.")
                return false
            }
            context.delete(expense)
            saveContext()
            return true
        }
        return false
    }

    // MARK: - Save
    private func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }

    // MARK: - Validation
    private func isActivityDeletable(date: String, time: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd hh:mm a"
        if let activityDate = formatter.date(from: "\(date) \(time)") {
            return activityDate > Date()
        }
        return false
    }

    private func isExpenseDeletable(date: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let expenseDate = formatter.date(from: date) else { return true }
        let days = Calendar.current.dateComponents([.day], from: expenseDate, to: Date()).day ?? 0
        return days <= 30
    }
}
