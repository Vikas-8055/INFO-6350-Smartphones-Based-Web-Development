import UIKit

class tripTableViewController: UITableViewController {

    var destinationsWithTrips: [Destination] = []
    var tripsByDestination: [Int32: [Trip]] = [:]

    let searchController = UISearchController(searchResultsController: nil)
    var filteredTripsByDestination: [Int32: [Trip]] = [:]
    var isSearching = false

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "All Trips"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "TripCell")
        navigationItem.leftBarButtonItem = editButtonItem

        // Setup search controller
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search by city, trip ID, or activity"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadTrips()
        tableView.reloadData()
    }

    func loadTrips() {
        let allDestinations = DataManager.shared.fetchDestinations()
        let allTrips = DataManager.shared.fetchTrips()

        tripsByDestination = Dictionary(grouping: allTrips, by: { $0.destinationID })
        destinationsWithTrips = allDestinations.filter { tripsByDestination[$0.id] != nil }
        tableView.reloadData()
        print("Loaded \(allDestinations.count) destinations and \(allTrips.count) trips from Core Data")
    }

    // MARK: - TableView Sections
    override func numberOfSections(in tableView: UITableView) -> Int {
        return isSearching ? filteredTripsByDestination.count : destinationsWithTrips.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let destinationList = isSearching ? Array(filteredTripsByDestination.keys) : destinationsWithTrips.map { $0.id }
        if let destination = destinationsWithTrips.first(where: { $0.id == destinationList[section] }) {
            return "\(destination.city ?? ""), \(destination.country ?? "")"
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let destinationList = isSearching ? Array(filteredTripsByDestination.keys) : destinationsWithTrips.map { $0.id }
        let destinationId = destinationList[section]
        return (isSearching ? filteredTripsByDestination[destinationId] : tripsByDestination[destinationId])?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TripCell", for: indexPath)

        let destinationList = isSearching ? Array(filteredTripsByDestination.keys) : destinationsWithTrips.map { $0.id }
        let destinationId = destinationList[indexPath.section]
        let tripList = isSearching ? filteredTripsByDestination[destinationId] : tripsByDestination[destinationId]

        if let trip = tripList?[indexPath.row] {
            let formattedDateRange = formatDateRange(startDate: trip.startDate ?? "", endDate: trip.endDate ?? "")
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.text = "\(trip.title ?? "")\n\(formattedDateRange)"
        }

        return cell
    }

    // MARK: - Navigation
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let destinationList = isSearching ? Array(filteredTripsByDestination.keys) : destinationsWithTrips.map { $0.id }
        let destinationId = destinationList[indexPath.section]
        let tripList = isSearching ? filteredTripsByDestination[destinationId] : tripsByDestination[destinationId]

        if let selectedTrip = tripList?[indexPath.row],
           let updateVC = storyboard?.instantiateViewController(identifier: "UpdateTripVC") as? tripUpdateViewController {
            updateVC.trip = selectedTrip
            navigationController?.pushViewController(updateVC, animated: true)
        }
    }

    // MARK: - Deletion
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let destinationList = isSearching ? Array(filteredTripsByDestination.keys) : destinationsWithTrips.map { $0.id }
            let destinationId = destinationList[indexPath.section]
            var tripList = isSearching ? filteredTripsByDestination[destinationId] : tripsByDestination[destinationId]

            if let trip = tripList?[indexPath.row] {
                if DataManager.shared.deleteTrip(id: trip.id) {
                    tripList?.remove(at: indexPath.row)

                    if isSearching {
                        filteredTripsByDestination[destinationId] = tripList?.isEmpty ?? true ? nil : tripList
                        loadTrips()
                    } else {
                        tripsByDestination[destinationId] = tripList?.isEmpty ?? true ? nil : tripList
                        destinationsWithTrips = destinationsWithTrips.filter { tripsByDestination[$0.id] != nil }
                    }

                    tableView.reloadData()
                } else {
                    let alert = UIAlertController(title: "Error",
                                                  message: "Cannot delete this trip as it has linked activities or expenses.",
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    present(alert, animated: true)
                }
            }
        }
    }

    // MARK: - Date Formatting
    func formatDateRange(startDate: String, endDate: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MMMM d"

        if let start = dateFormatter.date(from: startDate),
           let end = dateFormatter.date(from: endDate) {
            let formattedStart = outputFormatter.string(from: start)
            let formattedEnd = outputFormatter.string(from: end)
            return "\(formattedStart) - \(formattedEnd)"
        }

        return "\(startDate) - \(endDate)"
    }

    // MARK: - No Results Alert
    func showNoResultsAlert() {
        let alert = UIAlertController(title: "No Results",
                                      message: "No matching trips found for the given city, trip ID, or activity name.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Search Logic
extension tripTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let query = searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !query.isEmpty else {
            isSearching = false
            tableView.reloadData()
            return
        }

        let lowerQuery = query.lowercased()
        let allActivities = DataManager.shared.fetchActivities()
        let allTrips = DataManager.shared.fetchTrips()

        var matchedTripIDs = Set<Int32>()

        // 1. Match by destination city
        for trip in allTrips {
            if let city = trip.destination?.city?.lowercased(), city.contains(lowerQuery) {
                matchedTripIDs.insert(trip.id)
            }
        }

        // 2. Match by trip ID
        if let tripId = Int32(query), allTrips.contains(where: { $0.id == tripId }) {
            matchedTripIDs.insert(tripId)
        }

        // 3. Match by activity name
        for activity in allActivities {
            if activity.name?.lowercased().contains(lowerQuery) == true,
               let tripId = activity.trip?.id {
                matchedTripIDs.insert(tripId)
            }
        }


        // Filter trips
        filteredTripsByDestination.removeAll()
        for destination in destinationsWithTrips {
            if let trips = tripsByDestination[destination.id] {
                let matchedTrips = trips.filter { matchedTripIDs.contains($0.id) }
                if !matchedTrips.isEmpty {
                    filteredTripsByDestination[destination.id] = matchedTrips
                }
            }
        }

        if filteredTripsByDestination.isEmpty {
            isSearching = false
            tableView.reloadData()
            showNoResultsAlert()
        } else {
            isSearching = true
            tableView.reloadData()
        }
    }
}
