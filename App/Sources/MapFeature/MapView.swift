import ComposableArchitecture
import MapKit
import SwiftUI


public struct Coordinates: Equatable {
  public static func == (lhs: Coordinates, rhs: Coordinates) -> Bool {
    for (x,y) in zip(lhs.coordinates, rhs.coordinates) {
      if x.latitude != y.latitude || x.longitude != y.longitude {
        return false
      }
    }
    return true
  }
  
  public init(coordinates: [CLLocationCoordinate2D] = []) {
    self.coordinates = coordinates
  }
  
  public var coordinates: [CLLocationCoordinate2D]
}


public let mapViewReducer = Reducer<MapView.ViewState, MapView.ViewAction, Void> { state, action, _ in
  print("map view reducer action")
  return .none
}

public struct MapView: View {
  
  public struct ViewState: Equatable {
    public var coordinates: Coordinates
    
    public init(coordinates: Coordinates = .init()) {
      self.coordinates = coordinates
    }
  }
  
  public enum ViewAction: Equatable {
    case receivedCoordinates(Coordinates)
  }
  
  var viewStore: ViewStore<ViewState, ViewAction>
  
  public init(store: Store<ViewState, ViewAction>) {
    self.viewStore = ViewStore(store)
  }
  
  public var body: some View {
    MapViewRepresentable(coordinates: viewStore.publisher.coordinates.eraseToAnyPublisher())
//    VStack {}
  }
}

import Combine

public final class MapViewRepresentable: UIViewRepresentable {
  
//  var coordinates = AnyPublisher<[CLLocationCoordinate2D], Never>
  var mapView = MKMapView()
  var cancellables = Set<AnyCancellable>()
  var coordinatesWereSet: Bool = false
  
  init(coordinates: AnyPublisher<Coordinates, Never>) {
//    self.coordinates = coordinates
    
    mapView.showsUserLocation = true

    
    coordinates.sink(receiveValue: { coordinates in
      print("received coordinates \(coordinates.coordinates.count)")
      if let firstCoordinate = coordinates.coordinates.first, self.coordinatesWereSet == false {
        self.mapView.region =  MKCoordinateRegion(center:  CLLocationCoordinate2D(latitude: firstCoordinate.latitude,
                                                                                  longitude: firstCoordinate.longitude),
                                                  span: MKCoordinateSpan(latitudeDelta: 0.005,
                                                                         longitudeDelta: 0.005))
        self.coordinatesWereSet = true
      }
      
      let polyLine = MKPolyline(coordinates: coordinates.coordinates, count: coordinates.coordinates.count)
      
      
      self.mapView.addOverlay(polyLine)
    })
    .store(in: &cancellables)
  }
  
  
  public func makeUIView(context: Context) -> MKMapView {
    return mapView
  }
  
  public func updateUIView(_ uiView: MKMapView, context: Context) {}
  
  public func makeCoordinator() -> MapViewCoordinator {
    let coordinator = MapViewCoordinator()
    mapView.delegate = coordinator
    return coordinator
  }
  
  public typealias UIViewType = MKMapView
  
  
}

public final class MapViewCoordinator: NSObject, MKMapViewDelegate {
  public func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
    print(mapView)
  }
  
  public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    var polylineRenderer = MKPolylineRenderer(overlay: overlay)
    polylineRenderer.strokeColor = .blue
    polylineRenderer.lineWidth = 5
    return polylineRenderer
  }
}
