
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
  
  appViewReducer
    .pullback(state: \.appViewState,
              action: /AppAction.appViewAction,
              environment: { $0 } ),
  
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
            return Effect(value: AppAction.appViewAction(.mapAction(.gotUpdatedLocation(location))))

          default:
            break
            
          }
          
          return .none
        }
      
      case .appViewAction(let appViewAction):
        return .none
        
//      case .dayViewAction(let dayViewAction):
//        print(dayViewAction)
//        switch dayViewAction {
//        case .showDatePicker:
//          state.appViewState.isShowingPicker = true
//        }
//        return .none
        
      default:
        return .none
      }
    }
)

let appViewReducer: Reducer<AppView.ViewState, AppView.ViewAction, AppEnvironment> = .combine(
  
  mapViewReducer
  .pullback(state: \.mapViewState,
            action: /AppView.ViewAction.mapAction,
          environment: { _ in }),
  
  .init { state, action, env in
    switch action {
    case .showOldLocations:
      let allLocations = env.locationClient.getAllSavedLocations()
      return Effect(value: AppView.ViewAction.mapAction(.receivedLocations(allLocations)))
      
    case .deleteRealm:
      env.locationClient.deleteRealm()
      return .none
      
    case .testAction:
      env.locationClient.testLocations()
      return .none
      
    case .showLocationsFor(let date):
      print("show locations for date \(date)")
      let allLocations = env.locationClient.getAllSavedLocations().filter { Calendar.current.isDate($0.timestamp, equalTo: date, toGranularity: .day) }
      return Effect(value: AppView.ViewAction.mapAction(.receivedLocations(allLocations)))
      
    case .mapAction(let mapAction):
      return .none
    case .dayViewAction(let dayViewAction):
      print(dayViewAction)
       switch dayViewAction {
       case .showDatePicker:
         state.isShowingPicker = true
       }
       return .none
    }
})

struct CoordinateRegion: Equatable {
  static func == (lhs: CoordinateRegion, rhs: CoordinateRegion) -> Bool {
    return lhs.region.center.longitude == rhs.region.center.longitude && lhs.region.center.latitude == rhs.region.center.latitude
  }
  
  var region: MKCoordinateRegion
}

public struct AppView: View {
  let store: Store<ViewState, ViewAction>
  @ObservedObject var viewStore:  ViewStore<ViewState, ViewAction>
  
  // ViewState and ViewAction not being used
  public struct ViewState: Equatable {
    public var mapViewState: MapView.ViewState
    var dayViewState: DayView.ViewState
    var isShowingPicker: Bool
    
    public init(mapViewState: MapView.ViewState = .init(),
                dayViewState: DayView.ViewState = .init(),
                isShowingPicker: Bool = false) {
      self.mapViewState = mapViewState
      self.dayViewState = dayViewState
      self.isShowingPicker = false
    }
  }
  
  public enum ViewAction: Equatable {
    case deleteRealm
    case showLocationsFor(Date)
    case showOldLocations
    case testAction
    
    case mapAction(MapView.ViewAction)
    case dayViewAction(DayView.ViewAction)
  }
  
  public init(store: Store<ViewState, ViewAction>) {
    self.store = store
    self.viewStore = ViewStore(self.store)
  }
  
  @State var presentingListView: Bool = false
  @State var dayViewHeight: CGFloat = 400
  
  public var body: some View {
    GeometryReader { g in
  
      ZStack {
        MapView(store: store.scope(state: \.mapViewState, action: ViewAction.mapAction))
       
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
          
          DayView(store: store.scope(state: \.dayViewState,
                                     action: ViewAction.dayViewAction))
        }
      }
    }
    .popover(isPresented: $presentingListView, content: {
      MainView()
    })
      .onAppear {
        viewStore.send(.showOldLocations)
      }
  }
}
