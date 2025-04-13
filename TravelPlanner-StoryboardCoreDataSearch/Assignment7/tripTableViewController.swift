import UIKit

class tripTableViewController: UITableViewController, UISearchResultsUpdating {

    var destinationsWithTrips: [Destination] = []
    var tripsByDestination: [Int32: [Trip]] = [:]

    var allDestinations: [Destination] = []
    var allTrips: [Trip] = []

    let searchController = UISearchController(searchResultsController: nil)

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "All Trips"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "TripCell")
        navigationItem.leftBarButtonItem = editButtonItem
        setupSearch()
    }

    func setupSearch() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search by Trip ID or Title or City"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        allDestinations = DataManager.shared.fetchDestinations()
        allTrips = DataManager.shared.fetchTrips()
        loadTrips()
    }

    func loadTrips() {
        tripsByDestination = Dictionary(grouping: allTrips, by: { $0.destinationID })
        destinationsWithTrips = allDestinations.filter { tripsByDestination[$0.id] != nil }
        tableView.reloadData()
    }

    func updateSearchResults(for searchController: UISearchController) {
        let query = searchController.searchBar.text?.lowercased() ?? ""

        if query.isEmpty {
            loadTrips()
            return
        }

        let filteredTrips = allTrips.filter {
            ($0.title?.lowercased().contains(query) ?? false) || "\( $0.id )" == query
        }

        let filteredDestinations = allDestinations.filter {
            $0.city?.lowercased().contains(query) ?? false
        }

        var matchingTripsByDestination: [Int32: [Trip]] = [:]

        for trip in filteredTrips {
            matchingTripsByDestination[trip.destinationID, default: []].append(trip)
        }

        for dest in filteredDestinations {
            let trips = allTrips.filter { $0.destinationID == dest.id }
            if !trips.isEmpty {
                matchingTripsByDestination[dest.id] = trips
            }
        }

        if matchingTripsByDestination.isEmpty {
            showAlert(message: "No trips found for \"\(query)\".")
            loadTrips()
            return
        }

        tripsByDestination = matchingTripsByDestination
        destinationsWithTrips = allDestinations.filter { tripsByDestination[$0.id] != nil }
        tableView.reloadData()
    }

    func showAlert(message: String) {
        let alert = UIAlertController(title: "No Results", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return destinationsWithTrips.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let dest = destinationsWithTrips[section]
        return "\(dest.city ?? ""), \(dest.country ?? "")"
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let dest = destinationsWithTrips[section]
        return tripsByDestination[dest.id]?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TripCell", for: indexPath)
        let dest = destinationsWithTrips[indexPath.section]
        if let trip = tripsByDestination[dest.id]?[indexPath.row] {
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.text = "\(trip.title ?? "")\n\(trip.startDate ?? "") - \(trip.endDate ?? "")"
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let dest = destinationsWithTrips[indexPath.section]
        if let trip = tripsByDestination[dest.id]?[indexPath.row],
           let vc = storyboard?.instantiateViewController(identifier: "UpdateTripVC") as? tripUpdateViewController {
            vc.trip = trip
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}
