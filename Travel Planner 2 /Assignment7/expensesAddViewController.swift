import UIKit

class expensesAddViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var trips: [Trip] = []
    var selectedTripId: Int?

    @IBOutlet weak var expenseIdTextField: UITextField!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var tripPickerView: UIPickerView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Add Expense"

        expenseIdTextField.keyboardType = .numberPad // Restrict input to numbers
        amountTextField.keyboardType = .decimalPad

        tripPickerView.delegate = self
        tripPickerView.dataSource = self

        trips = DataManager.shared.trips // Load available trips
        
        if !trips.isEmpty {
            selectedTripId = trips[0].id // Default selection
        }
    }

    @IBAction func saveButtonTapped(_ sender: UIButton) {
        guard let expenseIdText = expenseIdTextField.text, let expenseId = Int(expenseIdText),
              let tripId = selectedTripId,
              let title = titleTextField.text, !title.isEmpty,
              let amountText = amountTextField.text, let amount = Double(amountText) else {
            showAlert(message: "All fields are required and amount must be a valid number.")
            return
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.string(from: datePicker.date)

        if DataManager.shared.expenses.contains(where: { $0.id == expenseId }) {
               showAlert(message: "Expense ID is already taken. Please use a different ID.")
               return
           }
        
        DataManager.shared.addExpense(id: expenseId, tripId: tripId, title: title, amount: amount, date: date)

        navigationController?.popViewController(animated: true)
    }

    func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }


    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return trips.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let trip = trips[row]
        return "\(trip.title) (\(trip.startDate) - \(trip.endDate))"
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedTripId = trips[row].id // Update selected trip ID
    }
}
