import SwiftUI
import PhotosUI

struct DestinationDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    @State private var isEditing = false
    @State private var city: String
    @State private var country: String
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showDeleteConfirmation = false
    @State private var destinationID: String
    var destination: DestinationEntity

    init(destination: DestinationEntity) {
        self.destination = destination
        _city = State(initialValue: destination.city ?? "")
        _country = State(initialValue: destination.country ?? "")
        _destinationID = State(initialValue: "\(destination.destinationID)") // Use destinationID as Int32
        
        if let imageData = destination.image {
            _selectedImage = State(initialValue: UIImage(data: imageData))
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            // Destination Image
            Button(action: {
                if isEditing { showingImagePicker = true }
            }) {
                if let selectedImage = selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray, lineWidth: 2))
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.gray)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!isEditing)

            // Editable Fields
            Group {
                TextField("City", text: $city)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(!isEditing)
                    .keyboardType(.default)

                TextField("Country", text: $country)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(!isEditing)
                    .keyboardType(.default)

                TextField("Destination ID", text: $destinationID)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(true) // Make ID non-editable
            }
            .padding(.horizontal)

            Spacer()

            // Update Button
            if isEditing {
                Button(action: updateDestination) {
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
        .navigationTitle("Destination Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    if isEditing { resetFields() }
                    isEditing.toggle()
                }) {
                    Image(systemName: isEditing ? "xmark.circle.fill" : "pencil.circle.fill")
                        .foregroundColor(.blue)
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showDeleteConfirmation = true
                }) {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.red)
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Notification"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .confirmationDialog(
            "Are you sure you want to delete this destination?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive, action: deleteDestination)
            Button("Cancel", role: .cancel, action: {})
        }
    }

    private func resetFields() {
        city = destination.city ?? ""
        country = destination.country ?? ""
        if let imageData = destination.image {
            selectedImage = UIImage(data: imageData)
        } else {
            selectedImage = nil
        }
    }

    private func updateDestination() {
        guard !city.isEmpty else {
            showAlert("City cannot be empty.")
            return
        }

        guard !country.isEmpty else {
            showAlert("Country cannot be empty.")
            return
        }

        destination.city = city
        destination.country = country

        if let selectedImage = selectedImage, let imageData = selectedImage.jpegData(compressionQuality: 0.8) {
            destination.image = imageData
        }

        do {
            try viewContext.save()
            showAlert("Updated destination successfully.")
            isEditing = false
        } catch {
            showAlert("Failed to update destination: \(error.localizedDescription)")
        }
    }

    private func deleteDestination() {
        if let tripCount = destination.trips?.count, tripCount > 0 {
            showAlert("This destination has active trips and cannot be deleted.")
            return
        }

        viewContext.delete(destination)

        do {
            try viewContext.save()
            showAlert("Destination deleted successfully.")
            presentationMode.wrappedValue.dismiss()
        } catch {
            showAlert("Failed to delete destination: \(error.localizedDescription)")
        }
    }

    private func showAlert(_ message: String) {
        alertMessage = message
        showAlert = true
    }
}
