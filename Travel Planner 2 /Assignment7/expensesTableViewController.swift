import UIKit

class expensesTableViewController: UITableViewController {
    
    var tripsWithExpenses: [Trip] = []
    var expensesByTrip: [Int: [Expense]] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "All Expenses"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ExpenseCell")
        
        navigationItem.leftBarButtonItem = editButtonItem
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadExpenses()
        tableView.reloadData()
    }

    func loadExpenses() {
        let allTrips = DataManager.shared.trips
        let allExpenses = DataManager.shared.expenses
        
        expensesByTrip = Dictionary(grouping: allExpenses, by: { $0.tripId })

  
        tripsWithExpenses = allTrips.filter { expensesByTrip[$0.id] != nil }
    }


    override func numberOfSections(in tableView: UITableView) -> Int {
        return tripsWithExpenses.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let trip = tripsWithExpenses[section]
        return "\(trip.title) (\(trip.startDate) - \(trip.endDate))"
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let trip = tripsWithExpenses[section]
        return expensesByTrip[trip.id]?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ExpenseCell", for: indexPath)
        let trip = tripsWithExpenses[indexPath.section]
        if let expenses = expensesByTrip[trip.id] {
            let expense = expenses[indexPath.row]
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.text = "\(expense.title) - $\(expense.amount)\n\(expense.date)"
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let trip = tripsWithExpenses[indexPath.section]
        if let expenses = expensesByTrip[trip.id] {
            let selectedExpense = expenses[indexPath.row]
            
            if let updateVC = storyboard?.instantiateViewController(identifier: "ExpenseUpdateVC") as? expensesUpdateViewController {
                updateVC.expense = selectedExpense
                navigationController?.pushViewController(updateVC, animated: true)
            }
        }
    }

 
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let trip = tripsWithExpenses[indexPath.section]
            if var expenses = expensesByTrip[trip.id] {
                let expense = expenses[indexPath.row]

                if DataManager.shared.deleteExpense(id: expense.id) {
                    expenses.remove(at: indexPath.row)
                    expensesByTrip[trip.id] = expenses.isEmpty ? nil : expenses
                    tripsWithExpenses = tripsWithExpenses.filter { expensesByTrip[$0.id] != nil }
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
}
