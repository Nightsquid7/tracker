import AppFeature
import ComposableArchitecture
import CoreLocation
import UIKit

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
    print("Hello Dill, [\(launchOptions)]")
    
    
    viewStore.send(.locationAction(.startListening))
    
    print("locationManager.delegate \(locationManager.delegate)")
    
    if let locationKey = launchOptions?[UIApplication.LaunchOptionsKey.location] {
      print("started from location")
    }
    return true
    }
}
