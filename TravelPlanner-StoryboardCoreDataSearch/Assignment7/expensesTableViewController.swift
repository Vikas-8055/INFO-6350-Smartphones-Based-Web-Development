import UIKit

class expensesTableViewController: UITableViewController, UISearchResultsUpdating {

    var tripsWithExpenses: [Trip] = []
    var expensesByTrip: [Int32: [Expense]] = [:]
    var allTrips: [Trip] = []
    var allExpenses: [Expense] = []

    let searchController = UISearchController(searchResultsController: nil)

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "All Expenses"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier:"ExpenseCell")
        navigationItem.leftBarButtonItem = editButtonItem
        setupSearch()
    }

    func setupSearch() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search by ID or Title"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        allTrips = DataManager.shared.fetchTrips()
        allExpenses = DataManager.shared.fetchExpenses()
        loadExpenses()
    }

    func loadExpenses() {
        let grouped = Dictionary(grouping: allExpenses, by: { $0.trip_id })
        expensesByTrip = grouped
        tripsWithExpenses = allTrips.filter { grouped[$0.id] != nil }
        tableView.reloadData()
    }

    func updateSearchResults(for searchController: UISearchController) {
        let query = searchController.searchBar.text?.lowercased() ?? ""
        if query.isEmpty {
            loadExpenses()
            return
        }

        let filtered = allExpenses.filter {
            ($0.title?.lowercased().contains(query) ?? false) || "\( $0.id )" == query
        }

        if filtered.isEmpty {
            showAlert(message: "No expenses found for \"\(query)\".")
            loadExpenses()
            return
        }

        expensesByTrip = Dictionary(grouping: filtered, by: { $0.trip_id })
        tripsWithExpenses = allTrips.filter { expensesByTrip[$0.id] != nil }
        tableView.reloadData()
    }

    func showAlert(message: String) {
        let alert = UIAlertController(title: "No Results", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return tripsWithExpenses.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let trip = tripsWithExpenses[section]
        return "\(trip.title ?? "") (\(trip.startDate ?? "") - \(trip.endDate ?? ""))"
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let trip = tripsWithExpenses[section]
        return expensesByTrip[trip.id]?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ExpenseCell", for: indexPath)
        let trip = tripsWithExpenses[indexPath.section]
        if let expense = expensesByTrip[trip.id]?[indexPath.row] {
            let amount = String(format: "%.2f", expense.amount)
            let date = expense.date ?? ""
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.text = "\(expense.title ?? "Untitled") - $\(amount)\n\(date)"
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let trip = tripsWithExpenses[indexPath.section]
        if let expense = expensesByTrip[trip.id]?[indexPath.row],
           let vc = storyboard?.instantiateViewController(identifier: "ExpenseUpdateVC") as? expensesUpdateViewController {
            vc.expense = expense
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}


