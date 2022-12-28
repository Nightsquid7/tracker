import ComposableArchitecture
import UIKit
import LoggerFeature
import TrackerUI
import SwiftUI
import PulseUI

public final class RootViewController: UIViewController {
  private let store: Store<AppState, AppAction>
  let viewStore: ViewStore<AppState, AppAction>

  public init(store: Store<AppState, AppAction>) {
    self.store = store
    self.viewStore = ViewStore(store)
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .blue
    log("")
    setupDebugMenu()
    showDebug()

    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//      self.viewStore.send(.locationAction()))
    }
  }
}

extension RootViewController {
  private func setupDebugMenu() {
    let edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(screenEdgeSwiped))
       edgePan.edges = .left

       view.addGestureRecognizer(edgePan)
  }

  @objc func screenEdgeSwiped(_ recognizer: UIScreenEdgePanGestureRecognizer) {
      if recognizer.state == .recognized {
        showDebug()
      }
  }


  func showDebug() {
    let settingsView = SettingsView(store: store.scope(state: \.settingsViewState,
                                                       action: { AppAction.appViewAction(AppView.ViewAction.settingsViewAction($0)) }))

    let hosting = UIHostingController(rootView: settingsView)
    present(hosting, animated: false)
  }
}




