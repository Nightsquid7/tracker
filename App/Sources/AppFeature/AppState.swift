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
  
  public init(appDelegateState: AppDelegateState = AppDelegateState(),
              appViewState: AppView.ViewState = .init()) {
    self.appDelegateState = appDelegateState
    self.appViewState = appViewState
    
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
//  case mapAction(MapView.ViewAction)
//  case dayViewAction(DayView.ViewAction)
}
