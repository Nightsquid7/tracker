import Combine
import ComposableArchitecture
import MapKit
import SwiftUI
import LoggerFeature

public let mapViewReducer = Reducer<MapView.ViewState, MapView.ViewAction, Void> { state, action, _ in
  
  switch action {
  case .gotUpdatedLocation(let location):
    logger.info("received location mapViewReducer \(location)")
    state.currentLocation = location
    
  case .receivedLocations(let locations):
    state.oldLocations = locations
  }
  
  return .none
}


public struct MapView: View {
  
  public struct ViewState: Equatable {
    public var locations: [CLLocation]
    public var currentLocation: CLLocation
    public var oldLocations: [CLLocation]
    
    
    public init(locations: [CLLocation] = [], currentLocation: CLLocation = .init(), oldLocations: [CLLocation] = []) {
      self.locations = locations
      self.currentLocation = currentLocation
      self.oldLocations = oldLocations
    }
  }
  
  public enum ViewAction: Equatable {
    // add to "current line"
    case gotUpdatedLocation(CLLocation)
    // Draw all at once in "previous line color"
    case receivedLocations([CLLocation])
  }
  
  var store: Store<ViewState, ViewAction>
  var viewStore: ViewStore<ViewState, ViewAction>
  
  public init(store: Store<ViewState, ViewAction>) {
    self.store = store
    self.viewStore = ViewStore(store)
  }
  
  public var body: some View {
    MapViewRepresentable(store: store)
  }
}

public final class MapViewRepresentable: UIViewRepresentable {
  
  var mapView = MKMapView()
  var cancellables = Set<AnyCancellable>()
  var coordinatesWereSet: Bool = false

  var store: Store<MapView.ViewState, MapView.ViewAction>
  var viewStore: ViewStore<MapView.ViewState, MapView.ViewAction>
  var currentPolyline = MyPolyline(lineType: .current)
  var currentLocations: [CLLocationCoordinate2D] = []
  
  var pastPolyline = MyPolyline(lineType: .past)
  var region: MKCoordinateRegion?
  
  init(store: Store<MapView.ViewState, MapView.ViewAction>) {
    self.store = store
    self.viewStore = ViewStore(store)
    mapView.showsUserLocation = true
    viewStore.publisher.currentLocation.sink(receiveValue: { location in
      logger.info("mapView update location \(location)")
      self.currentLocations.append(location.coordinate)
      let _polyline = MyPolyline(coordinates: self.currentLocations, count: self.currentLocations.count)
      self.mapView.addOverlay(_polyline)
      self.mapView.removeOverlay(self.currentPolyline)
      self.currentPolyline = _polyline
    })
    .store(in: &cancellables)
    
    viewStore.publisher.oldLocations
      .filter { $0.count > 0 }
      .sink(receiveValue: { locations in
        logger.info("mapView past locations \(locations.count)")
        
        let coordinates = locations.map { $0.coordinate }
        let polyline = MyPolyline(lineType: .past, coordinates: coordinates)
          if let location = locations.first, self.region == nil {
            self.region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
            self.mapView.setRegion(self.region!, animated: true)
          }
        
        self.mapView.addOverlay(polyline)
        self.mapView.removeOverlay(self.pastPolyline)
        self.pastPolyline = polyline
        
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
//    logger.info(mapView )
  }
  
  public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    let polylineRenderer = MKPolylineRenderer(overlay: overlay)
    polylineRenderer.lineWidth = 5
    polylineRenderer.strokeColor = .systemPink
    if let polyline = overlay as? MyPolyline {
      switch polyline.lineType {
      case .current:
        polylineRenderer.strokeColor = .blue
      case .past:
        polylineRenderer.strokeColor = .red
      }
    }
    
    return polylineRenderer
  }
}

public enum LineType: Equatable {
  case current
  case past
}

public struct Polyline: Equatable {
  var lineType: LineType
  var polyline: MKPolyline
  
  init(lineType: LineType = .current, polyline: MKPolyline) {
    self.lineType = lineType
    self.polyline = polyline
  }
}

final class MyPolyline: MKPolyline {
  
  var lineType: LineType = .current
  
  convenience init(lineType: LineType, coordinates: [CLLocationCoordinate2D] = []) {
    self.init(coordinates: coordinates, count: coordinates.count)
    self.lineType = lineType
  }
  
  override init() {
    super.init()
  }
}
