import CoreLocation
import Foundation
import LocationFeature
import Logging
import MapFeature
import Pulse
import TrackerUI


public struct AppState: Equatable {
  public var appDelegateState: AppDelegateState
  public var appViewState: AppView.ViewState
  public var settingsViewState: TrackerUI.SettingsView.ViewState
  public init(appDelegateState: AppDelegateState = AppDelegateState(),
              appViewState: AppView.ViewState = .init(),
              settingsViewState: TrackerUI.SettingsView.ViewState = .init()) {
    self.appDelegateState = appDelegateState
    self.appViewState = appViewState
    self.settingsViewState = settingsViewState
    LoggingSystem.bootstrap(PersistentLogHandler.init)
  }
}

public enum LocationAction: Equatable {
  case startListening
  case receivedEvent(LocationEvent)
}

public enum AppAction: Equatable {
  case appDelegate(AppDelegateAction)
  case appViewAction(AppView.ViewAction)
  case locationAction(LocationAction)
}
