import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DestinationView()
                .tabItem {
                    Image(systemName: "mappin.and.ellipse")
                    Text("Destinations")
                }

            TripView()
                .tabItem {
                    Image(systemName: "airplane")
                    Text("Trips")
                }
        }
    }
}

#Preview {
    ContentView()
}
