
import ComposableArchitecture
import LocationFeature
import MapKit
import MapFeature
import SwiftUI

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
      print("\nACTION \(action)\n")
      switch action {
      case .locationAction(let locationAction):
        switch locationAction {
        case .startListening:
          return env.locationClient.startListening()
            .map { AppAction.locationAction(.receivedEvent($0)) }
            
        case .receivedEvent(let event):
          print("received event \(event)")
          switch event {
          case .location(let location):
            print("set cooridinate region")
            state.appViewState.coordinateRegion.region = MKCoordinateRegion(center:  CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude), span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005))
          default:
            break
            
          }
          state.appViewState.events = env.locationClient.getSavedLocations()//.sorted(by: { $0.timestamp < $1.timestamp })
          state.appViewState.mapViewState.coordinates = Coordinates(coordinates: env.locationClient.getAllSavedCoordinates())

          return .none
        }
      
      case .appViewAction(let appViewAction):
        if case .deleteRealm = appViewAction {
          env.locationClient.deleteRealm()
          
        }
        return .none
        
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
    case temp
    case deleteRealm
  }
  
  public init(store: Store<AppState, AppAction>) {
    self.store = store
    self.viewStore = ViewStore(self.store)
  }
  
  @State var presentingListView: Bool = false
  
  public var body: some View {
    VStack {
      
      MapView(store: store.scope(state: \.appViewState.mapViewState, action: AppAction.mapAction))
      
      HStack {
        Button (action: {
          viewStore.send(.appViewAction(.deleteRealm))
        }, label: {
          Text("Delete realm")
        })
        
        Toggle(isOn: $presentingListView, label: { Text("Toggle list view")})
      }
      .frame(height: 50)
    }
    .popover(isPresented: $presentingListView, content: {
            List {
              ForEach(viewStore.appViewState.events, id: \.self) { event in
                Text(event.toString())
              }
            }
    })
      .onAppear {
        viewStore.send(AppAction.appDelegate(.didFinishLaunching))
      }
  }
}
