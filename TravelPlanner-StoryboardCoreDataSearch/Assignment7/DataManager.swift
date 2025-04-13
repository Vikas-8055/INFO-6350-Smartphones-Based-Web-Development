import Foundation
import CoreData
import UIKit

class DataManager {
    static let shared = DataManager()
    private init() {}

    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext


    func fetchDestinations() -> [Destination] {
        let request: NSFetchRequest<Destination> = Destination.fetchRequest()
        return (try? context.fetch(request)) ?? []
    }

    func addDestination(id: Int32, city: String, country: String) {
        let request: NSFetchRequest<Destination> = Destination.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", id)
        if let result = try? context.fetch(request), result.isEmpty {
            let destination = Destination(context: context)
            destination.id = id
            destination.city = city
            destination.country = country
            saveContext()
        }
    }

    func updateDestination(id: Int32, newCity: String) {
        let request: NSFetchRequest<Destination> = Destination.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", id)
        if let destination = try? context.fetch(request).first {
            destination.city = newCity
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

    func fetchTrips() -> [Trip] {
        let request: NSFetchRequest<Trip> = Trip.fetchRequest()
        return (try? context.fetch(request)) ?? []
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


    private func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }


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
