
import Combine
import ComposableArchitecture
import LocationFeature
import MapKit
import MapFeature
import LoggerFeature
import PulseUI
import SwiftUI
import TrackerUI
import Assets

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
          
          let locations = env.locationClient.getAllSavedLocations().sorted(by: { $0.timestamp < $1.timestamp })
          print("locations first \(locations.first!) last \(locations.last!)")
          let locationsFirstDate = locations.first!.timestamp
          let locationsLastDate = locations.last!.timestamp
          state.appViewState.datePickerViewState = .init(dateRange: locationsFirstDate...locationsLastDate, date: Date())
          
          
          return env.locationClient.startListening()
            .map { AppAction.locationAction(.receivedEvent($0)) }
            
        case .receivedEvent(let event):
          switch event {
          case .location(let location):
            // FIXME: replacing this with
//            return Effect(value: AppAction.appViewAction(.mapAction(.gotCurrentLocation(location))))
            break
            
          case .updatedLocation:
            // FIXME: this should be called on mapViewState
            print(".updateLocation")
            state.appViewState.mapViewState.currentLocations = env.locationClient.getCurrentLocations()
            
          default:
            break
            
          }
          
          return .none
        }
      
      case .appViewAction(let appViewAction):
        return .none
        
      default:
        return .none
      }
    }
)

let appViewReducer: Reducer<AppView.ViewState, AppView.ViewAction, AppEnvironment> = .combine(
  
  datePickerViewReducer
    .optional()
    .pullback(state: \.datePickerViewState,
              action: /AppView.ViewAction.datePickerViewAction,
              environment: { $0 }),
  
  mapViewReducer
  .pullback(state: \.mapViewState,
            action: /AppView.ViewAction.mapAction,
          environment: { $0 }),
  
  .init { state, action, env in
    switch action {
      
    case .deleteRealm:
      env.locationClient.deleteRealm()
      return .none
      
    case .mapAction(let mapAction):
      return .none
      
    case .dayViewAction(let dayViewAction):
      print(dayViewAction)
       switch dayViewAction {
       case .showDatePicker:
         state.isShowingPicker = true
         return .none
         
       case .showPreviousDate:
         guard let date = state.dayViewState.selectedDate,
               let previousDate = Calendar.current.date(byAdding: .day, value: -1, to: date),
               let earliestDate = state.datePickerViewState?.dateRange.lowerBound,
               previousDate >= earliestDate
         else {
           print("didn't have date selected or date is out of range")
           return .none
         }
         state.dayViewState.selectedDate = previousDate
         return Effect(value: AppView.ViewAction.mapAction(.showLocationsFor(previousDate)))
         
       case .showNextDate:
         guard let date = state.dayViewState.selectedDate,
               let nextDate = Calendar.current.date(byAdding: .day, value: 1, to: date),
               nextDate <= Date()
         else {
           print("didn't have date selected or date is out of range")
           return .none
         }
         state.dayViewState.selectedDate = nextDate
         return Effect(value: AppView.ViewAction.mapAction(.showLocationsFor(nextDate)))
         
       }

      
    case .binding:
      return .none
      
    case .datePickerViewAction(let datePickerViewAction):
      switch datePickerViewAction {
      
      case .binding:
        state.dayViewState.selectedDate = state.datePickerViewState!.calendarViewState.date
        state.isShowingPicker = false

        return Effect(value: AppView.ViewAction.mapAction(.showLocationsFor(state.dayViewState.selectedDate!)))
        
      case .showAllLocations:
        state.dayViewState.selectedDate = nil
        state.isShowingPicker = false
        return Effect(value: AppView.ViewAction.mapAction(.showAll))
        
      case .calendarViewAction(let calendarViewAction):
        if case let .showDate(date) = calendarViewAction {
          state.isShowingPicker = false
          
          state.dayViewState.selectedDate = date
          return Effect(value: AppView.ViewAction.mapAction(.showLocationsFor(date)))
        }
        
        
        return .none
      }
    }
  }//.debug()
).binding()

public let mapViewReducer = Reducer<MapView.ViewState, MapView.ViewAction, AppEnvironment> { state, action, env in
  
  switch action {
  case .showCurrent:
    let currentLocations = env.locationClient.getCurrentLocations()
    let mapViewState = MapView.ViewState.init(viewAction: .showAll, currentLocations: currentLocations, oldLocations: [])
    state = mapViewState
    
  case .showAll:
    let currentLocations = env.locationClient.getCurrentLocations()
    let allLocations = env.locationClient.getAllSavedLocations()
    let mapViewState = MapView.ViewState.init(viewAction: .showAll, currentLocations: currentLocations, oldLocations: allLocations)
    state = mapViewState
    
  case .showLocationsFor(let date):
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yy-mm-dd"
    print("\(dateFormatter.string(from: date))")
    let locationsMatchingDate = env.locationClient.getAllSavedLocations().filter { Calendar.current.isDate($0.timestamp, inSameDayAs: date) }
    let mapViewState = MapView.ViewState.init(viewAction: action, currentLocations: [], oldLocations: locationsMatchingDate)
    state = mapViewState
  }
  
  return .none
}//.debug()

struct CoordinateRegion: Equatable {
  static func == (lhs: CoordinateRegion, rhs: CoordinateRegion) -> Bool {
    return lhs.region.center.longitude == rhs.region.center.longitude && lhs.region.center.latitude == rhs.region.center.latitude
  }
  
  var region: MKCoordinateRegion
}

public struct AppView: View {
  let store: Store<ViewState, ViewAction>
  @ObservedObject var viewStore:  ViewStore<ViewState, ViewAction>
  
  public struct ViewState: Equatable {
    public var mapViewState: MapView.ViewState
    var dayViewState: DayView.ViewState
    var datePickerViewState: DatePickerView.ViewState?
    @BindableState var isShowingPicker: Bool
    
    public init(mapViewState: MapView.ViewState = .init(),
                dayViewState: DayView.ViewState = .init(),
                datePickerViewState: DatePickerView.ViewState? = nil,
                isShowingPicker: Bool = false) {
      self.mapViewState = mapViewState
      self.dayViewState = dayViewState
      self.isShowingPicker = false
      self.datePickerViewState = datePickerViewState
    }
  }
  
  public enum ViewAction: BindableAction, Equatable {
    case binding(BindingAction<ViewState>)
    case deleteRealm
    
    case mapAction(MapView.ViewAction)
    case dayViewAction(DayView.ViewAction)
    case datePickerViewAction(DatePickerView.ViewAction)
  }
  
  public init(store: Store<ViewState, ViewAction>) {
    self.store = store
    self.viewStore = ViewStore(self.store)
  }
  
  @State var presentingListView: Bool = false
  @State var dayViewHeight: CGFloat = 70
  
  public var body: some View {
    GeometryReader { g in
  
      ZStack {
        
        MapView(store: store.scope(state: \.mapViewState, action: ViewAction.mapAction))
          .frame(height: g.size.height - dayViewHeight)
          .offset(y: -dayViewHeight)
       
          VStack(spacing: 0) {
            HStack {
              Button (action: {
                presentingListView.toggle()
              }, label: {
                ZStack {
                  
                  RoundedRectangle(cornerRadius: 20)
                    .foregroundColor(.white)
                  
                  RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(lineWidth: 2)
                    .foregroundColor(.black)
                  
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
    .popover(isPresented: viewStore.binding(\.$isShowingPicker), content: {
      IfLetStore(store.scope(state: \.datePickerViewState,
                             action: ViewAction.datePickerViewAction),
                 then: { store in
          DatePickerView(store: store)
      }, else: {Text("DatePickerViewState is nil...")})
    })
    .popover(isPresented: $presentingListView, content: {
      MainView()
    })
      .onAppear {
      
      }
  }
}

let datePickerViewReducer = Reducer<DatePickerView.ViewState, DatePickerView.ViewAction, AppEnvironment> { state, action, env in
  print()
//  print("datePickerViewReducer \(action)")
  switch action {
  case .calendarViewAction(let calendarViewAction):
    if case let .showMonth(date) = calendarViewAction {
      print("show month \(date) ...")
      let dayColumnViewStates = state.calendarViewState.getViewStates(date)
      state.calendarViewState.date = date
      state.calendarViewState.daysColumnViewStates = dayColumnViewStates
    }
  default:
    break
  }
  return .none
}.binding()

