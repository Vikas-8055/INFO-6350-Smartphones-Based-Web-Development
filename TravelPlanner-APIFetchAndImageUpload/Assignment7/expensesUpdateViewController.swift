import UIKit

class expensesUpdateViewController: UIViewController {

    var expense: Expense?

    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Update Expense"
        setupUI()
    }

    func setupUI() {
        guard let expense = expense else { return }

        titleTextField.text = expense.title
        amountTextField.text = String(expense.amount)
        amountTextField.keyboardType = .decimalPad

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        if let dateStr = expense.date, let date = dateFormatter.date(from: dateStr) {
            datePicker.date = date
        }
    }

    @IBAction func updateExpenseTapped(_ sender: UIButton) {
        guard let updatedTitle = titleTextField.text, !updatedTitle.isEmpty,
              let updatedAmountStr = amountTextField.text, !updatedAmountStr.isEmpty,
              let updatedAmount = Double(updatedAmountStr) else {
            showAlert(message: "All fields are required, and amount must be a valid number.")
            return
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let updatedDate = dateFormatter.string(from: datePicker.date)

        if let expense = expense {
            expense.title = updatedTitle
            expense.amount = updatedAmount
            expense.date = updatedDate

            do {
                try expense.managedObjectContext?.save()
                navigationController?.popViewController(animated: true)
            } catch {
                showAlert(message: "Failed to save changes: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Alert Helper
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Invalid Input", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
