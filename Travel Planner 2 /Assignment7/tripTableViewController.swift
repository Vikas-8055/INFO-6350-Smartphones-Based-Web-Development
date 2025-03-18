import UIKit

class tripTableViewController: UITableViewController {
    
    var destinationsWithTrips: [Destination] = []
    var tripsByDestination: [Int: [Trip]] = [:] // Group trips by destinationId

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "All Trips"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "TripCell")
        
        navigationItem.leftBarButtonItem = editButtonItem
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadTrips()
        tableView.reloadData()
    }

    func loadTrips() {
        let allDestinations = DataManager.shared.destinations
        let allTrips = DataManager.shared.trips


        tripsByDestination = Dictionary(grouping: allTrips, by: { $0.destinationId })

        destinationsWithTrips = allDestinations.filter { tripsByDestination[$0.id] != nil }
    }


    override func numberOfSections(in tableView: UITableView) -> Int {
        return destinationsWithTrips.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let destination = destinationsWithTrips[section]
        return "\(destination.city), \(destination.country)"
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let destination = destinationsWithTrips[section]
        return tripsByDestination[destination.id]?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TripCell", for: indexPath)
        let destination = destinationsWithTrips[indexPath.section]
        if let trips = tripsByDestination[destination.id] {
            let trip = trips[indexPath.row]
            let formattedDateRange = formatDateRange(startDate: trip.startDate, endDate: trip.endDate)
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.text = "\(trip.title)\n\(formattedDateRange)"
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let destination = destinationsWithTrips[indexPath.section]
        if let trips = tripsByDestination[destination.id] {
            let selectedTrip = trips[indexPath.row]
            if let updateVC = storyboard?.instantiateViewController(identifier: "UpdateTripVC") as? tripUpdateViewController {
                updateVC.trip = selectedTrip
                navigationController?.pushViewController(updateVC, animated: true)
            }
        }
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let destination = destinationsWithTrips[indexPath.section]
            if var trips = tripsByDestination[destination.id] {
                let trip = trips[indexPath.row]
                
                if DataManager.shared.deleteTrip(id: trip.id) {
                    trips.remove(at: indexPath.row)
                    tripsByDestination[destination.id] = trips.isEmpty ? nil : trips
                    destinationsWithTrips = destinationsWithTrips.filter { tripsByDestination[$0.id] != nil }
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
}
