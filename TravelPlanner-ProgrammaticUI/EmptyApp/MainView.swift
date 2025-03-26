import UIKit

class MainView: UIView {

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Main Menu"
        label.textAlignment = .center
        label.font = .boldSystemFont(ofSize: 24)
        return label
    }()

    private let destinationsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Manage Destinations", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        return button
    }()

    private let tripsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Manage Trips", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white

        addSubview(titleLabel)
        addSubview(destinationsButton)
        addSubview(tripsButton)

        titleLabel.frame = CGRect(x: 0, y: 100, width: frame.size.width, height: 40)
        destinationsButton.frame = CGRect(x: 40, y: 200, width: frame.size.width - 80, height: 50)
        tripsButton.frame = CGRect(x: 40, y: 300, width: frame.size.width - 80, height: 50)

        destinationsButton.addTarget(self, action: #selector(openDestinationsView), for: .touchUpInside)
        tripsButton.addTarget(self, action: #selector(openTripsView), for: .touchUpInside)
    }

    @objc private func openDestinationsView() {
        let destView = DestinationsView(frame: bounds)
        addSubview(destView)
    }

    @objc private func openTripsView() {
        let tripsView = TripsView(frame: bounds)
        addSubview(tripsView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
