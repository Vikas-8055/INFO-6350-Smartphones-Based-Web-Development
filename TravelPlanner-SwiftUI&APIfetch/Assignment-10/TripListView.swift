import SwiftUI

struct TripListView: View {
    @State private var trips: [Trip] = []
    @State private var destinations: [Destination] = []
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                if filteredTrips.isEmpty {
                    Text("No trips found")
                        .font(.headline)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    List(filteredTrips) { trip in
                        NavigationLink(destination: TripDetailView(trip: trip)) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(trip.title)
                                        .font(.headline)
                                    Text("Destination: \(destinationName(for: Int32(trip.destinationID)))")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: iconForDuration(trip))
                                    .font(.system(size: 24))
                                    .foregroundColor(.blue)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            .onAppear {
                APIService().fetchTrips { self.trips = $0 }
                APIService().fetchDestinations { self.destinations = $0 }
            }
            .navigationTitle("Trips")
            .searchable(text: $searchText, prompt: "Search by title")
        }
    }
    
    // MARK: - Helpers
    
    var filteredTrips: [Trip] {
        searchText.isEmpty
            ? trips
            : trips.filter { $0.title.lowercased().contains(searchText.lowercased()) }
    }
    
    func iconForDuration(_ trip: Trip) -> String {
        let duration = calculateDuration(from: trip.startDate, to: trip.endDate)
        switch duration {
        case 1...3:
            return "calendar"
        case 4...7:
            return "calendar.badge.clock"
        default:
            return "calendar.badge.exclamationmark"
        }
    }
    
    func calculateDuration(from start: String, to end: String) -> Int {
        let isoFormatter = ISO8601DateFormatter()
        // Include fractional seconds so that date strings like "2025-05-01T10:30:00.000Z" parse correctly.
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let startDate = isoFormatter.date(from: start),
              let endDate = isoFormatter.date(from: end) else { return 0 }
        let seconds = endDate.timeIntervalSince(startDate)
        return Int(seconds / (60 * 60 * 24))
    }
    
    func destinationName(for id: Int32) -> String {
        destinations.first(where: { $0.id == String(id) })?.city ?? "Unknown"
    }
}
