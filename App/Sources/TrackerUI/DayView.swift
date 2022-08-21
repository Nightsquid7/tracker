import Assets
import ComposableArchitecture
import SwiftUI

public struct DayView: View {

  public struct ViewState: Equatable {
    public var selectedDate: Date?
    
    public init(selectedDate: Date? = nil) {
      self.selectedDate = selectedDate
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
          Rectangle()
          .foregroundColor(.white)
        
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
            }
            
            Spacer()
            
            Text(viewStore.selectedDate?.yearMonthDay() ?? "All")
              .font(.custom("G.B.BOOT", size: 25))
              .onTapGesture {
                viewStore.send(.showDatePicker)
              }
              .onAppear  {
                print("UIFont.familyNames \(UIFont.familyNames)")
              }
            
            Spacer()
            
            if viewStore.selectedDate != nil {
              Button(action: {
                print("right")
                viewStore.send(.showNextDate)
              }, label: {
                Image("chevron_right", bundle: assetsBundle)
              })
              .frame(width: 100, height: 70)
            }
          }
          
//          Spacer()
        }
      }
      .onAppear {
        dragHeight = g.size.height - 90
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
