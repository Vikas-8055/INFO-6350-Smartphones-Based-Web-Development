import Foundation

final class DataStore {
    
    static let shared = DataStore()
    private init() { }

    private var destinations: [Destination] = []
    private var trips: [Trip] = []

    func addDestination(_ destination: Destination) throws {
  
        guard !destination.city.isEmpty, !destination.country.isEmpty else {
            throw NSError(domain: "Invalid input", code: 1, userInfo: [NSLocalizedDescriptionKey: "City/Country cannot be empty"])
        }
        destinations.append(destination)
    }

    func updateDestination(id: Int, newCity: String) throws {
        guard !newCity.isEmpty else {
            throw NSError(domain: "Invalid input", code: 2, userInfo: [NSLocalizedDescriptionKey: "City cannot be empty"])
        }
        guard let index = destinations.firstIndex(where: { $0.id == id }) else {
            throw NSError(domain: "Not found", code: 3, userInfo: [NSLocalizedDescriptionKey: "Destination not found"])
        }
        
        destinations[index].city = newCity
    }

    func deleteDestination(id: Int) throws {
        
        if trips.contains(where: { $0.destination_id == id }) {
            throw NSError(domain: "Delete Error", code: 4, userInfo: [NSLocalizedDescriptionKey: "Cannot delete this destination because it has linked trips."])
        }
        guard let index = destinations.firstIndex(where: { $0.id == id }) else {
            throw NSError(domain: "Not found", code: 5, userInfo: [NSLocalizedDescriptionKey: "Destination not found"])
        }
        destinations.remove(at: index)
    }

    func getAllDestinations() -> [Destination] {
        return destinations
    }

    func addTrip(_ trip: Trip) throws {
        
        guard !trip.title.isEmpty, !trip.start_date.isEmpty,
              !trip.end_date.isEmpty, !trip.description.isEmpty else {
            throw NSError(domain: "Invalid input", code: 6, userInfo: [NSLocalizedDescriptionKey: "Trip fields cannot be empty"])
        }

        guard destinations.contains(where: { $0.id == trip.destination_id }) else {
            throw NSError(domain: "Invalid Destination", code: 7, userInfo: [NSLocalizedDescriptionKey: "No Destination with that ID"])
        }
        trips.append(trip)
    }

    func updateTrip(id: Int, newTitle: String?, newEndDate: String?, newDescription: String?) throws {
        guard let index = trips.firstIndex(where: { $0.id == id }) else {
            throw NSError(domain: "Not found", code: 8, userInfo: [NSLocalizedDescriptionKey: "Trip not found"])
        }

        if let t = newTitle, !t.isEmpty {
            trips[index].title = t
        }
        if let e = newEndDate, !e.isEmpty {
            trips[index].end_date = e
        }
        if let d = newDescription, !d.isEmpty {
            trips[index].description = d
        }
    }

    func deleteTrip(id: Int) throws {
        guard let index = trips.firstIndex(where: { $0.id == id }) else {
            throw NSError(domain: "Not found", code: 9, userInfo: [NSLocalizedDescriptionKey: "Trip not found"])
        }

        let startDateString = trips[index].start_date


        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let startDate = dateFormatter.date(from: startDateString),
              let now = dateFormatter.date(from: dateFormatter.string(from: Date())) else {
            throw NSError(domain: "Date Parsing Error", code: 10, userInfo: [NSLocalizedDescriptionKey: "Cannot parse trip dates"])
        }

        if now >= startDate {
            throw NSError(domain: "Delete Error", code: 11, userInfo: [NSLocalizedDescriptionKey: "Cannot delete a trip that has already started"])
        }

        trips.remove(at: index)
    }

    func getAllTrips() -> [Trip] {
        return trips
    }
}
