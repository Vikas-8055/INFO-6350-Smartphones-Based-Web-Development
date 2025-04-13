import SwiftUI
import Combine
import CoreData

class DestinationViewModel: ObservableObject {
    @Published var destinations: [DestinationEntity] = []
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private var viewContext: NSManagedObjectContext
    
    // API URL - using the correct singular endpoint
    private let apiURL = "https://67f2b3aeec56ec1a36d3effd.mockapi.io/destinations"

    init(context: NSManagedObjectContext) {
        self.viewContext = context
        fetchDestinations()
    }

    func fetchDestinations() {
        let fetchRequest: NSFetchRequest<DestinationEntity> = DestinationEntity.fetchRequest()

        do {
            let fetched = try viewContext.fetch(fetchRequest)
            self.destinations = fetched
            
            if fetched.isEmpty && !Destination.isFetched {
                print("No destinations found in CoreData. Attempting to fetch from API...")
                fetchDestinationsFromAPI()
                Destination.isFetched = true
            }
        } catch {
            print("Error fetching destinations from Core Data: \(error)")
            errorMessage = "Failed to fetch destinations: \(error.localizedDescription)"
        }
    }

    var filteredDestinations: [DestinationEntity] {
        if searchText.isEmpty {
            return destinations
        } else {
            return destinations.filter {
                ($0.city?.lowercased().contains(searchText.lowercased()) ?? false) ||
                ($0.country?.lowercased().contains(searchText.lowercased()) ?? false)
            }
        }
    }

    private func fetchDestinationsFromAPI() {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: apiURL) else {
            print("Invalid URL: \(apiURL)")
            isLoading = false
            errorMessage = "Invalid API URL"
            return
        }
        
        print("Fetching destinations from: \(apiURL)")
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                // Handle network error
                if let error = error {
                    print("Network error: \(error.localizedDescription)")
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                
                // Check HTTP response
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("Invalid response type")
                    self.errorMessage = "Invalid server response"
                    return
                }
                
                print("HTTP Response Status: \(httpResponse.statusCode)")
                
                // Check status code
                guard (200...299).contains(httpResponse.statusCode) else {
                    print("Server returned error status: \(httpResponse.statusCode)")
                    self.errorMessage = "Server error: \(httpResponse.statusCode)"
                    return
                }
                
                // Check for valid data
                guard let data = data, !data.isEmpty else {
                    print("No data received from server")
                    self.errorMessage = "No data received from server"
                    return
                }
                
                // Print the raw JSON for debugging
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Raw JSON response: \(jsonString.prefix(500))...")
                }
                
                // Try to decode the data with the correct structure
                do {
                    let apiDestinations = try JSONDecoder().decode([MockAPIDestination].self, from: data)
                    print("Successfully decoded \(apiDestinations.count) destinations")
                    
                    if apiDestinations.isEmpty {
                        print("API returned empty array")
                        self.errorMessage = "No destinations found in API"
                        return
                    }
                    
                    self.saveDestinationsToCoreData(apiDestinations)
                } catch {
                    print("Error decoding data: \(error)")
                    self.errorMessage = "Failed to process API data: \(error.localizedDescription)"
                }
            }
        }
        task.resume()
    }

    private func saveDestinationsToCoreData(_ apiDestinations: [MockAPIDestination]) {
        print("Saving \(apiDestinations.count) destinations to Core Data")
        
        for apiDestination in apiDestinations {
            let destination = DestinationEntity(context: viewContext)
            destination.destinationID = Int32(apiDestination.id) // Convert numeric ID to Int32
            destination.city = apiDestination.city
            destination.country = apiDestination.country

            if let imageURL = URL(string: apiDestination.pictureURL) {
                fetchImageData(from: imageURL) { [weak self] data in
                    guard let self = self else { return }
                    
                    DispatchQueue.main.async {
                        if let data = data {
                            destination.image = data
                            
                            do {
                                try self.viewContext.save()
                                print("Saved image for \(apiDestination.city)")
                            } catch {
                                print("Error saving image: \(error)")
                            }
                        } else {
                            print("Failed to fetch image data for \(apiDestination.city)")
                        }
                    }
                }
            } else {
                print("Invalid image URL: \(apiDestination.pictureURL)")
            }
        }

        do {
            try viewContext.save()
            print("Successfully saved \(apiDestinations.count) destinations to Core Data")
            fetchDestinations() // Refresh the list
        } catch {
            print("Error saving destinations: \(error)")
            errorMessage = "Failed to save destinations: \(error.localizedDescription)"
        }
    }
    
    private func fetchImageData(from url: URL, completion: @escaping (Data?) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching image: \(error)")
                completion(nil)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("Invalid HTTP response for image")
                completion(nil)
                return
            }
            
            completion(data)
        }
        task.resume()
    }
}
