import SwiftUI

struct TripDetailView: View {
    let trip: Trip

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Trip Icon based on duration
            HStack {
                Spacer()
                Image(systemName: iconForDuration)
                    .font(.system(size: 64))
                    .foregroundColor(.blue)
                Spacer()
            }
            
            Text("Trip Title: \(trip.title)")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Destination ID: \(trip.destinationID)")
                .font(.title2)
            
            Text("Start Date: \(formattedDate(from: trip.startDate))")
                .font(.body)
            Text("End Date: \(formattedDate(from: trip.endDate))")
                .font(.body)
            
            Text("Duration: \(tripDuration) days")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Trip Details")
    }

    // MARK: - Helpers

    /// Computes the duration of the trip in days using time interval.
    var tripDuration: Int {
        let isoFormatter = ISO8601DateFormatter()
        // Include fractional seconds so the formatter can parse ".000" correctly.
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let start = isoFormatter.date(from: trip.startDate),
              let end = isoFormatter.date(from: trip.endDate) else {
            print("Date parsing failed for trip:", trip.title)
            return 0
        }
        // Calculate the time interval in seconds and convert to days.
        let seconds = end.timeIntervalSince(start)
        return Int(seconds / (60 * 60 * 24))
    }

    /// Returns the appropriate SF Symbol name based on the trip duration.
    var iconForDuration: String {
        switch tripDuration {
        case 1...3:
            return "calendar"
        case 4...7:
            return "calendar.badge.clock"
        default:
            return "calendar.badge.exclamationmark"
        }
    }

    /// Formats an ISO8601 date string into a user-friendly medium style date.
    func formattedDate(from raw: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: raw) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
        return raw
    }
}
