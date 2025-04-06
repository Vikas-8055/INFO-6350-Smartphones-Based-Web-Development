import SwiftUI

struct DestinationListView: View {
    @State private var destinations: [Destination] = []
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            VStack {
                if filteredDestinations.isEmpty {
                    Text("No destinations found")
                        .font(.headline)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    List(filteredDestinations) { destination in
                        NavigationLink(destination: DestinationDetailView(destination: destination)) {
                            HStack {
                                AsyncImage(url: URL(string: destination.pictureURL ?? "")) { image in
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 50, height: 50)
                                } placeholder: {
                                    Circle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 50, height: 50)
                                }
                                .clipShape(Circle())
                                .overlay(
                                    Circle().stroke(Color.gray, lineWidth: 1)
                                )


                                VStack(alignment: .leading) {
                                    Text(destination.city)
                                        .font(.headline)
                                    Text(destination.country)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 5)
                        }
                    }
                }
            }
            .onAppear {
                APIService().fetchDestinations { fetched in
                    self.destinations = fetched
                }
            }
            .navigationTitle("Destinations")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search by city")
        }
    }

    var filteredDestinations: [Destination] {
        if searchText.isEmpty {
            return destinations
        } else {
            return destinations.filter {
                $0.city.lowercased().contains(searchText.lowercased())
            }
        }
    }
}
