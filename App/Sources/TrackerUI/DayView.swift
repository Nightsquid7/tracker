import SwiftUI

public struct DayView: View {
  
  enum Appearance {
    case minimum
    case medium
    case max
  }
  
  public init() {}
  
  @State var appearance: Appearance = .minimum
  @State var date: Date = Date()
  let oldDate = Date(timeIntervalSince1970: 1649308341)
  @State var dragHeight: CGFloat = 400
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
            
            Text(date.yearMonthDay())
            
            Spacer()
            
            Button(action: {print("right")}, label: {Image(systemName: "chevron.right")})
              .frame(width: 100, height: 100)
          }
          
          Spacer()
        }
      }
      .gesture(
        DragGesture(minimumDistance: 20, coordinateSpace: .global)
          .onChanged { changed in
            dragHeight = changed.location.y - space
            
            print("dragHeight \(dragHeight)")
          }
          .onEnded { ended in
            dragHeight = ended.location.y - space
            print("ended \(ended)")
          })
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
