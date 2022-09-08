import Combine
import ComposableArchitecture
import MapKit
import SwiftUI
import LoggerFeature
import Assets
//import MapboxMaps
import Foundation

public struct MapView: View {

  public enum ViewAction: Equatable {
    case showCurrent
    case showAll
    case showLocationsFor(Date)
    case centerMap(UUID)
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
  var viewStore: ViewStore<ViewState, ViewAction>
  
  public init(store: Store<ViewState, ViewAction>) {
    self.store = store
    self.viewStore = ViewStore(store)
  }
  
  public var body: some View {
    WithViewStore(store) { viewStore in
    
      ZStack {
        MapViewRepresentable(viewStore)
          .onAppear {
            self.viewStore.send(.showAll)
          }
        
        VStack {
          Spacer()
          
          HStack {
            Spacer()
            
            Button(action: {
              viewStore.send(.centerMap(UUID()))
            }, label: {
              ZStack {
                RoundedRectangle(cornerRadius: 14)
                  .foregroundColor(.white)
                  .padding(8)
                
                Image("locationButton", bundle: assetsBundle)
                  .resizable()
                  .aspectRatio(contentMode: .fit)
                  .frame(width: 16, height: 16)
              }
            })
            .frame(width: 60, height: 50)
          }
          
        }
      }
    }
  }
}



public struct MapViewRepresentable: UIViewRepresentable {
  
  var coordinatesWereSet: Bool = false

  let viewStore: ViewStore<MapView.ViewState, MapView.ViewAction>
  
  var currentPolyline = MyPolyline(lineType: .current)
  var pastPolyline = MyPolyline(lineType: .past)
  var region: MKCoordinateRegion?
  
  func centerMapOnLocations(_ locations: [CLLocation], mapView: MKMapView) {
    guard locations.count > 10 else {
      if let location = locations.first {
        let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: location.coordinate.latitude,
                                                                       longitude: location.coordinate.longitude),
                                        span: .init(latitudeDelta: 0.1, longitudeDelta: 0.1))
        
      }
      return }
    
    guard let first = locations.first, let last = locations.last else { return }
    
    
    let size: MKMapSize = .init(width: 100, height: 100)
    let firstRect = MKMapRect(origin: .init(first.coordinate), size: size)
    let lastRect =  MKMapRect(origin: .init(last.coordinate), size: size)
    let midRect = MKMapRect(origin: .init(locations[locations.count / 2].coordinate), size: size)
    var otherRect = firstRect
    for index in stride(from: 0, through: locations.count, by: 100) {
      otherRect = otherRect.union(MKMapRect(origin: .init(locations[index].coordinate), size: size))
    }
    
    mapView.region = .init(midRect.union(lastRect).union(otherRect).insetBy(dx: -5000, dy: -5000))
    
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
    
    mapView.region = region
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

    let currentLocations = viewStore.currentLocations
    let oldLocations = viewStore.oldLocations
    
    switch viewStore.state.viewAction {
    case .showLocationsFor(let date):
      dPrint("show locations for date \(date)")
      uiView.removeOverlays(uiView.overlays)
      let coordinates = oldLocations.map { $0.coordinate }
      let polyline = MyPolyline(lineType: .current, coordinates: coordinates)
      uiView.addOverlay(polyline)
      centerMapOnLocations(oldLocations, mapView: uiView)
      
    case .showAll:
      dPrint("Show all")
      uiView.removeOverlays(uiView.overlays)
      let coordinates = currentLocations.map { $0.coordinate }
      let polyline = MyPolyline(lineType: .current, coordinates: coordinates)
      uiView.addOverlay(polyline)
      
      let oldCoordinates = oldLocations.map { $0.coordinate }
      let oldPolyline = MyPolyline(lineType: .past, coordinates: oldCoordinates)
      uiView.addOverlay(oldPolyline)
      centerMapOnLocations(oldLocations, mapView: uiView)
      
    case .showCurrent:
      dPrint("Show current")
      uiView.removeOverlays(uiView.overlays)
      let coordinates = currentLocations.map { $0.coordinate }
      let polyline = MyPolyline(lineType: .current, coordinates: coordinates)
      uiView.addOverlay(polyline)
    case .centerMap:
      uiView.centerCoordinate = uiView.userLocation.coordinate
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


//public struct _MBMapView: UIViewRepresentable {
//  
//  var frame: CGRect
//
//  var store: Store<MapView.ViewState, MapView.ViewAction>
//  var viewStore: ViewStore<MapView.ViewState, MapView.ViewAction>
//
//  
//  init(frame: CGRect, store: Store<MapView.ViewState, MapView.ViewAction>, cancellables: Set<AnyCancellable>) {
//    self.frame = frame
//    self.store = store
//    self.viewStore = ViewStore(store)
//  }
//  
//  public func updateUIView(_ uiView: MapboxMaps.MapView, context: Context) {
//  }
//  
//  public func makeUIView(context: Context) -> MapboxMaps.MapView {
//    guard let accessToken = ProcessInfo.processInfo.environment["mapboxAccessToken"] else { fatalError() }
//    dPrint("_MBMapView ")
//    
//    let myResourceOptions = ResourceOptions(accessToken: accessToken)
//    let myMapInitOptions = MapInitOptions(resourceOptions: myResourceOptions)
//    let mapView = MapboxMaps.MapView(frame: frame, mapInitOptions: myMapInitOptions)
//    return mapView
//  }
//}
