import SwiftUI
import CoreData

struct DestinationView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: DestinationViewModel

    init() {
        _viewModel = StateObject(wrappedValue: DestinationViewModel(context: PersistenceController.shared.container.viewContext))
    }

    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                DestinationSearchBar(text: $viewModel.searchText)

                // Loading indicator
                if viewModel.isLoading {
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.5)
                        
                        Text("Loading destinations...")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.top, 10)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                // Error message
                else if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 15) {
                        Image(systemName: "exclamationmark.triangle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.orange)
                        
                        Text("Error loading destinations")
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: {
                            viewModel.fetchDestinations()
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Try Again")
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .padding(.top, 10)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                // Check if filtered list is empty
                else if viewModel.filteredDestinations.isEmpty {
                    VStack(spacing: 15) {
                        Image(systemName: "mappin.slash")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.gray)
                        
                        Text("No destinations found")
                            .font(.headline)
                            .foregroundColor(.red)
                            
                        if !viewModel.searchText.isEmpty {
                            Text("Try a different search term")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        } else {
                            Button(action: {
                                // Reset isFetched flag and try fetching again
                                Destination.isFetched = false
                                viewModel.fetchDestinations()
                            }) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Fetch from API")
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                } else {
                    // List of destinations
                    List(viewModel.filteredDestinations, id: \.destinationID) { destination in
                        NavigationLink(destination: DestinationDetailView(destination: destination)) {
                            HStack {
                                // Image
                                if let imageData = destination.image,
                                   let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 50, height: 50)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
                                } else {
                                    Image(systemName: "photo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 50, height: 50)
                                        .foregroundColor(.gray)
                                }

                                // City & Country
                                VStack(alignment: .leading) {
                                    Text(destination.city ?? "Unknown City")
                                        .font(.headline)
                                    Text(destination.country ?? "Unknown Country")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.leading, 10)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Destinations")
            .onAppear {
                viewModel.fetchDestinations()
            }
            .refreshable {
                // Allow pull-to-refresh
                Destination.isFetched = false
                viewModel.fetchDestinations()
            }
        }
    }
}

// MARK: - Search Bar with Add Button
struct DestinationSearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            TextField("Search destinations...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            NavigationLink(destination: DestinationAdd()) {
                Image(systemName: "plus")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.blue)
                    .padding(.trailing)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}
