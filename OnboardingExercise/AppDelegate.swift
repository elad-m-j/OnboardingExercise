import UIKit
import Photos
import CoreData

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
//        print("Default document directory: \(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))")
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        if let rootViewController = window?.rootViewController as? GalleryCollectionViewController {
            rootViewController.sessionService.linkDataService.saveContext()
        }
    }
    
}
