import SwiftUI

public struct PixelBackground: View {
  
  var cornerRectSize: CGFloat = 10
  var lineWidth: CGFloat = 2
  var padding: CGFloat = 10
  
  public var body: some View {
    GeometryReader { g in
      ZStack {
        Rectangle()
          .foregroundColor(.white)
        VStack(spacing: 0) {
          HStack(spacing: 0) {
            Rectangle()
              .stroke(lineWidth: lineWidth)
              .frame(width: cornerRectSize, height: cornerRectSize)
            Rectangle()
              .frame(height: lineWidth)
            
            Rectangle()
              .stroke(lineWidth: lineWidth)
              .frame(width: cornerRectSize, height: cornerRectSize)
          }
          
          HStack(spacing: 0) {
            Rectangle()
              .frame(width: lineWidth, height: g.size.height - 10)
            
            Spacer()
              .frame(width: g.size.width - (cornerRectSize*2) - (padding))
            
            Rectangle()
              .frame(width: lineWidth, height: g.size.height - 10)
          }
          
          HStack(spacing: 0) {
            Rectangle()
              .stroke(lineWidth: lineWidth)
              .frame(width: cornerRectSize, height: cornerRectSize)
            
            Rectangle()
              .frame(height: lineWidth)
            
            Rectangle()
              .stroke(lineWidth: lineWidth)
              .frame(width: cornerRectSize, height: cornerRectSize)
          }
        }
        .padding(padding)
      }
    }
  }
}


extension View {
  public func withPixelBackground() -> some View {
    modifier(_withPixelBackground())
  }
}

public struct _withPixelBackground: ViewModifier {
  public func body(content: Content) -> some View {
    ZStack {
      PixelBackgroundView()
      
      content
    }
  }
}

struct PixelBackgroundView: View {
  var lineWidth: CGFloat = 2
  var lineColor: Color = .black
  
  public var body: some View {
//    GeometryReader { g in
      
      
      VStack(spacing: 0) {
        Rectangle()
          .foregroundColor(lineColor)
          .frame(height: lineWidth)
        
//        Spacer()
        
        HStack(spacing: 0) {
          Rectangle()
            .foregroundColor(lineColor)
            .frame(width: lineWidth)
          
          Spacer()
          
          Rectangle()
            .foregroundColor(lineColor)
            .frame(width: lineWidth)
        }
        
//        Spacer()
        
        Rectangle()
          .foregroundColor(lineColor)
          .frame(height: lineWidth)
      }
//    }
    .padding(.horizontal, 4)
  }
}
