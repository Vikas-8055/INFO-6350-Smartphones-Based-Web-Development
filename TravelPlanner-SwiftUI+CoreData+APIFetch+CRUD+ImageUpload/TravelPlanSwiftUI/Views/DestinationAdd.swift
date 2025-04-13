import SwiftUI
import CoreData

struct DestinationAdd: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    // Form field states
    @State private var destinationID: String = ""  // Manual ID entry field
    @State private var city: String = ""
    @State private var country: String = ""
    @State private var destinationImage: UIImage? = nil
    @State private var showImagePicker: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    private let defaultImage: UIImage = UIImage(systemName: "photo")!

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Destination Details")) {
                    // Manual ID entry field
                    TextField("Destination ID", text: $destinationID)
                        .keyboardType(.numberPad)
                        .disableAutocorrection(true)
                    
                    TextField("Enter city", text: $city)
                        .keyboardType(.default)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)

                    TextField("Enter country", text: $country)
                        .keyboardType(.default)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                }

                Section(header: Text("Destination Image")) {
                    if let destinationImage = destinationImage {
                        Image(uiImage: destinationImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))
                    } else {
                        Image(uiImage: defaultImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))
                    }

                    Button("Select Destination Image") {
                        showImagePicker = true
                    }
                }

                Button(action: validateAndSaveDestination) {
                    Text("Submit")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
            .navigationTitle("Add Destination")
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Validation Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $destinationImage)
            }
        }
    }

    private func validateAndSaveDestination() {
        // Validate ID
        guard !destinationID.isEmpty, let id = Int32(destinationID) else {
            showValidationError("Please enter a valid numeric ID.")
            return
        }
        
        // Check if the ID is already in use
        let idRequest: NSFetchRequest<DestinationEntity> = DestinationEntity.fetchRequest()
        idRequest.predicate = NSPredicate(format: "destinationID == %d", id)
        
        do {
            let matches = try viewContext.fetch(idRequest)
            if !matches.isEmpty {
                showValidationError("This ID is already in use. Please choose a different ID.")
                return
            }
        } catch {
            showValidationError("Error checking ID: \(error.localizedDescription)")
            return
        }

        // Validate city
        guard !city.isEmpty else {
            showValidationError("City cannot be empty.")
            return
        }

        // Validate country
        guard !country.isEmpty else {
            showValidationError("Country cannot be empty.")
            return
        }
        
        // Save to Core Data
        let newDestination = DestinationEntity(context: viewContext)
        newDestination.destinationID = id  // Use the manually entered ID
        newDestination.city = city
        newDestination.country = country
        newDestination.image = destinationImage?.jpegData(compressionQuality: 0.8) ?? defaultImage.jpegData(compressionQuality: 0.8)

        do {
            try viewContext.save()
            print("Successfully saved new destination with ID: \(id)")
            clearForm()
        } catch {
            showValidationError("Failed to save destination: \(error.localizedDescription)")
        }
    }

    private func showValidationError(_ message: String) {
        alertMessage = message
        showAlert = true
    }

    private func clearForm() {
        destinationID = ""
        city = ""
        country = ""
        destinationImage = nil
        dismiss()
    }
}
