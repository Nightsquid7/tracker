import Combine
import ComposableArchitecture
import MapKit
import SwiftUI
import LoggerFeature
import Assets
import MapboxMaps
import Foundation

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
  
  public enum _ViewAction: Equatable {
    case showCurrentLocations([CLLocation])
    case showLocationsForDate([CLLocation])
    case showAllLocations(currentLocations: [CLLocation], oldLocations: [CLLocation])
//    case centerMap
//    case updateMapSettings(MapSettings)
  }
  
  var store: Store<ViewState, ViewAction>
  var viewStore: ViewStore<ViewState, ViewAction>
  
  public init(store: Store<ViewState, ViewAction>) {
    self.store = store
    self.viewStore = ViewStore(store)
  }
  
  public var body: some View {
    WithViewStore(store) { viewStore in
      
    MapViewRepresentable(viewStore)
      .onAppear {
        self.viewStore.send(.showAll)
      }
    }
  }
}



public struct MapViewRepresentable: UIViewRepresentable {
  
//  var cancellables = Set<AnyCancellable>()
  var coordinatesWereSet: Bool = false

//  var store: Store<MapView.ViewState, MapView.ViewAction>
  let viewStore: ViewStore<MapView.ViewState, MapView.ViewAction>
  
  var currentPolyline = MyPolyline(lineType: .current)
  var pastPolyline = MyPolyline(lineType: .past)
  var region: MKCoordinateRegion?

  func showCurrentLocations(mapView: MKMapView) {
    let coordinates = self.viewStore.currentLocations.map { $0.coordinate }
    dPrint("showCurrentLocations \(coordinates.count)")
    let polyline = MyPolyline(lineType: .current, coordinates: coordinates)
    mapView.addOverlay(polyline)
    //    self.mapView.removeOverlay(self.currentPolyline)
//    self.currentPolyline = polyline
    
  }
  
  func showOldLocations() {
    let oldLocations = self.viewStore.oldLocations
    print("oldLocations .count \(oldLocations.count)")
    let polyline = MyPolyline(lineType: .past,
                              coordinates: oldLocations.map { $0.coordinate })
    if let location = oldLocations.first, self.region == nil {
//      self.region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
//      mapView.setRegion(MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)), animated: true)
    }
    
//    mapView.addOverlay(polyline)
    
//    self.mapView.removeOverlay(pastPolyline)
//    self.pastPolyline = polyline
  }
  
  func centerMapOnLocations(_ locations: [CLLocation]) {
    guard locations.count > 10 else {
      if let location = locations.first {
        let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: location.coordinate.latitude,
                                                                       longitude: location.coordinate.longitude),
                                        span: .init(latitudeDelta: 0.1, longitudeDelta: 0.1))
        
//        self.mapView.region = region
      }
      return }
    
    guard let first = locations.first, let last = locations.last else { return }
    
    
    let size: Double = 100
    let firstRect = MKMapRect(origin: .init(first.coordinate), size: .init(width: size, height: size))
    let lastRect =  MKMapRect(origin: .init(last.coordinate), size: .init(width: size, height: size))
    let midRect = MKMapRect(origin: .init(locations[locations.count / 2].coordinate), size: .init(width: size, height: size))
    
//    self.mapView.region = MKCoordinateRegion(firstRect.union(lastRect).union(midRect))

    return
    
    
    let jankCenter = locations[locations.count / 2]
    let firstCoord = locations.first!
    let lastCoord = locations.last!
    let distance = firstCoord.distance(from: lastCoord)
    
    var span: MKCoordinateSpan = .init()
    switch distance {
    case 1...100:
      span = .init(latitudeDelta: 0.1, longitudeDelta: 0.1)
    case 100...1_000:
      span = .init(latitudeDelta: 0.1, longitudeDelta: 0.1)
    case 1_000...10_000:
      span = .init(latitudeDelta: 0.25, longitudeDelta: 0.25)
    case 10_000...20_000:
      span = .init(latitudeDelta: 0.4, longitudeDelta: 0.4)
    case 20_000...100_000:
      span = .init(latitudeDelta: 0.9, longitudeDelta: 0.9)
    default:
      break
    }
    print("distance", distance)
    let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: jankCenter.coordinate.latitude,
                                                                   longitude: jankCenter.coordinate.longitude), span: span)
    
    self.mapView.region = region
    
  }
  
  init(_ viewStore: ViewStore<MapView.ViewState, MapView.ViewAction>) {
    self.viewStore = viewStore
    
    dPrint("mapView init")
  }
  
  var mapView = MKMapView()
  
  public func makeUIView(context: Context) -> MKMapView {
    dPrint("mapView makeUIView")
    mapView.showsUserLocation = true
    mapView.showsCompass = true
    mapView.userTrackingMode = .followWithHeading

    return mapView
  }
  
  
  public func updateUIView(_ uiView: MKMapView, context: Context) {
    print("update mapView... \(uiView) mapView \(mapView)")
    
    
    dPrint("ViewStore state \(viewStore.state)")
    let currentLocations = viewStore.currentLocations
    let oldLocations = viewStore.oldLocations
    switch viewStore.state.viewAction {
    case .showLocationsFor(let date):
      dPrint("show locations for date \(date)")
      uiView.removeOverlays(
        uiView.overlays.filter {
          guard let polyline = $0 as? MyPolyline else { return false}
          if polyline.lineType == .current {
            dPrint("remove polynine type current \(polyline.pointCount)")
            return true }
          return false
        }
      )
      let coordinates = currentLocations.map { $0.coordinate }
      let polyline = MyPolyline(lineType: .current, coordinates: coordinates)
      uiView.addOverlay(polyline)
      
    case .showAll:
      dPrint("Show all")
      uiView.removeOverlays(uiView.overlays)
      let coordinates = currentLocations.map { $0.coordinate }
      let polyline = MyPolyline(lineType: .current, coordinates: coordinates)
      uiView.addOverlay(polyline)
      
      let oldCoordinates = oldLocations.map { $0.coordinate }
      let oldPolyline = MyPolyline(lineType: .past, coordinates: oldCoordinates)
      uiView.addOverlay(oldPolyline)
      
    case .showCurrent:
      dPrint("Show current")
      uiView.removeOverlays(uiView.overlays)
      let coordinates = currentLocations.map { $0.coordinate }
      let polyline = MyPolyline(lineType: .current, coordinates: coordinates)
      uiView.addOverlay(polyline)
    }
  }
  
  public func makeCoordinator() -> MapViewCoordinator {
    let coordinator = MapViewCoordinator()
    dPrint("make Coordinator")
    mapView.delegate = coordinator
    return coordinator
  }
  
  public typealias UIViewType = MKMapView
}

public final class MapViewCoordinator: NSObject, MKMapViewDelegate {
  
  var whaleImages: UIImage
  

  init(_ garbage: Bool? = nil) {
//    self.mapView = mapView
    dPrint("mapView coordinator init()")
    whaleImages = UIImage(named: "my_whale_64x64", in: assetsBundle, with: nil)!
  }
  
  public func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
    dPrint("mapView didAdd views \(views)")
  }
  
  public func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
    dPrint("MapViewDidFinishLoadingMap")
  }
  
  public func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
    dPrint("mapViewDidFinishRenderingMap")
  }
  
  
  public func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
    dPrint("mapView regionDidChangeAnimated")
  }

  public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    let polylineRenderer = MKPolylineRenderer(overlay: overlay)
    polylineRenderer.lineWidth = 5
    polylineRenderer.strokeColor = .systemPink
    polylineRenderer.lineJoin = .bevel
    dPrint("mapView renderFor overlay")
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
  
  public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    print("annotation", annotation)

    if let userLocation = annotation as? MKUserLocation {
      print("user location \(userLocation)")
      let view = MKAnnotationView()
      view.image = whaleImages
      return view
    }
    return nil
  }
  
  public func mapView(_ mapView: MKMapView, didAdd renderers: [MKOverlayRenderer]) {
    print("did add renderers")
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
  
  func formatted() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yy-mm-dd"
    return dateFormatter.string(from: self)
  }
}


public struct _MBMapView: UIViewRepresentable {
  
  var frame: CGRect

  var store: Store<MapView.ViewState, MapView.ViewAction>
  var viewStore: ViewStore<MapView.ViewState, MapView.ViewAction>

  
  init(frame: CGRect, store: Store<MapView.ViewState, MapView.ViewAction>, cancellables: Set<AnyCancellable>) {
    self.frame = frame
    self.store = store
    self.viewStore = ViewStore(store)
  }
  
  public func updateUIView(_ uiView: MapboxMaps.MapView, context: Context) {
  }
  
  public func makeUIView(context: Context) -> MapboxMaps.MapView {
    guard let accessToken = ProcessInfo.processInfo.environment["mapboxAccessToken"] else { fatalError() }
    dPrint("_MBMapView ")
    
    let myResourceOptions = ResourceOptions(accessToken: accessToken)
    let myMapInitOptions = MapInitOptions(resourceOptions: myResourceOptions)
    let mapView = MapboxMaps.MapView(frame: frame, mapInitOptions: myMapInitOptions)
    return mapView
  }
}
