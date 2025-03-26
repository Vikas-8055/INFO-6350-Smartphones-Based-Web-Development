import UIKit

class destinationTableViewController: UITableViewController, UISearchResultsUpdating {

    var destinations: [Destination] = []
    var filteredDestinations: [Destination] = []

    let searchController = UISearchController(searchResultsController: nil)

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Destinations"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DestinationCell")
        navigationItem.leftBarButtonItem = editButtonItem

        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = "Search by City or ID"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        destinations = DataManager.shared.fetchDestinations()
        filteredDestinations = destinations
        tableView.reloadData()
    }

    func updateSearchResults(for searchController: UISearchController) {
        let query = searchController.searchBar.text?.lowercased() ?? ""
        if query.isEmpty {
            filteredDestinations = destinations
        } else {
            filteredDestinations = destinations.filter {
                ($0.city?.lowercased().contains(query) ?? false) || "\( $0.id )" == query
            }
        }

        if filteredDestinations.isEmpty {
            showAlert(message: "No destinations found for \"\(query)\".")
        }

        tableView.reloadData()
    }

    func showAlert(message: String) {
        let alert = UIAlertController(title: "No Results", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredDestinations.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DestinationCell", for: indexPath)
        let dest = filteredDestinations[indexPath.row]
        cell.textLabel?.text = "\(dest.city ?? ""), \(dest.country ?? "")"
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let destination = filteredDestinations[indexPath.row]
        if let vc = storyboard?.instantiateViewController(identifier: "UpdateDestinationVC") as? destinationUpdateViewController {
            vc.destination = destination
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}
