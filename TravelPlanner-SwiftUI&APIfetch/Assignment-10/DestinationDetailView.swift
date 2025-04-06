import SwiftUI

struct DestinationDetailView: View {
    let destination: Destination
    
    var body: some View {
        VStack(spacing: 20) {
            AsyncImage(url: URL(string: destination.pictureURL ?? "")) { image in
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
            } placeholder: {
                ProgressView()
            }
            .clipShape(Circle())
            .overlay(
                Circle().stroke(Color.gray, lineWidth: 2)
            )
            .shadow(radius: 10)
            
            Text(destination.city)
                .font(.title)
                .padding(.top)
            Text("Country: \(destination.country)")
                .font(.subheadline)
        }
        .padding()
        .navigationTitle("Destination Details")
    }
}
