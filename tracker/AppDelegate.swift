import AppFeature
import ComposableArchitecture
import CoreLocation
import Foundation
import Logging
import LoggerFeature
import Pulse
import UIKit
import RealmSwift

final class AppDelegate: NSObject, UIApplicationDelegate {

  let locationManager = CLLocationManager()
  let store  = Store(
    initialState: .init(),
    reducer: appReducer,
    environment: .live
  )
  
  lazy var viewStore = ViewStore(
    self.store.scope(state: { _ in () }),
    removeDuplicates: ==
  )
  
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    
    UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .sound, .provisional, .alert], completionHandler: { result, error in
      print("result, \(result) error \(error)")
    })
    
    viewStore.send(.locationAction(.startListening))
//    AppDelegate.notification(title: "testing", body: "nothing")
    logger.info("didFinishLaunchingWithOptions")
    if let locationKey = launchOptions?[UIApplication.LaunchOptionsKey.location] {
      logger.info("started app with location key \(locationKey)")
      AppDelegate.notification(title: "Started with location key!", body: "locationKey \(locationKey)")
    }
    
    return true
    }
  
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

extension AppDelegate: UNUserNotificationCenterDelegate {
  func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    completionHandler([.badge, .alert, .list, .sound])
  }
  
  func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
          print(response.notification.request.content.userInfo)
          completionHandler()
      }
}
