import Foundation

class DataManager {
    static let shared = DataManager()
    
    private init() {}

    var destinations: [Destination] = [
        Destination(id: 1, city: "London", country: "UK"),
        Destination(id: 2, city: "Rome", country: "Italy"),
        Destination(id: 3, city: "Berlin", country: "Germany")
    ]

    func addDestination(id: Int, city: String, country: String) {
        if !destinations.contains(where: { $0.id == id }) {
            let newDestination = Destination(id: id, city: city, country: country)
            destinations.append(newDestination)
        }
    }

    func updateDestination(id: Int, newCity: String) {
        if let index = destinations.firstIndex(where: { $0.id == id }) {
            destinations[index].city = newCity
        }
    }

    func deleteDestination(id: Int) -> Bool {
        if trips.contains(where: { $0.destinationId == id }) {
            return false
        }
        destinations.removeAll { $0.id == id }
        return true
    }

    var trips: [Trip] = [
        Trip(id: 1, destinationId: 1, title: "Autumn Break", startDate: "2025-10-01", endDate: "2025-10-10"),
        Trip(id: 2, destinationId: 1, title: "Spring Getaway", startDate: "2025-04-15", endDate: "2025-04-22"),
        Trip(id: 3, destinationId: 2, title: "Historical Tour", startDate: "2025-05-05", endDate: "2025-05-12"),
        Trip(id: 4, destinationId: 2, title: "Culinary Journey", startDate: "2025-05-05", endDate: "2025-05-12")
    ]

    func addTrip(id: Int, destinationId: Int, title: String, startDate: String, endDate: String) {
        if !trips.contains(where: { $0.id == id }) {
            let newTrip = Trip(id: id, destinationId: destinationId, title: title, startDate: startDate, endDate: endDate)
            trips.append(newTrip)
        }
    }

    func updateTrip(id: Int, newTitle: String, newEndDate: String) {
        if let index = trips.firstIndex(where: { $0.id == id }) {
            trips[index].title = newTitle
            trips[index].endDate = newEndDate
        }
    }

    func deleteTrip(id: Int) -> Bool {
        if activities.contains(where: { $0.tripId == id }) || expenses.contains(where: { $0.tripId == id }) {
            return false
        }
        trips.removeAll { $0.id == id }
        return true
    }

    var activities: [Activity] = [
        Activity(id: 1, tripId: 1, name: "London Eye Visit", date: "2025-10-02", time: "11:00 AM", location: "London"),
        Activity(id: 2, tripId: 1, name: "Thames River Cruise", date: "2025-10-03", time: "02:00 PM", location: "London"),
        Activity(id: 3, tripId: 2, name: "Hyde Park Stroll", date: "2025-04-16", time: "09:30 AM", location: "London"),
        Activity(id: 4, tripId: 2, name: "British Museum Tour", date: "2025-04-16", time: "01:00 PM", location: "London")
    ]

    func addActivity(id: Int, tripId: Int, name: String, date: String, time: String, location: String) {
        if let trip = trips.first(where: { $0.id == tripId }), isDateWithinTripPeriod(date, trip: trip) {
            if !activities.contains(where: { $0.id == id }) {
                let newActivity = Activity(id: id, tripId: tripId, name: name, date: date, time: time, location: location)
                activities.append(newActivity)
            }
        }
    }
    
    func updateActivity(id: Int, newName: String, newDate: String, newTime: String, newLocation: String) {
        if let index = activities.firstIndex(where: { $0.id == id }) {
            activities[index].name = newName
            activities[index].date = newDate
            activities[index].time = newTime
            activities[index].location = newLocation
        }
    }

    func deleteActivity(id: Int) -> Bool {
        if let index = activities.firstIndex(where: { $0.id == id }) {
            let activity = activities[index]
            if isDateTimeInPast(activity.date, activity.time) {
                return false
            }
            activities.remove(at: index)
            return true
        }
        return false
    }

    var expenses: [Expense] = [
        Expense(id: 1, tripId: 1, title: "Hotel Reservation", amount: 600.0, date: "2025-09-30"),
        Expense(id: 2, tripId: 1, title: "City Tour Bus", amount: 250.0, date: "2025-09-30"),
        Expense(id: 3, tripId: 2, title: "Museum Entry", amount: 150.0, date: "2025-04-14"),
        Expense(id: 4, tripId: 2, title: "Local Transport", amount: 100.0, date: "2025-04-14")
    ]

    func addExpense(id: Int, tripId: Int, title: String, amount: Double, date: String) {
        if !expenses.contains(where: { $0.id == id }) {
            let newExpense = Expense(id: id, tripId: tripId, title: title, amount: amount, date: date)
            expenses.append(newExpense)
        }
    }

    func updateExpense(id: Int, newTitle: String, newAmount: Double, newDate: String) {
        if let index = expenses.firstIndex(where: { $0.id == id }) {
            expenses[index].title = newTitle
            expenses[index].amount = newAmount
            expenses[index].date = newDate
        }
    }
    
    func deleteExpense(id: Int) -> Bool {
        if let index = expenses.firstIndex(where: { $0.id == id }) {
            let expense = expenses[index]
            if isExpenseOlderThan30Days(expense.date) {
                return false
            }
            expenses.remove(at: index)
            return true
        }
        return false
    }

    private func isDateTimeInPast(_ dateStr: String, _ timeStr: String) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd hh:mm a"
        if let activityDateTime = dateFormatter.date(from: "\(dateStr) \(timeStr)") {
            return activityDateTime < Date()
        }
        return false
    }
    
    private func isExpenseOlderThan30Days(_ dateStr: String) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let expenseDate = dateFormatter.date(from: dateStr) else { return false }

        let today = Date()
        let difference = Calendar.current.dateComponents([.day], from: expenseDate, to: today)
        return (difference.day ?? 0) > 30
    }
    
    private func isDateWithinTripPeriod(_ dateStr: String, trip: Trip) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let date = dateFormatter.date(from: dateStr),
              let startDate = dateFormatter.date(from: trip.startDate),
              let endDate = dateFormatter.date(from: trip.endDate) else { return false }
        
        return date >= startDate && date <= endDate
    }
}
