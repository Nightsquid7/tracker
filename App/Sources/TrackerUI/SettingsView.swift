import ComposableArchitecture
import CoreLocation
import SwiftUI

public struct SettingsView: View {
  
  public struct ViewState: Equatable {
    @BindableState var distanceFilter: CGFloat
    @BindableState var desiredAccuracy:  CLLocationAccuracy
    
    public init(distanceFilter: CLLocationDistance = 10,
                desiredAccuracy: CLLocationAccuracy  = kCLLocationAccuracyBest) {
      self.distanceFilter = distanceFilter
      self.desiredAccuracy = desiredAccuracy
    }
  }
  
  public enum ViewAction: BindableAction, Equatable {
    case binding(BindingAction<ViewState>)
    case updateDistanceFilter(CGFloat)
    case startTestData
  }
  
  let viewStore: ViewStore<ViewState, ViewAction>
  
  public init(store: Store<ViewState, ViewAction>) {
    self.viewStore = ViewStore(store)
  }
  
  @State var distanceFilter: CGFloat = 10
  @State var desiredAccuracy:  CLLocationAccuracy = kCLLocationAccuracyBest
  
  public var body: some View {
    VStack {
      List {
        Section {
          Button(action: {}, label: {
            Text("Console")
              .foregroundColor(.black)
              .font(.custom("G.B.BOOT", size: 21))
          })
        }
        
        Section {
            Text("Sensitivity")
              .foregroundColor(.black)
              .font(.custom("G.B.BOOT", size: 21))
          
          Slider(value: $distanceFilter, in: 1...100)
          
          Button(action: {
            viewStore.send(.updateDistanceFilter(distanceFilter))
          }, label: {
            Text("Update")
              .foregroundColor(.black)
              .font(.custom("G.B.BOOT", size: 16))
          })
        }
        
        Section {
          Button(action: {
            viewStore.send(.startTestData)
          }, label: {
            Text("Start sending test location data")
              .foregroundColor(.black)
              .font(.custom("G.B.BOOT", size: 21))
          })
        }
      }

    }
    
  }
}
