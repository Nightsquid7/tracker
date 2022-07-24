import ComposableArchitecture

public struct AppDelegateState: Equatable {
  public init() {}
}

public enum AppDelegateAction: Equatable {
  case didFinishLaunching
  case receivedScreens
}

public struct AppDelegateEnvironment {
   
  public init() {}
}

public let appDelegateReducer = Reducer<AppDelegateState, AppDelegateAction,  AppDelegateEnvironment> { state, action, env in
  switch action {
  case .didFinishLaunching:
    return .none
    
  default: 
    return .none
  }
}

