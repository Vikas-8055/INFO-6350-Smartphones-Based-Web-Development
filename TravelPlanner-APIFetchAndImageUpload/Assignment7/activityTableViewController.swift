import UIKit

class activityTableViewController: UITableViewController {

    var tripsWithActivities: [Trip] = []
    var activitiesByTrip: [Int32: [Activity]] = [:]

    let searchController = UISearchController(searchResultsController: nil)
    var filteredActivitiesByTrip: [Int32: [Activity]] = [:]
    var isSearching = false

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "All Activities"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ActivityCell")
        navigationItem.leftBarButtonItem = editButtonItem

        // Setup Search
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search by city, trip ID, or activity"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadActivities()
        tableView.reloadData()
    }

    func loadActivities() {
        let allTrips = DataManager.shared.fetchTrips()
        let allActivities = DataManager.shared.fetchActivities()

        activitiesByTrip = Dictionary(grouping: allActivities, by: { $0.trip_id })
        tripsWithActivities = allTrips.filter { activitiesByTrip[$0.id] != nil }
    }

    // MARK: - TableView Sections
    override func numberOfSections(in tableView: UITableView) -> Int {
        return isSearching ? filteredActivitiesByTrip.count : tripsWithActivities.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let tripList = isSearching ? Array(filteredActivitiesByTrip.keys) : tripsWithActivities.map { $0.id }
        if let trip = tripsWithActivities.first(where: { $0.id == tripList[section] }) {
            return "\(trip.title ?? "") (\(trip.startDate ?? "") - \(trip.endDate ?? ""))"
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let tripList = isSearching ? Array(filteredActivitiesByTrip.keys) : tripsWithActivities.map { $0.id }
        let tripId = tripList[section]
        return (isSearching ? filteredActivitiesByTrip[tripId] : activitiesByTrip[tripId])?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ActivityCell", for: indexPath)

        let tripList = isSearching ? Array(filteredActivitiesByTrip.keys) : tripsWithActivities.map { $0.id }
        let tripId = tripList[indexPath.section]
        let activityList = isSearching ? filteredActivitiesByTrip[tripId] : activitiesByTrip[tripId]

        if let activity = activityList?[indexPath.row] {
            let formattedDate = formatDate(activity.date ?? "")
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.text = "\(activity.name ?? ""), \(formattedDate) \(activity.time ?? "")"
        }

        return cell
    }

    // MARK: - Navigation
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tripList = isSearching ? Array(filteredActivitiesByTrip.keys) : tripsWithActivities.map { $0.id }
        let tripId = tripList[indexPath.section]
        let activityList = isSearching ? filteredActivitiesByTrip[tripId] : activitiesByTrip[tripId]

        if let selectedActivity = activityList?[indexPath.row],
           let updateVC = storyboard?.instantiateViewController(identifier: "ActivityUpdateVC") as? activityUpdateViewController {
            updateVC.activity = selectedActivity
            navigationController?.pushViewController(updateVC, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let tripList = isSearching ? Array(filteredActivitiesByTrip.keys) : tripsWithActivities.map { $0.id }
            let tripId = tripList[indexPath.section]
            
            if let activities = isSearching ? filteredActivitiesByTrip[tripId] : activitiesByTrip[tripId],
                   indexPath.row < activities.count {
                       let activityToDelete = activities[indexPath.row]
                
                if DataManager.shared.deleteActivity(id: activityToDelete.id) {
                    // Update data sources
                    if isSearching {
        filteredActivitiesByTrip[tripId]?.remove(at: indexPath.row)
                        // Also update the main data source
                        if let index = activitiesByTrip[tripId]?.firstIndex(of: activityToDelete) {
                            activitiesByTrip[tripId]?.remove(at: index)
                        }
                    } else {
                        activitiesByTrip[tripId]?.remove(at: indexPath.row)
                    }
                    
                    // Update table view
                    tableView.performBatchUpdates({
                        tableView.deleteRows(at: [indexPath], with: .fade)
                        
                        // Remove section if it's now empty
                        if let count = isSearching ? filteredActivitiesByTrip[tripId]?.count : activitiesByTrip[tripId]?.count,
                               count == 0 {
                                   if isSearching {
        filteredActivitiesByTrip.removeValue(forKey: tripId)
                                   } else {
                                       activitiesByTrip.removeValue(forKey: tripId)
                                       tripsWithActivities.removeAll { $0.id == tripId }
                                   }
                                   tableView.deleteSections(IndexSet(integer: indexPath.section), with: .fade)
                               }
                    })
                } else {
                    // Show error if deletion failed
                    let alert = UIAlertController(title: "Error",
                                                  message: "Cannot delete this activity.",
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    present(alert, animated: true)
                }
            }
        }
    }

    // MARK: - Date Formatting Helper
    func formatDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MMMM d"

        if let date = dateFormatter.date(from: dateString) {
            return outputFormatter.string(from: date) + dateSuffix(date)
        }
        return dateString
    }

    func dateSuffix(_ date: Date) -> String {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)

        switch day {
        case 1, 21, 31: return "st"
        case 2, 22: return "nd"
        case 3, 23: return "rd"
        default: return "th"
        }
    }

    // MARK: - Error Alert
    func showNoResultsAlert() {
        let alert = UIAlertController(title: "No Results",
                                      message: "No matching activities, cities, or trip IDs found.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Search Logic
extension activityTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !searchText.isEmpty else {
            isSearching = false
            tableView.reloadData()
            return
        }

        isSearching = true
        filteredActivitiesByTrip.removeAll()

        let allTrips = tripsWithActivities
        var foundMatch = false

        for trip in allTrips {
            guard let activities = activitiesByTrip[trip.id] else { continue }

            // Match by city, trip ID, or activity name
            let matches = activities.filter {
                let cityMatch = trip.destination?.city?.lowercased().contains(searchText.lowercased()) ?? false
                let tripIdMatch = String(trip.id) == searchText
                let activityNameMatch = $0.name?.lowercased().contains(searchText.lowercased()) ?? false
                return cityMatch || tripIdMatch || activityNameMatch
            }

            if !matches.isEmpty {
                filteredActivitiesByTrip[trip.id] = matches
                foundMatch = true
            }
        }

        if !foundMatch {
            isSearching = false
            tableView.reloadData()
            showNoResultsAlert()
        } else {
            tableView.reloadData()
        }
    }
}
