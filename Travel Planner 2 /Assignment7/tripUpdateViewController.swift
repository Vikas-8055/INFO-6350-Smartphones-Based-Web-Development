import UIKit

class tripUpdateViewController: UIViewController {
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var endDatePicker: UIDatePicker!
    
    var trip: Trip?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Update Trip"
        
        if let trip = trip {
            titleTextField.text = trip.title
            endDatePicker.date = parseDate(trip.endDate) ?? Date()
        }
    }

    @IBAction func updateButtonTapped(_ sender: UIButton) {
    
        guard let newTitle = titleTextField.text, !newTitle.isEmpty,
              let tripId = trip?.id,
              let trip = trip,
              let startDate = parseDate(trip.startDate) else {
            showAlert(message: "Title cannot be empty and start date must be valid.")
            return
        }
        
        let newEndDate = endDatePicker.date

        if newEndDate < startDate {
            showAlert(message: "End date cannot be before start date.")
            return
        }
        
        let newEndDateStr = formatDate(newEndDate)
        DataManager.shared.updateTrip(id: tripId, newTitle: newTitle, newEndDate: newEndDateStr)
        navigationController?.popViewController(animated: true)
    }

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
    

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Invalid Input", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
