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
    print("did finish launching appDelegateReducer")
    return .none
    
  default: 
    return .none
  }
}

