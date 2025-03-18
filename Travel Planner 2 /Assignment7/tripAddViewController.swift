import UIKit

class tripAddViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var tripIdTextField: UITextField!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var startDatePicker: UIDatePicker!
    @IBOutlet weak var endDatePicker: UIDatePicker!
    @IBOutlet weak var destinationPicker: UIPickerView!
    
    var selectedDestinationId: Int?
    var destinations: [Destination] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Add Trip"

        tripIdTextField.keyboardType = .numberPad

     
        destinations = DataManager.shared.destinations
        
        if let firstDestination = destinations.first {
            selectedDestinationId = firstDestination.id
        }
        
        destinationPicker.delegate = self
        destinationPicker.dataSource = self
        
     
        startDatePicker.minimumDate = Date()
        endDatePicker.minimumDate = Date()
    }

    @IBAction func saveButtonTapped(_ sender: UIButton) {

        guard let tripIdText = tripIdTextField.text, let tripId = Int(tripIdText),
              let tripTitle = titleTextField.text, !tripTitle.isEmpty,
              let destinationId = selectedDestinationId else {
            showAlert(message: "All fields must be filled, and ID must be a number.")
            return
        }
        
        let startDate = startDatePicker.date
        let endDate = endDatePicker.date
        
       
        if startDate > endDate {
            showAlert(message: "Start date cannot be after End date.")
            return
        }
        
        let startDateStr = formatDate(startDate)
        let endDateStr = formatDate(endDate)
        

        if DataManager.shared.trips.contains(where: { $0.id == tripId }) {
                showAlert(message: "Trip ID is already taken. Please use a different ID.")
                return
            }
        DataManager.shared.addTrip(id: tripId, destinationId: destinationId, title: tripTitle, startDate: startDateStr, endDate: endDateStr)
        navigationController?.popViewController(animated: true)
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }


    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return destinations.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let destination = destinations[row]
        return "\(destination.city), \(destination.country)"
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedDestinationId = destinations[row].id
    }
    
 
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Invalid Input", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
