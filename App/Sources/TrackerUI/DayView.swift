import Assets
import ComposableArchitecture
import SwiftUI

public struct DayView: View {

  public struct ViewState: Equatable {
    public var selectedDate: Date?
    public var dateRange: ClosedRange<Date>?
    
    public init(selectedDate: Date? = nil,
                dateRange: ClosedRange<Date>? = nil) {
      self.selectedDate = selectedDate
      self.dateRange = dateRange
    }
  }
  
  public enum ViewAction: Equatable {
    case showDatePicker
    case showPreviousDate
    case showNextDate
  }
  
  var viewStore: ViewStore<ViewState, ViewAction>
  
  public init(store: Store<ViewState, ViewAction>) {
    self.viewStore = ViewStore(store)
  }

  @State var dragHeight: CGFloat = 70
  let maximumHeight: CGFloat = 670
  let space: CGFloat = 100
  
  func height(parent: CGFloat) -> CGFloat {
    if dragHeight > maximumHeight { return 50 }
    return parent - dragHeight
  }
  
  func offset(parent: CGFloat) -> CGFloat {
    if dragHeight > maximumHeight { return parent - 50 }
    return dragHeight
  }
  
  public var body: some View {
    GeometryReader { g in
      ZStack {
        
        VStack {

          HStack {
            if viewStore.selectedDate != nil {
              Button(action: {
                print("left")
                viewStore.send(.showPreviousDate)
              }, label: {
                Image("chevron_left", bundle: assetsBundle)
              }
              )
              .frame(width: 100, height: 70)
            
            
            Spacer()
              
              Button(action: {
                viewStore.send(.showDatePicker)
              },
                     label: {
                ZStack {
                  RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(lineWidth: 2)
                    .foregroundColor(.black)
                  
                  Text(viewStore.selectedDate?.yearMonthDay() ?? "...")
                    .foregroundColor(.black)
                    .font(.custom("G.B.BOOT", size: 25))
                }
              })
            
            Spacer()
            
            
              Button(action: {
                print("right")
                viewStore.send(.showNextDate)
              }, label: {
                Image("chevron_right", bundle: assetsBundle)
              })
              .frame(width: 100, height: 70)
            } else {
              
              RoundedOutlineButton(text: "\(viewStore.dateRange?.lowerBound.yearMonthDay() ?? "") ~ \(Date().yearMonthDay())",
                                   action: {
                viewStore.send(.showDatePicker)
              })
            }
          }
        }
      }
      .onAppear {
        dragHeight = g.size.height - 90
        
        // DEBUG
//        viewStore.send(.showDatePicker)
      }
      .frame(height: height(parent: g.size.height))
      .offset(y: offset(parent: g.size.height))
    }
  }
}


extension Date {
  func yearMonthDay() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "YY/MM/dd"
    return dateFormatter.string(from: self)
  }
}

