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
    
  }
  
  var viewStore: ViewStore<ViewState, ViewAction>
  
  public init(store: Store<ViewState, ViewAction>) {
    self.viewStore = ViewStore(store)
  }

  @State var dragHeight: CGFloat = 90
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
            Button(action: {print("left")}, label: {Image(systemName: "chevron.left")})
              .frame(width: 100, height: 100)
            
            Spacer()
            
            Text(viewStore.selectedDate?.yearMonthDay() ?? "viewStore.selectedDate == nil")
              .onTapGesture {
                viewStore.send(.showDatePicker)
              }
            
            Spacer()
            
            Button(action: {print("right")}, label: {Image(systemName: "chevron.right")})
              .frame(width: 100, height: 100)
          }
          
          Spacer()
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
