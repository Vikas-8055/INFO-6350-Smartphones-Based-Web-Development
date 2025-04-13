import SwiftUI
import CoreData

struct TripDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    @State private var isEditing = false
    @State private var title: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showDeleteConfirmation = false
    let trip: TripEntity

    init(trip: TripEntity) {
        self.trip = trip
        _title = State(initialValue: trip.title ?? "")
        _startDate = State(initialValue: trip.startDate ?? Date())
        _endDate = State(initialValue: trip.endDate ?? Date())
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Trip ID: \(trip.id)")
                .font(.caption)
                .foregroundColor(.gray)

            if let destination = trip.destination {
                Text("Destination: \(destination.city ?? "Unknown City")")
                    .font(.headline)
            }

            Image(systemName: iconForTripDuration(start: startDate, end: endDate))
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)

            if isEditing {
                TextField("Trip Title", text: $title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .autocapitalization(.words)
            } else {
                Text("Trip Title: \(title)")
                    .font(.title2)
            }

            if isEditing {
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    .padding(.horizontal)
            } else {
                Text("Start Date: \(formatDate(startDate))")
            }

            if isEditing {
                DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    .padding(.horizontal)
            } else {
                Text("End Date: \(formatDate(endDate))")
            }

            Spacer()

            if isEditing {
                Button(action: updateTrip) {
                    Text("Update")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .navigationTitle(isEditing ? "Edit Trip" : "Trip Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { isEditing.toggle() }) {
                    Image(systemName: isEditing ? "xmark.circle.fill" : "pencil.circle.fill")
                        .foregroundColor(.blue)
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.red)
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .confirmationDialog(
            "Are you sure you want to delete this trip?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive, action: deleteTrip)
            Button("Cancel", role: .cancel, action: {})
        }
    }

    private func updateTrip() {
        guard !title.isEmpty else {
            showAlert("Error", "Trip title cannot be empty.")
            return
        }

        guard endDate > startDate else {
            showAlert("Error", "End date must be after start date.")
            return
        }

        trip.title = title
        trip.startDate = startDate
        trip.endDate = endDate

        do {
            try viewContext.save()
            showAlert("Success", "Trip updated successfully.")
            isEditing = false
        } catch {
            showAlert("Error", "Failed to update trip: \(error.localizedDescription)")
        }
    }

    // Delete trip anytime (Removed date check)
    private func deleteTrip() {
        if let destination = trip.destination {
            destination.removeFromTrips(trip)
        }

        viewContext.delete(trip)

        do {
            try viewContext.save()
            showAlert("Success", "Trip deleted successfully.")
            presentationMode.wrappedValue.dismiss()
        } catch {
            showAlert("Error", "Failed to delete trip: \(error.localizedDescription)")
        }
    }

    private func showAlert(_ title: String, _ message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }

    private func iconForTripDuration(start: Date?, end: Date?) -> String {
        guard let start = start, let end = end else { return "calendar.badge.questionmark" }
        let duration = Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0

        switch duration {
        case 0...3: return "airplane"
        case 4...10: return "suitcase.fill"
        default: return "globe"
        }
    }

    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
