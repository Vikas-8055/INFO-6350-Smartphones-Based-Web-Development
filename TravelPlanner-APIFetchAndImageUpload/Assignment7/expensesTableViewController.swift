import UIKit

class expensesTableViewController: UITableViewController {

    var tripsWithExpenses: [Trip] = []
    var expensesByTrip: [Int32: [Expense]] = [:]

    let searchController = UISearchController(searchResultsController: nil)
    var filteredExpensesByTrip: [Int32: [Expense]] = [:]
    var isSearching = false

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "All Expenses"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ExpenseCell")
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
        loadExpenses()
        tableView.reloadData()
    }

    func loadExpenses() {
        let allTrips = DataManager.shared.fetchTrips()
        let allExpenses = DataManager.shared.fetchExpenses()

        expensesByTrip = Dictionary(grouping: allExpenses, by: { $0.trip_id })
        tripsWithExpenses = allTrips.filter { expensesByTrip[$0.id] != nil }
    }

    // MARK: - TableView Sections
    override func numberOfSections(in tableView: UITableView) -> Int {
        return isSearching ? filteredExpensesByTrip.count : tripsWithExpenses.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let tripList = isSearching ? Array(filteredExpensesByTrip.keys) : tripsWithExpenses.map { $0.id }
        if let trip = tripsWithExpenses.first(where: { $0.id == tripList[section] }) {
            return "\(trip.title ?? "") (\(trip.startDate ?? "") - \(trip.endDate ?? ""))"
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let tripList = isSearching ? Array(filteredExpensesByTrip.keys) : tripsWithExpenses.map { $0.id }
        let tripId = tripList[section]
        return (isSearching ? filteredExpensesByTrip[tripId] : expensesByTrip[tripId])?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ExpenseCell", for: indexPath)

        let tripList = isSearching ? Array(filteredExpensesByTrip.keys) : tripsWithExpenses.map { $0.id }
        let tripId = tripList[indexPath.section]
        let expenseList = isSearching ? filteredExpensesByTrip[tripId] : expensesByTrip[tripId]

        if let expense = expenseList?[indexPath.row] {
            cell.textLabel?.numberOfLines = 0
            let title = expense.title ?? "Untitled"
            let amount = String(format: "%.2f", expense.amount)
            let date = expense.date ?? "Unknown Date"
            cell.textLabel?.text = "\(title) - $\(amount)\n\(date)"
        }

        return cell
    }

    // MARK: - Navigation
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tripList = isSearching ? Array(filteredExpensesByTrip.keys) : tripsWithExpenses.map { $0.id }
        let tripId = tripList[indexPath.section]
        let expenseList = isSearching ? filteredExpensesByTrip[tripId] : expensesByTrip[tripId]

        if let selectedExpense = expenseList?[indexPath.row],
           let updateVC = storyboard?.instantiateViewController(identifier: "ExpenseUpdateVC") as? expensesUpdateViewController {
            updateVC.expense = selectedExpense
            navigationController?.pushViewController(updateVC, animated: true)
        }
    }

    // MARK: - Deletion
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let tripList = isSearching ? Array(filteredExpensesByTrip.keys) : tripsWithExpenses.map { $0.id }
            let tripId = tripList[indexPath.section]
            var expenseList = isSearching ? filteredExpensesByTrip[tripId] : expensesByTrip[tripId]

            if let expense = expenseList?[indexPath.row] {
                if DataManager.shared.deleteExpense(id: expense.id) {
                    expenseList?.remove(at: indexPath.row)

                    if isSearching {
                        filteredExpensesByTrip[tripId] = expenseList?.isEmpty ?? true ? nil : expenseList
                        loadExpenses()
                    } else {
                        expensesByTrip[tripId] = expenseList?.isEmpty ?? true ? nil : expenseList
                        tripsWithExpenses = tripsWithExpenses.filter { expensesByTrip[$0.id] != nil }
                    }

                    tableView.reloadData()
                } else {
                    let alert = UIAlertController(title: "Error",
                                                  message: "Cannot delete this expense as it's older than 30 days.",
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    present(alert, animated: true)
                }
            }
        }
    }

    // MARK: - Show No Results Alert
    func showNoResultsAlert() {
        let alert = UIAlertController(title: "No Results",
                                      message: "No matching expenses found for that city, trip ID, or activity name.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Search Logic
extension expensesTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let query = searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !query.isEmpty else {
            isSearching = false
            tableView.reloadData()
            return
        }

        let allActivities = DataManager.shared.fetchActivities()
        let allTrips = DataManager.shared.fetchTrips()
        let lowerQuery = query.lowercased()
        var resultTripIDs = Set<Int32>()

        // 1. Match by destination city
        for trip in allTrips {
            if let city = trip.destination?.city?.lowercased(), city.contains(lowerQuery) {
                resultTripIDs.insert(trip.id)
            }
        }

        // 2. Match by Trip ID
        if let tripId = Int32(query), allTrips.contains(where: { $0.id == tripId }) {
            resultTripIDs.insert(tripId)
        }

        var matchedTripIDs = Set<Int32>()

        for activity in allActivities {
            if activity.name?.lowercased().contains(lowerQuery) == true,
               let tripId = activity.trip?.id {
                matchedTripIDs.insert(tripId)
            }
        }



        // Now filter expenses
        filteredExpensesByTrip.removeAll()
        for tripId in resultTripIDs {
            if let expenses = expensesByTrip[tripId], !expenses.isEmpty {
                filteredExpensesByTrip[tripId] = expenses
            }
        }

        if filteredExpensesByTrip.isEmpty {
            isSearching = false
            tableView.reloadData()
            showNoResultsAlert()
        } else {
            isSearching = true
            tableView.reloadData()
        }
    }
}
