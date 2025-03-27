import UIKit

class activityTableViewController: UITableViewController, UISearchResultsUpdating, UISearchBarDelegate {

    var tripsWithActivities: [Trip] = []
    var activitiesByTrip: [Int32: [Activity]] = [:]

    var allTrips: [Trip] = []
    var allActivities: [Activity] = []
    var isSearching = false

    let searchController = UISearchController(searchResultsController: nil)

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "All Activities"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ActivityCell")
        navigationItem.leftBarButtonItem = editButtonItem

        setupSearch()
    }

    func setupSearch() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search by Trip ID or Activity Name"
        searchController.searchBar.delegate = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        allTrips = DataManager.shared.fetchTrips()
        allActivities = DataManager.shared.fetchActivities()
        loadActivities()
    }

    func loadActivities() {
        if isSearching {
            return
        }
        activitiesByTrip = Dictionary(grouping: allActivities, by: { $0.trip_id })
        tripsWithActivities = allTrips.filter { activitiesByTrip[$0.id] != nil }
        tableView.reloadData()
    }

    func updateSearchResults(for searchController: UISearchController) {
        let query = searchController.searchBar.text?.lowercased() ?? ""
        if query.isEmpty {
            isSearching = false
            loadActivities()
            return
        }

        isSearching = true
        let matchedActivities = allActivities.filter {
            ($0.name?.lowercased().contains(query) ?? false) || "\( $0.trip_id )" == query
        }

        if matchedActivities.isEmpty {
            isSearching = false
            showAlert(message: "No matching activities found for \"\(query)\".")
            loadActivities()
            return
        }

        activitiesByTrip = Dictionary(grouping: matchedActivities, by: { $0.trip_id })
        tripsWithActivities = allTrips.filter { activitiesByTrip[$0.id] != nil }
        tableView.reloadData()
    }

    func showAlert(message: String) {
        let alert = UIAlertController(title: "No Results", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return tripsWithActivities.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let trip = tripsWithActivities[section]
        return "\(trip.title ?? "") (\(trip.startDate ?? "") - \(trip.endDate ?? ""))"
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let trip = tripsWithActivities[section]
        return activitiesByTrip[trip.id]?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ActivityCell", for: indexPath)
        let trip = tripsWithActivities[indexPath.section]
        if let activity = activitiesByTrip[trip.id]?[indexPath.row] {
            let formattedDate = formatDate(activity.date ?? "")
            cell.textLabel?.text = "\(activity.name ?? ""), \(formattedDate) \(activity.time ?? "")"
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let trip = tripsWithActivities[indexPath.section]
        if let activity = activitiesByTrip[trip.id]?[indexPath.row],
           let vc = storyboard?.instantiateViewController(identifier: "ActivityUpdateVC") as? activityUpdateViewController {
            vc.activity = activity
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "MMM d"
            return outputFormatter.string(from: date)
        }
        return dateString
    }
}
