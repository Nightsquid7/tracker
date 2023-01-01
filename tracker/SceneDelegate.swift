import AppFeature
import ComposableArchitecture
import SwiftUI
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  let store = Store(
    initialState: .init(),
    reducer: appReducer,
    environment: .live
  )

  lazy var viewStore = ViewStore(
    self.store.scope(state: { _ in () }),
    removeDuplicates: ==
  )

  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
      guard let windowScene = scene as? UIWindowScene else { return }

    viewStore.send(.locationAction(.startListening))
    let window = UIWindow(windowScene: windowScene)
    window.rootViewController = RootViewController(store: store)
    self.window = window
    window.makeKeyAndVisible()
  }
}
