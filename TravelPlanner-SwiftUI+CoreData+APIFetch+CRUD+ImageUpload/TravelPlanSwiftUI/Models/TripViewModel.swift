import SwiftUI
import Combine
import CoreData

class TripViewModel: ObservableObject {
    @Published var trips: [TripEntity] = []
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private var cancellables = Set<AnyCancellable>()
    private let viewContext: NSManagedObjectContext

    private let tripsURL = "https://67f2b3aeec56ec1a36d3effd.mockapi.io/trips"

    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }

    // Fetch trips from CoreData or API
    func loadData() {
        fetchTrips()
    }

    func fetchTrips() {
        let fetchRequest: NSFetchRequest<TripEntity> = TripEntity.fetchRequest()

        do {
            let fetchedTrips = try viewContext.fetch(fetchRequest)
            self.trips = fetchedTrips

            if fetchedTrips.isEmpty && !Trip.isFetched {
                print("No trips found in CoreData. Fetching from API...")
                fetchTripsFromAPI()
                Trip.isFetched = true
            }
        } catch {
            print("Error fetching trips from CoreData: \(error)")
            errorMessage = "Failed to fetch trips: \(error.localizedDescription)"
        }
    }

    private func fetchTripsFromAPI() {
        isLoading = true
        errorMessage = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.checkDestinationsAndFetchTrips()
        }
    }

    private func checkDestinationsAndFetchTrips() {
        let destRequest: NSFetchRequest<DestinationEntity> = DestinationEntity.fetchRequest()

        do {
            let destinations = try viewContext.fetch(destRequest)

            if destinations.isEmpty {
                print("No destinations found. Retrying...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.checkDestinationsAndFetchTrips()
                }
                return
            }

            print("Destinations found. Fetching trips from API...")
            fetchTripsData(destinations)

        } catch {
            print("Error fetching destinations: \(error)")
            errorMessage = "Failed to access destinations: \(error.localizedDescription)"
            isLoading = false
        }
    }

    private func fetchTripsData(_ destinations: [DestinationEntity]) {
        guard let url = URL(string: tripsURL) else {
            print("Invalid trips API URL")
            errorMessage = "Invalid API URL"
            isLoading = false
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isLoading = false

                if let error = error {
                    print("Network error: \(error)")
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }

                guard let data = data else {
                    print("No data received")
                    self.errorMessage = "No trip data received"
                    return
                }

                if let rawString = String(data: data, encoding: .utf8) {
                    print("Trips JSON: \(rawString.prefix(200))...")
                }

                do {
                    let apiTrips = try JSONDecoder().decode([MockAPITrip].self, from: data)
                    print("Decoded \(apiTrips.count) trips")

                    var destinationMap: [Int32: DestinationEntity] = [:]
                    for destination in destinations {
                        destinationMap[destination.destinationID] = destination
                    }

                    self.processAndSaveTrips(apiTrips, destinationMap: destinationMap)
                } catch {
                    print("Error decoding trips: \(error)")
                    self.errorMessage = "Failed to decode trip data: \(error.localizedDescription)"
                }
            }
        }.resume()
    }

    private func processAndSaveTrips(_ apiTrips: [MockAPITrip], destinationMap: [Int32: DestinationEntity]) {
        var nextId: Int32 = (try? viewContext.fetch(TripEntity.fetchRequest()).first?.id ?? 0) ?? 0 + 1
        var savedCount = 0

        for trip in apiTrips {
            guard let destination = destinationMap[Int32(trip.destinationID)] else {
                continue
            }

            let tripRequest: NSFetchRequest<TripEntity> = TripEntity.fetchRequest()
            tripRequest.predicate = NSPredicate(format: "title == %@ AND destination == %@", trip.title, destination)

            let existingTrips = (try? viewContext.fetch(tripRequest)) ?? []

            if existingTrips.isEmpty {
                let tripEntity = TripEntity(context: viewContext)
                tripEntity.id = nextId
                nextId += 1
                tripEntity.title = trip.title
                tripEntity.destination = destination
                tripEntity.startDate = parseAPIDateString(trip.startDate) ?? Date()
                tripEntity.endDate = parseAPIDateString(trip.endDate) ?? Date()
                savedCount += 1
            }
        }

        if savedCount > 0 {
            do {
                try viewContext.save()
                print("Saved \(savedCount) new trips")
                fetchTrips()
            } catch {
                print("Error saving trips: \(error)")
                errorMessage = "Failed to save trips: \(error.localizedDescription)"
            }
        }
    }

    private func parseAPIDateString(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }

    var filteredTrips: [TripEntity] {
        if searchText.isEmpty {
            return trips
        } else {
            return trips.filter {
                ($0.title?.lowercased().contains(searchText.lowercased()) ?? false)
            }
        }
    }
}
