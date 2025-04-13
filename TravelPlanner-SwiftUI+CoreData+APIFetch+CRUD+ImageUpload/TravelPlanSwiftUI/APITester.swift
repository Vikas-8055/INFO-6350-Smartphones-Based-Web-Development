import SwiftUI
import CoreData

struct APITester: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var message: String = ""
    @State private var isLoading: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var rawResponse: String = ""
    @State private var showRawResponse: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("API Testing Tools")
                    .font(.title)
                    .padding(.top)
                
                if isLoading {
                    ProgressView("Working...")
                        .padding()
                }
                
                if !message.isEmpty {
                    Text(message)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                Group {
                    Button(action: testDestinationAPI) {
                        Label("Test Destination API", systemImage: "network")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    Button(action: testTripsAPI) {
                        Label("Test Trips API", systemImage: "network")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    if !rawResponse.isEmpty {
                        Button(action: { showRawResponse.toggle() }) {
                            Label(showRawResponse ? "Hide Raw Response" : "Show Raw Response",
                                  systemImage: showRawResponse ? "eye.slash" : "eye")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        
                        if showRawResponse {
                            Text(rawResponse)
                                .font(.system(.caption, design: .monospaced))
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                    
                    Divider()
                    
                    Button(action: resetFetchFlags) {
                        Label("Reset API Fetch Flags", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    Button(action: clearAllData) {
                        Label("Clear All Data", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("API Tester")
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func testDestinationAPI() {
        isLoading = true
        message = "Testing destination API..."
        rawResponse = ""
        showRawResponse = false
        
        let destinationURL = "https://67f2b3aeec56ec1a36d3effd.mockapi.io/destinations"
        
        guard let url = URL(string: destinationURL) else {
            isLoading = false
            message = "Invalid URL"
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    message = "Error: \(error.localizedDescription)"
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    message = "Invalid response type"
                    return
                }
                
                message = "Status: \(httpResponse.statusCode)"
                
                if (200...299).contains(httpResponse.statusCode), let data = data {
                    if let jsonString = String(data: data, encoding: .utf8) {
                        rawResponse = jsonString
                        message = "Success! Found \(jsonString.count) characters of data"
                        
                        // Try to decode
                        do {
                            let destinations = try JSONDecoder().decode([MockAPIDestination].self, from: data)
                            showAlert(title: "Success", message: "Found \(destinations.count) destinations!")
                            
                            // Print field names of first destination for debugging
                            if let first = destinations.first {
                                print("First destination: id=\(first.id), city=\(first.city), country=\(first.country), pictureURL=\(first.pictureURL)")
                            }
                        } catch {
                            showAlert(title: "Decode Error", message: error.localizedDescription)
                        }
                    }
                }
            }
        }
        task.resume()
    }
    
    private func testTripsAPI() {
        isLoading = true
        message = "Testing trips API..."
        rawResponse = ""
        showRawResponse = false
        
        let tripsURL = "https://67f2b3aeec56ec1a36d3effd.mockapi.io/trips"
        
        guard let url = URL(string: tripsURL) else {
            isLoading = false
            message = "Invalid URL"
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    message = "Error: \(error.localizedDescription)"
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    message = "Invalid response type"
                    return
                }
                
                message = "Status: \(httpResponse.statusCode)"
                
                if (200...299).contains(httpResponse.statusCode), let data = data {
                    if let jsonString = String(data: data, encoding: .utf8) {
                        rawResponse = jsonString
                        message = "Success! Found \(jsonString.count) characters of data"
                        
                        // Try to decode
                        do {
                            let trips = try JSONDecoder().decode([MockAPITrip].self, from: data)
                            showAlert(title: "Success", message: "Found \(trips.count) trips!")
                            
                            // Print field names of first trip for debugging
                            if let first = trips.first {
                                print("First trip: id=\(first.id), destinationID=\(first.destinationID), title=\(first.title)")
                            }
                        } catch {
                            showAlert(title: "Decode Error", message: error.localizedDescription)
                        }
                    }
                }
            }
        }
        task.resume()
    }
    
    private func resetFetchFlags() {
        Destination.isFetched = false
        Trip.isFetched = false
        message = "Fetch flags reset. App will try to fetch from API again."
        showAlert(title: "Success", message: "API fetch flags reset. Restart the app or navigate to another screen and back to refresh.")
    }
    
    private func clearAllData() {
        isLoading = true
        message = "Clearing all data..."
        
        // Delete trips first
        let tripFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "TripEntity")
        let tripDeleteRequest = NSBatchDeleteRequest(fetchRequest: tripFetch)
        
        // Then delete destinations
        let destFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "DestinationEntity")
        let destDeleteRequest = NSBatchDeleteRequest(fetchRequest: destFetch)
        
        do {
            try viewContext.execute(tripDeleteRequest)
            try viewContext.execute(destDeleteRequest)
            try viewContext.save()
            
            // Reset fetch flags
            Destination.isFetched = false
            Trip.isFetched = false
            
            isLoading = false
            message = "All data cleared successfully"
            showAlert(title: "Success", message: "All data has been cleared. The app will fetch from API on next view appearance.")
        } catch {
            isLoading = false
            message = "Error clearing data: \(error.localizedDescription)"
            showAlert(title: "Error", message: "Failed to clear data: \(error.localizedDescription)")
        }
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

// Add this to ContentView for easy access to the API Tester
extension ContentView {
    func addAPITester() -> some View {
        TabView {
            self
                .tabItem {
                    Label("App", systemImage: "house")
                }
            
            NavigationView {
                APITester()
            }
            .tabItem {
                Label("API Tester", systemImage: "network")
            }
        }
    }
}
