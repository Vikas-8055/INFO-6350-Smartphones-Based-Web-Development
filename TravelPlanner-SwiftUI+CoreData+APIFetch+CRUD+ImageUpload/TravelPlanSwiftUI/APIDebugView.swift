import SwiftUI
import CoreData

struct APIDebugView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var destinationURL = "https://67f2b3aeec56ec1a36d3effd.mockapi.io/destinations"
    @State private var tripURL = "https://67f2b3aeec56ec1a36d3effd.mockapi.io/trips"
    @State private var testResults: [TestResult] = []
    @State private var isLoading = false
    @State private var showConfirmation = false
    @State private var confirmationMessage = ""
    @State private var confirmationAction: () -> Void = {}
    
    struct TestResult: Identifiable {
        let id = UUID()
        let url: String
        let success: Bool
        let message: String
        let timestamp: Date = Date()
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("API Debug Tools")
                    .font(.title)
                    .padding(.top)
                
                // API URLs
                Group {
                    Text("API Endpoints")
                        .font(.headline)
                    
                    TextField("Destinations URL", text: $destinationURL)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Trips URL", text: $tripURL)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Test Buttons
                Group {
                    Text("Test Actions")
                        .font(.headline)
                        .padding(.top, 8)
                    
                    Button(action: testDestinationsAPI) {
                        Label("Test Destinations API", systemImage: "network")
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
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    Button(action: {
                        confirmAction(
                            message: "This will reset fetch flags and make the app try to fetch data from the API again. Continue?",
                            action: resetFetchFlags
                        )
                    }) {
                        Label("Reset API Fetch Status", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                        confirmAction(
                            message: "This will delete ALL saved destinations and trips. Continue?",
                            action: deleteAllData
                        )
                    }) {
                        Label("Delete All Data", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                
                // Test Results
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView("Testing...")
                        Spacer()
                    }
                    .padding()
                } else if !testResults.isEmpty {
                    Text("Test Results")
                        .font(.headline)
                        .padding(.top, 8)
                    
                    ForEach(testResults) { result in
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(result.success ? .green : .red)
                                Text(result.url)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                Spacer()
                                Text(formatDate(result.timestamp))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Text(result.message)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 26)
                        }
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
            }
            .padding()
        }
        .alert(isPresented: $showConfirmation) {
            Alert(
                title: Text("Confirm"),
                message: Text(confirmationMessage),
                primaryButton: .destructive(Text("Continue")) {
                    confirmationAction()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func testDestinationsAPI() {
        isLoading = true
        testEndpoint(destinationURL) { result in
            testResults.insert(result, at: 0)
            isLoading = false
        }
    }
    
    private func testTripsAPI() {
        isLoading = true
        testEndpoint(tripURL) { result in
            testResults.insert(result, at: 0)
            isLoading = false
        }
    }
    
    private func testEndpoint(_ url: String, completion: @escaping (TestResult) -> Void) {
        guard let urlObj = URL(string: url) else {
            completion(TestResult(url: url, success: false, message: "Invalid URL format"))
            return
        }
        
        var request = URLRequest(url: urlObj)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle network error
            if let error = error {
                DispatchQueue.main.async {
                    completion(TestResult(url: url, success: false, message: "Network error: \(error.localizedDescription)"))
                }
                return
            }
            
            // Check HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(TestResult(url: url, success: false, message: "Invalid response type"))
                }
                return
            }
            
            // Check status code
            guard (200...299).contains(httpResponse.statusCode) else {
                DispatchQueue.main.async {
                    completion(TestResult(url: url, success: false, message: "HTTP error: \(httpResponse.statusCode)"))
                }
                return
            }
            
            // Check data
            guard let data = data, !data.isEmpty else {
                DispatchQueue.main.async {
                    completion(TestResult(url: url, success: false, message: "No data returned"))
                }
                return
            }
            
            // Try to parse JSON
            do {
                let json = try JSONSerialization.jsonObject(with: data)
                
                // Extract useful information about the structure
                if let array = json as? [[String: Any]], !array.isEmpty {
                    let firstItem = array[0]
                    let keys = Array(firstItem.keys).joined(separator: ", ")
                    
                    DispatchQueue.main.async {
                        completion(TestResult(
                            url: url,
                            success: true,
                            message: "Success! Found array with \(array.count) items. Fields: \(keys)"
                        ))
                    }
                } else if let dict = json as? [String: Any] {
                    let keys = Array(dict.keys).joined(separator: ", ")
                    
                    DispatchQueue.main.async {
                        completion(TestResult(
                            url: url,
                            success: true,
                            message: "Success! Found object with fields: \(keys)"
                        ))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(TestResult(
                            url: url,
                            success: true,
                            message: "Success! Valid JSON but unexpected structure."
                        ))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(TestResult(
                        url: url,
                        success: false,
                        message: "Invalid JSON: \(error.localizedDescription)"
                    ))
                }
            }
        }.resume()
    }
    
    private func resetFetchFlags() {
        Trip.isFetched = false
        Destination.isFetched = false
        
        let result = TestResult(
            url: "App Status",
            success: true,
            message: "Reset fetch flags. App will try to fetch from API next time."
        )
        
        testResults.insert(result, at: 0)
    }
    
    private func deleteAllData() {
        // Delete trips first (to maintain referential integrity)
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
            Trip.isFetched = false
            Destination.isFetched = false
            
            let result = TestResult(
                url: "Database",
                success: true,
                message: "All data deleted successfully. Restart the app or reset fetch flags to reload."
            )
            
            testResults.insert(result, at: 0)
        } catch {
            let result = TestResult(
                url: "Database",
                success: false,
                message: "Error deleting data: \(error.localizedDescription)"
            )
            
            testResults.insert(result, at: 0)
        }
    }
    
    private func confirmAction(message: String, action: @escaping () -> Void) {
        confirmationMessage = message
        confirmationAction = action
        showConfirmation = true
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}

// Add this as a menu item or navigation item in your app
extension ContentView {
    func addAPIDebugMenuItem() -> some View {
        NavigationView {
            self
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink(destination: APIDebugView()) {
                            Image(systemName: "network")
                        }
                    }
                }
        }
    }
}

