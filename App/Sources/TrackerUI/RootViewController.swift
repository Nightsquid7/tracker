import UIKit
import LoggerFeature

public final class RootViewController: UIViewController {
  public override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .blue
    logger.debug("")
  }
}
