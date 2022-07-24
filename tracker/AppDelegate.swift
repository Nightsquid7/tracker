import AppFeature
import ComposableArchitecture
import CoreLocation
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
  
    viewStore.send(.locationAction(.startListening))
    logger.info("didFinishLaunchingWithOptions")
    if let locationKey = launchOptions?[UIApplication.LaunchOptionsKey.location] {
      logger.info("started app with location key \(locationKey)")
    }
    return true
    }
}
