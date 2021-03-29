import UIKit
import Photos
import CoreData

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        LinksDataService.shared.saveContext()
    }
    
}

