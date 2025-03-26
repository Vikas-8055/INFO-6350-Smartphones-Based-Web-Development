import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .white

        let rootVC = UIViewController()
        rootVC.view.backgroundColor = .white
 
        window?.rootViewController = rootVC
        window?.makeKeyAndVisible()

        let mainView = MainView(frame: rootVC.view.bounds)
        rootVC.view.addSubview(mainView)

        return true
    }
}
