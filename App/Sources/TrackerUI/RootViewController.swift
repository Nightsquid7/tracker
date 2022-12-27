import UIKit
import LoggerFeature

public final class RootViewController: UIViewController {
  public override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .blue
    logger.debug("")
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
//        let hosting = UIHostingController(rootView: SettingsView(store: <#T##Store<ViewState, ViewAction>#>))

      }
  }
}


