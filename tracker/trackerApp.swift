import AppFeature
import SwiftUI

@main
struct trackerApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  
    var body: some Scene {
        WindowGroup {
          AppView(store: appDelegate.store.scope(state: \.appViewState, action: AppAction.appViewAction))
            .onAppear() {
            }
        }
    }
}
