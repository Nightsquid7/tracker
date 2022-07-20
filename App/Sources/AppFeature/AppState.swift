import CoreLocation
import Foundation
import LocationFeature
import MapFeature

public struct AppState: Equatable {
  var appDelegateState: AppDelegateState
  var appViewState: AppView.ViewState
  
  public init(appDelegateState: AppDelegateState = AppDelegateState(),
              appViewState: AppView.ViewState = .init()) {
    self.appDelegateState = appDelegateState
    self.appViewState = appViewState
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
  case mapAction(MapView.ViewAction)
}


