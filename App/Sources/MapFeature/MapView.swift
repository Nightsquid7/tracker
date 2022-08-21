import Combine
import ComposableArchitecture
import MapKit
import SwiftUI
import LoggerFeature

public struct MapView: View {

  public enum ViewAction: Equatable {
    case showCurrent
    case showAll
    case showLocationsFor(Date)
  }

  public struct ViewState: Equatable {
    public var currentLocations: [CLLocation]
    public var oldLocations: [CLLocation]
    public var viewAction: ViewAction
    
    public init(viewAction: ViewAction = .showAll,
                currentLocations: [CLLocation] = [],
                oldLocations: [CLLocation] = []) {
      self.viewAction = viewAction
      self.oldLocations = oldLocations
      self.currentLocations = currentLocations
    }
  }
  
  var store: Store<ViewState, ViewAction>
  @State var viewStore: ViewStore<ViewState, ViewAction>
  
  public init(store: Store<ViewState, ViewAction>) {
    self.store = store
    self.viewStore = ViewStore(store)
  }
  
  public var body: some View {
    MapViewRepresentable(store: store)
      .onAppear {
          self.viewStore.send(.showAll)
      }
  }
}

public final class MapViewRepresentable: UIViewRepresentable {
    
  var mapView = MKMapView()
  var cancellables = Set<AnyCancellable>()
  var coordinatesWereSet: Bool = false

  var store: Store<MapView.ViewState, MapView.ViewAction>
  let viewStore: ViewStore<MapView.ViewState, MapView.ViewAction>
  
  var currentPolyline = MyPolyline(lineType: .current)
  var pastPolyline = MyPolyline(lineType: .past)
  var region: MKCoordinateRegion?
  
  func showCurrentLocations() {
    let coordinates = self.viewStore.currentLocations.map { $0.coordinate }
    logger.debug("showCurrentLocations \(coordinates.count)")
    let polyline = MyPolyline(lineType: .current, coordinates: coordinates)

    self.mapView.addOverlay(polyline)
    self.mapView.removeOverlay(self.currentPolyline)
    self.currentPolyline = polyline
  }
  
  func showOldLocations() {
    let oldLocations = self.viewStore.oldLocations
    print("oldLocations .count \(oldLocations.count)")
    let polyline = MyPolyline(lineType: .past,
                              coordinates: oldLocations.map { $0.coordinate })
    if let location = oldLocations.first, self.region == nil {
      self.region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
      self.mapView.setRegion(self.region!, animated: true)
    }
    
    self.mapView.addOverlay(polyline)
    self.mapView.removeOverlay(pastPolyline)
    self.pastPolyline = polyline
  }
  
  init(store: Store<MapView.ViewState, MapView.ViewAction>) {
    self.store = store
    self.viewStore = ViewStore(store)
    
    mapView.showsUserLocation = true
    mapView.showsCompass = true
    mapView.userTrackingMode = .followWithHeading
    
    viewStore.publisher.viewAction
    //      .removeDuplicates(by: ==)
      .delay(for: 0.2, scheduler: RunLoop.main)
      .sink(receiveValue: { viewAction in
        print("viewStore.publisher.viewAction \(viewAction)")
        switch viewAction {
        case .showCurrent:
          self.mapView.removeOverlay(self.pastPolyline)
          self.showCurrentLocations()
          
        case .showAll:
          self.showOldLocations()
          self.showCurrentLocations()
          
        case .showLocationsFor:
          // remove current show old
          self.mapView.removeOverlay(self.currentPolyline)
          self.showOldLocations()
        }
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
    print("didAdd views \(views)")
  }
  
  public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    let polylineRenderer = MKPolylineRenderer(overlay: overlay)
    polylineRenderer.lineWidth = 5
    polylineRenderer.strokeColor = .systemPink
    polylineRenderer.lineJoin = .bevel
    if let polyline = overlay as? MyPolyline {
      switch polyline.lineType {
      case .current:
        polylineRenderer.strokeColor = .blue
      case .past:
        polylineRenderer.strokeColor = polyline.color ?? .red
      }
    }
    
    return polylineRenderer
  }
}

public enum LineType: Equatable {
  case current
  case past
}

final class MyPolyline: MKPolyline {
  
  var lineType: LineType = .current
  var color: UIColor?
  
  convenience init(lineType: LineType,
                   coordinates: [CLLocationCoordinate2D] = [],
                   color: UIColor? = nil) {
    self.init(coordinates: coordinates, count: coordinates.count)
    self.lineType = lineType
    self.color = color
  }
  
  override init() {
    super.init()
  }
}

extension Date {
  func onlyDayMonthYear() -> Date {
    let components = Calendar.current.dateComponents([.year, .month, .day], from: self)
    return Calendar.current.date(from: components)!
  }
}
