import Assets
import ComposableArchitecture
import SwiftUI
import LoggerFeature

public struct CalendarView: View {
  
  public struct ViewState: Equatable {
    public var date: Date
    public var daysColumnViewStates: [DaysColumnView.ViewState] = []
    public var dateRange: ClosedRange<Date>
    
    public func getViewStates(_ newDate: Date) -> [DaysColumnView.ViewState] {
      var viewStates: [DaysColumnView.ViewState] = []
      let dateData = newDate.getYearMonthDay()!
      let firstDay = dateData.firstWeekday - 1
      let numberOfDays = dateData.numDays
      var dayNumbers = (1...numberOfDays).map { $0 }
      if firstDay > 1 {
        let prevRange = (1..<firstDay).map { _ in -1 }
        dayNumbers = prevRange + dayNumbers
      }
      let remainingDayCount = 42 - dayNumbers.count
      dayNumbers += (remainingDayCount..<dayNumbers.count).map { _ in -1 }
 
      var dayIndexes: [[Int]] = []
      for num in  1...7 {
        var nums: [Int] = []
        for j in 0...5 {
          let adjustedCalendarDay = (num + (j * 7)) - 1
          nums.append(adjustedCalendarDay)
        }
        dayIndexes.append(nums)
        let days = nums.map { index -> Day in
          let date = Date.dateFrom(year: dateData.year, month: dateData.month, day: dayNumbers[index])!
          return Day.init(date: date, number: dayNumbers[index], isEnabled: dateRange.contains(date))
        }
        var dayString = ""
        switch num {
        case 1:
          dayString = "Mon"
        case 2:
          dayString = "Tue"
        case 3:
          dayString = "Wed"
        case 4:
          dayString = "Thu"
        case 5:
          dayString = "Fri"
        case 6:
          dayString = "Sat"
        case 7:
          dayString = "Sun"
        default:
          break
        }
        let daysColumnViewState = DaysColumnView.ViewState.init(day: dayString, days: days)
        viewStates.append(daysColumnViewState)
      }
      return viewStates
    }
  }
  
  public enum ViewAction: Equatable {
    case showDate(Date)
    case showMonth(Date)
  }
  
  let viewStore: ViewStore<ViewState, ViewAction>

  public init(store: Store<ViewState, ViewAction>) {
    self.viewStore = ViewStore(store)
  }
  
  var columnSpacing: CGFloat = 7
  public var body: some View {
    GeometryReader { g in
      
      VStack(spacing: 0) {
        HStack {
          Button(action: {
            print("left")
            let info = viewStore.date.getYearMonthDay()!
            // FIME: avoid force unwrapping
            let prevDate = Date.dateFrom(year: info.year, month: info.month - 1, day: info.day)!
            
            viewStore.send(.showMonth(prevDate))
          }, label: {
            Image("chevron_left", bundle: assetsBundle)
          })
          .frame(width: 100, height: 70)
          
          Text(verbatim: "\(viewStore.date.getYearMonthDay()!.year)/\(String(format: "%02d", viewStore.date.getYearMonthDay()!.month))")
            .font(.custom("G.B.BOOT", size: 25))
          
          Button(action: {
            print("right")
            let info = viewStore.date.getYearMonthDay()!
            let nextDate = Date.dateFrom(year: info.year, month: info.month + 1, day: info.day)!
            viewStore.send(.showMonth(nextDate))
          }, label: {
            Image("chevron_right", bundle: assetsBundle)
          })
          .frame(width: 100, height: 70)
        }
        
        HStack {
          ForEach(viewStore.daysColumnViewStates, id: \.self) { viewState in
            DaysColumnView(viewState: viewState) { date in
              viewStore.send(.showDate(date))
            }
              .frame(width: (g.size.width / 7) - columnSpacing, height: g.size.height / 2)
          }
        }
      }
      
    }
    .onAppear {
      viewStore.send(.showMonth(viewStore.date))
    }
  }
}

public struct Day: Hashable, Equatable {
  var date: Date
  var number: Int
  let isEnabled: Bool
}

public struct DaysColumnView: View {
  
  public struct ViewState: Hashable, Equatable {
    var day: String
    var days: [Day?]
    public init(day: String, days: [Day]) {
      self.day = day
      self.days = days
    }
  }
  var viewState: ViewState
  var action: (Date) -> Void
  
  var spacing: CGFloat = 4
  
  public var body: some View {
    GeometryReader { g in
      VStack {
        Text(viewState.day)
          .font(.custom("G.B.BOOT", size: 16))

        ForEach(viewState.days, id: \.self) { day in
          Button(action: {
            guard let day = day, day.number > 0, day.isEnabled else { return }
            action(day.date)
          }, label: {
            Text("\(day?.number ?? -7)")
              .font(.custom("G.B.BOOT", size: 25))
              .opacity(day?.number ?? -1 < 1 ? 0 : 1)
              .foregroundColor(day?.isEnabled ?? false ? .black : .gray)
              .frame(height: (g.size.height / 6) - spacing)
          })
        }
      }
    }
  }
}

extension Date {
  func getYearMonthDay() -> (year: Int, month: Int, day: Int, numDays: Int, firstWeekday: Int)? {
    
    let calendar = Calendar.current
    let components = calendar.dateComponents([.year, .month, .day], from: self)
    let dayRange = calendar.range(of: .day, in: .month, for: self)
    var monthComponents = components
    monthComponents.setValue(1, for: .day)
    guard let year = components.year,
          let month = components.month,
          let day = components.day,
          let numDays = dayRange?.count,
          let startOfMonth = calendar.date(from: monthComponents),
          let firstWeekday = calendar.dateComponents([.weekday], from: startOfMonth).weekday
    else {
      return nil
    }
    
    return (year, month, day, numDays, firstWeekday)
  }
  
  
  static func dateFrom(year: Int, month: Int, day: Int) -> Date? {
    let calendar = Calendar.current
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    return calendar.date(from: components)
  }
}
