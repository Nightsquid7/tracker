import AppFeature
import SwiftUI

@main
struct trackerApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  
    var body: some Scene {
        WindowGroup {
          AppView(store: appDelegate.store)
            .onAppear() {
//              DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
//              
//              }
            }
        }
    }
}
