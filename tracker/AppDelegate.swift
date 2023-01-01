import AppFeature
import ComposableArchitecture
import CoreLocation
import Foundation
import LoggerFeature
import UIKit
import RealmSwift

@main
final class AppDelegate: NSObject, UIApplicationDelegate {
  
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    
    UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .sound, .provisional, .alert], completionHandler: { result, error in
      log("result, \(result) error \(error)")
    })

    TrackerLogger.setup()
    log("didFinishLaunchingWithOptions")
    if let locationKey = launchOptions?[UIApplication.LaunchOptionsKey.location] {
      log("started app with location key \(locationKey)")
    }
    
    return true
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
  func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    completionHandler([.badge, .list, .sound])
  }
  
  func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
          print(response.notification.request.content.userInfo)
          completionHandler()
      }
}


extension AppDelegate {
  static func notification(title: String, body: String) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.badge = 0
    content.categoryIdentifier = "actionCategory"
    content.sound = UNNotificationSound.default


    var dateComponents = Calendar.current.dateComponents([.weekday, .hour], from: Date().addingTimeInterval(1))
    dateComponents.calendar = Calendar.current
    let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 3.0, repeats: false)

    let uuidString = UUID().uuidString
    let request = UNNotificationRequest(identifier: uuidString,
                                        content: content,
                                        trigger: trigger)

    // Schedule the request with the system.
    let notificationCenter = UNUserNotificationCenter.current()
    notificationCenter.add(request) { (error) in
      print("something notification...")
       if error != nil {
          // Handle any errors.
         print("error")
       }
    }
  }
}
