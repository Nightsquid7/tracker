import ComposableArchitecture
import CoreLocation
import SwiftUI
import PulseUI

public struct SettingsView: View {
  
  public struct ViewState: Equatable {
    @BindableState var distanceFilter: CGFloat
    @BindableState var desiredAccuracy:  CLLocationAccuracy
    @BindableState public var showingConsole: Bool
    public var locationAuthorizationStatus: String = ""
    
    public init(distanceFilter: CLLocationDistance = 10,
                desiredAccuracy: CLLocationAccuracy  = kCLLocationAccuracyBest,
                showingConsole: Bool = false) {
      self.distanceFilter = distanceFilter
      self.desiredAccuracy = desiredAccuracy
      self.showingConsole = showingConsole
    }
  }
  
  public enum ViewAction: BindableAction, Equatable {
    case binding(BindingAction<ViewState>)
    case updateDistanceFilter(CGFloat)
    case startTestData
    case showConsole
    case updatedLocationStatus(CLAuthorizationStatus)
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
          Button(action: {
            viewStore.send(.showConsole)
          }, label: {
            Text("Console")
              .foregroundColor(.black)
              .font(.custom("G.B.BOOT", size: 21))
          })
        }
        Section (content: {
          Button(action: {
            // FIXME: add this to reducer...
            UIApplication.shared.open(URL(string:UIApplication.openSettingsURLString)!)
          }, label: {
            Text(viewStore.locationAuthorizationStatus)
              .foregroundColor(.black)
              .gameboy(size: 21)
          })
        }, header: {
          Text("Location authorization status")
            .foregroundColor(.gray)
            .gameboy(size: 17)
        })
//        Section {
//            Text("Sensitivity")
//              .foregroundColor(.black)
//              .font(.custom("G.B.BOOT", size: 21))
//
//          Slider(value: $distanceFilter, in: 1...100)
//
//          Button(action: {
//            viewStore.send(.updateDistanceFilter(distanceFilter))
//          }, label: {
//            Text("Update")
//              .foregroundColor(.black)
//              .font(.custom("G.B.BOOT", size: 16))
//          })
//        }
        
        Section {
          Button(action: {
            viewStore.send(.startTestData)
          }, label: {
            Text("Start sending test location data")
              .foregroundColor(.black)
              .gameboy(size: 21)

          })
        }
      }

    }
    .popover(isPresented: viewStore.binding(\.$showingConsole)){
      MainView()
    }
    
  }
}

extension Text {
  func gameboy(size: CGFloat) -> some View {
    return self
      .font(.custom("G.B.BOOT", size: size))
  }
}
