import SwiftUI
import CoreData

struct TripAdd: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var tripID: String = "" // Manual ID entry field
    @State private var title: String = ""
    @State private var selectedDestination: DestinationEntity? = nil
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date().addingTimeInterval(7*24*60*60) // Default to one week
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    // Fetch available destinations from Core Data
    @FetchRequest(
        entity: DestinationEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \DestinationEntity.city, ascending: true)]
    ) var destinations: FetchedResults<DestinationEntity>

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Trip ID - Manual entry
                TextField("Trip ID", text: $tripID)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .keyboardType(.numberPad)
                
                // Trip Title
                TextField("Trip Title", text: $title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .keyboardType(.default)
                    .textInputAutocapitalization(.words)

                // Destination Picker
                if destinations.isEmpty {
                    Text("No destinations available. Please add destinations first.")
                        .foregroundColor(.red)
                        .padding()
                } else {
                    Picker("Select Destination", selection: $selectedDestination) {
                        Text("Please select a destination").tag(nil as DestinationEntity?)
                        ForEach(destinations, id: \.self) { destination in
                            Text("\(destination.city ?? "Unknown City"), \(destination.country ?? "Unknown Country") (ID: \(destination.destinationID))")
                                .tag(destination as DestinationEntity?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.horizontal)
                }

                // Start Date
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    .padding(.horizontal)

                // End Date
                DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    .padding(.horizontal)

                Spacer()

                // Save Button
                Button(action: saveTrip) {
                    Text("Save Trip")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                .disabled(selectedDestination == nil)
            }
            .padding()
            .navigationTitle("Add Trip")
            .alert(isPresented: $showAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func saveTrip() {
        // Validation
        guard !tripID.isEmpty, let id = Int32(tripID) else {
            showAlert("Error", "Please enter a valid numeric Trip ID.")
            return
        }
        
        // Check if this ID is already in use
        let idRequest: NSFetchRequest<TripEntity> = TripEntity.fetchRequest()
        idRequest.predicate = NSPredicate(format: "id == %d", id)
        
        do {
            let matches = try viewContext.fetch(idRequest)
            if !matches.isEmpty {
                showAlert("Error", "This Trip ID is already in use. Please choose a different ID.")
                return
            }
        } catch {
            showAlert("Error", "Failed to check ID: \(error.localizedDescription)")
            return
        }
        
        guard !title.isEmpty else {
            showAlert("Error", "Trip title cannot be empty.")
            return
        }
        guard let selectedDestination = selectedDestination else {
            showAlert("Error", "Please select a destination.")
            return
        }
        guard endDate > startDate else {
            showAlert("Error", "End Date must be after Start Date.")
            return
        }

        // Create new trip
        let newTrip = TripEntity(context: viewContext)
        newTrip.id = id  // Use the manually entered ID
        newTrip.title = title
        newTrip.startDate = startDate
        newTrip.endDate = endDate
        newTrip.destination = selectedDestination

        // Update the destination relationship
        selectedDestination.addToTrips(newTrip)

        do {
            try viewContext.save()
            showAlert("Success", "Trip added successfully with ID: \(id).")
            resetFields()
        } catch {
            showAlert("Error", "Failed to save trip: \(error.localizedDescription)")
        }
    }

    private func resetFields() {
        tripID = ""
        title = ""
        selectedDestination = nil
        startDate = Date()
        endDate = Date().addingTimeInterval(7*24*60*60)
    }

    private func showAlert(_ title: String, _ message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}
