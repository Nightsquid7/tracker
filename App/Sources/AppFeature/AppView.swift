
import ComposableArchitecture
import LocationFeature
import MapKit
import MapFeature
import LoggerFeature
import PulseUI
import SwiftUI
import TrackerUI

public let appReducer = Reducer<AppState, AppAction, AppEnvironment>.combine(
  appDelegateReducer
    .pullback(state: \.appDelegateState,
              action: /AppAction.appDelegate,
              environment: { _ in .init() }),
  
//  appViewReducer
//    .pullback(state: \.appViewState,
//              action: /AppAction.appViewAction,
//              environment: { $0 } ),
//
  
    mapViewReducer
    .pullback(state: \.appViewState.mapViewState,
              action: /AppAction.mapAction,
              environment: { _ in }),
  
    .init { state, action, env in

      switch action {
      
        
      case .locationAction(let locationAction):
        switch locationAction {
        
        case .startListening:
          return env.locationClient.startListening()
            .map { AppAction.locationAction(.receivedEvent($0)) }
            
        case .receivedEvent(let event):
          switch event {
          case .location(let location):
            state.appViewState.events.append(.location(location))
            return Effect(value: AppAction.mapAction(.gotUpdatedLocation(location)))

          default:
            break
            
          }
          
          return .none
        }
      
      case .appViewAction(let appViewAction):
        switch appViewAction {
        case .loadOldLocations:
          let allLocations = env.locationClient.getAllSavedLocations()
          return Effect(value: AppAction.mapAction(.receivedLocations(allLocations)))

        case .deleteRealm:
          env.locationClient.deleteRealm()
          return .none
        case .testAction:
//          env.locationClient.getDistances()
          env.locationClient.testLocations()
          return .none
        }
        
      default:
        return .none
      }
    }
)

let appViewReducer: Reducer<AppView.ViewState, AppView.ViewAction, AppEnvironment> = .init { state, action, env in

  return .none
}

struct CoordinateRegion: Equatable {
  static func == (lhs: CoordinateRegion, rhs: CoordinateRegion) -> Bool {
    return lhs.region.center.longitude == rhs.region.center.longitude && lhs.region.center.latitude == rhs.region.center.latitude
  }
  
  var region: MKCoordinateRegion
}


public struct AppView: View {
  let store: Store<AppState, AppAction>
  @ObservedObject var viewStore:  ViewStore<AppState, AppAction>
  
  // ViewState and ViewAction not being used
  public struct ViewState: Equatable {
    var events: [LocationEvent] = [] // Temp
    public var mapViewState: MapView.ViewState = .init()
    
    var coordinateRegion: CoordinateRegion = .init(region: MKCoordinateRegion())
    public init() {}
  }
  
  public enum ViewAction: Equatable {
    case deleteRealm
    case loadOldLocations
    case testAction
  }
  
  public init(store: Store<AppState, AppAction>) {
    self.store = store
    self.viewStore = ViewStore(self.store)
  }
  
  @State var presentingListView: Bool = false
  @State var dayViewHeight: CGFloat = 400
  
  public var body: some View {
    GeometryReader { g in
      
    
      ZStack {
        MapView(store: store.scope(state: \.appViewState.mapViewState, action: AppAction.mapAction))
       
        VStack(spacing: 0) {
          HStack {
            Button (action: {
              presentingListView.toggle()
            }, label: {
              ZStack {
                
                RoundedRectangle(cornerRadius: 7)
                  .strokeBorder()
                
                Image(systemName: "gear")
              }
            })
            .frame(width: 60, height: 50)
            
            
            Spacer()
          }
          .frame(height: 50)
          
          Spacer()
          
          DayView()
        }
      }
    }
    .popover(isPresented: $presentingListView, content: {
      MainView()
    })
      .onAppear {
        viewStore.send(AppAction.appViewAction(.loadOldLocations))
//        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//          viewStore.send(AppAction.appViewAction(.testAction))
//        }
      }
  }
}
