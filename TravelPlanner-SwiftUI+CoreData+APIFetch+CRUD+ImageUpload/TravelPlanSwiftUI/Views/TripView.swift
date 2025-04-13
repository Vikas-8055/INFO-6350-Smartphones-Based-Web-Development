import SwiftUI

struct TripView: View {
    @StateObject private var viewModel: TripViewModel
    @Environment(\.managedObjectContext) private var viewContext

    init() {
        _viewModel = StateObject(wrappedValue: TripViewModel(context: PersistenceController.shared.container.viewContext))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                TripSearchBar(text: $viewModel.searchText)
                
                // Show loading indicator or error
                if viewModel.isLoading {
                    ProgressView("Loading trips...")
                        .padding()
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                        .multilineTextAlignment(.center)
                }

                if viewModel.filteredTrips.isEmpty {
                    VStack(spacing: 15) {
                        Text("No trips found")
                            .foregroundColor(.red)
                            .font(.headline)
                            .padding()
                    }
                    .padding()
                } else {
                    List(viewModel.filteredTrips, id: \.self) { trip in
                        NavigationLink(destination: TripDetailView(trip: trip)) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(trip.title ?? "Untitled Trip")
                                        .font(.headline)
                                    
                                    if let start = trip.startDate, let end = trip.endDate {
                                        Text("From \(formatted(start)) to \(formatted(end))")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    if let destination = trip.destination {
                                        Text(destination.city ?? "Unknown City")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                }
                                
                                Spacer()
                                Image(systemName: iconForTripDuration(start: trip.startDate, end: trip.endDate))
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Trips")
            .onAppear {
                // Use the improved load method
                viewModel.loadData()
            }
        }
    }

    private func formatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func iconForTripDuration(start: Date?, end: Date?) -> String {
        guard let start = start, let end = end else {
            return "calendar.badge.questionmark"
        }
        let duration = Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0

        switch duration {
        case 0...3:
            return "airplane"
        case 4...10:
            return "suitcase.fill"
        default:
            return "globe"
        }
    }
}

struct TripSearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            TextField("Search Trips...", text: $text)
                .padding(7)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    HStack {
                        Spacer()
                        if !text.isEmpty {
                            Button(action: {
                                text = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                )
                .padding(.horizontal, 10)

            NavigationLink(destination: TripAdd()) {
                Image(systemName: "plus")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.blue)
                    .padding(.trailing)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.top, 10)
    }
}
