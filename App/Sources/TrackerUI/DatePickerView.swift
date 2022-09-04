import ComposableArchitecture
import SwiftUI

public struct DatePickerView: View {
  public struct ViewState: Equatable {
    
    // FIXME: remove dateRange here since it is now in calendarViewState
    public var dateRange: ClosedRange<Date>
    @BindableState public var calendarViewState: CalendarView.ViewState
    
    public init(dateRange: ClosedRange<Date>,
                date: Date) {
      self.dateRange = dateRange
      self.calendarViewState = .init(date: date, dateRange: dateRange)
    }
  }
  
  public enum ViewAction: BindableAction, Equatable {
    case binding(BindingAction<ViewState>)
    case showAllLocations
    case calendarViewAction(CalendarView.ViewAction)
  }
  
  var store: Store<ViewState, ViewAction>
  var viewStore: ViewStore<ViewState, ViewAction>
  
  public init(store: Store<ViewState, ViewAction>) {
    self.store = store
    self.viewStore = ViewStore(store)
  }
  
  public var body: some View {
    VStack {
      Text("Show locations from a date")
        .font(.custom("G.B.BOOT", size: 25))
      
      CalendarView(store: store.scope(state: \.calendarViewState,
                                      action: ViewAction.calendarViewAction))
      .padding(.horizontal, 8)
      
      RoundedOutlineButton(text: "show today", action: { viewStore.send(.calendarViewAction(.showDate(Date())))})
        .frame(height: 70)
      
      Text("or")
        .font(.custom("G.B.BOOT", size: 25))
      
      Spacer()
       
      RoundedOutlineButton(text: "show all locations", action: { viewStore.send(.showAllLocations)})
      .frame(height: 70)
    }
  }
}


struct RoundedOutlineButton: View {
  
  var text: String
  var action: () -> Void
  
  public var body: some View {
    Button(action: {
      action()
    }, label: {
      ZStack {
        RoundedRectangle(cornerRadius: 20)
          .strokeBorder(lineWidth: 2)
          .foregroundColor(.black)
        
        Text(text)
          .foregroundColor(.black)
          .font(.custom("G.B.BOOT", size: 25))
      }
    })
//    .frame(height: 70)
    .padding(.horizontal, 8)
  }
}
