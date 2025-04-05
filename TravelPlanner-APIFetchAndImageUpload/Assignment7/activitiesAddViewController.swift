import UIKit

class activitiesAddViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    var trips: [Trip] = []
    var selectedTripId: Int32?

    @IBOutlet weak var activityIdTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var timePicker: UIDatePicker!
    @IBOutlet weak var locationTextField: UITextField!
    @IBOutlet weak var tripPickerView: UIPickerView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Add Activity"

        activityIdTextField.keyboardType = .numberPad

        tripPickerView.delegate = self
        tripPickerView.dataSource = self

        trips = DataManager.shared.fetchTrips() // Core Data fetch

        if !trips.isEmpty {
            selectedTripId = trips[0].id
        }
    }

    @IBAction func saveButtonTapped(_ sender: UIButton) {
        guard let activityIdText = activityIdTextField.text, let activityId = Int32(activityIdText),
              let tripId = selectedTripId,
              let activityName = nameTextField.text, !activityName.isEmpty,
              let location = locationTextField.text, !location.isEmpty else {
            showAlert(message: "All fields must be filled, and ID must be a number.")
            return
        }

        // Format date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateStr = dateFormatter.string(from: datePicker.date)

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "hh:mm a"
        let timeStr = timeFormatter.string(from: timePicker.date)

        // Check for duplicate ID using Core Data fetch
        let existing = DataManager.shared.fetchActivities().contains { $0.id == activityId }
        if existing {
            showAlert(message: "Activity ID is already taken. Please use a different ID.")
            return
        }

        // Core Data save
        DataManager.shared.addActivity(id: activityId, tripId: tripId, name: activityName, date: dateStr, time: timeStr, location: location)

        navigationController?.popViewController(animated: true)
    }

    // MARK: - UIPickerView Data Source & Delegate

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return trips.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let trip = trips[row]
        return "\(trip.title ?? "") (\(trip.startDate ?? "") - \(trip.endDate ?? ""))"
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedTripId = trips[row].id
    }

    // MARK: - Alert Helper
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Invalid Input", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
