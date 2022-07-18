import AppFeature
import ComposableArchitecture
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
 
  
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
        return true
    }
}
