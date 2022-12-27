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

  var currentPolyLines: [MyPolyline] = []
  var pastPolyLines: [MyPolyline] = []

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
    
    log("mapView init")
  }
  
  var mapView = MKMapView()
  
  public func makeUIView(context: Context) -> MKMapView {
    log("mapView makeUIView")
    mapView.showsUserLocation = true
    mapView.showsCompass = true
    mapView.userTrackingMode = .followWithHeading

    return mapView
  }
  
  
  public func updateUIView(_ uiView: MKMapView, context: Context) {
    log("")

    let currentLocations = viewStore.currentLocations
    let oldLocations = viewStore.oldLocations
    log("currentLocations.count \(currentLocations.count)")
    log("oldLocations.count     \(oldLocations.count)")
    func addPolylines(type: LineType, locations: [CLLocation], distanceThreshold: Double = 250) {
      let spans = CoordinateParser.parseCoordinates(locations: locations, distanceThreshold: Double(distanceThreshold))
      var polylines: [MyPolyline] = []
      for span in spans {
        let polyline = MyPolyline(lineType: type, coordinates: span.map { $0.coordinate })
        polylines.append(polyline)
      }

      uiView.addOverlay(MKMultiPolyline(polylines))
      log("updateUIView polylineCount on mapView \(polylines.count)")
    }
    
    switch viewStore.state.viewAction {
    case .showLocationsFor(let date):
      log("show locations for date \(date)")
      uiView.removeOverlays(uiView.overlays)
      addPolylines(type: .current, locations: oldLocations)
      centerMapOnLocations(oldLocations, mapView: uiView)
      
    case .showAll:
      log("Show all")
      uiView.removeOverlays(uiView.overlays)
      addPolylines(type: .current, locations: currentLocations)
      addPolylines(type: .past, locations: oldLocations, distanceThreshold: 1000)
      centerMapOnLocations(oldLocations, mapView: uiView)
      
    case .showCurrent:
      log("Show current")
      addPolylines(type: .current, locations: currentLocations)

    case .centerMap:
      uiView.centerCoordinate = uiView.userLocation.coordinate
    }
  }
  
  public func makeCoordinator() -> MapViewCoordinator {
    let coordinator = MapViewCoordinator()
    log("make Coordinator")
    mapView.delegate = coordinator
    return coordinator
  }
  
  public typealias UIViewType = MKMapView
}

public final class MapViewCoordinator: NSObject, MKMapViewDelegate {
  
  var whaleImages: UIImage

  init(_ garbage: Bool? = nil) {
    whaleImages = UIImage(named: "my_whale_64x64", in: assetsBundle, with: nil)!
  }
  
  public func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
//    log("mapView didAdd views \(views)")
  }
  
  public func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
//    log("MapViewDidFinishLoadingMap")
  }
  
  public func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
//    log("mapViewDidFinishRenderingMap")
  }
  
  
  public func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
//    log("mapView regionDidChangeAnimated")
  }

  public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {

    let polylineRenderer = MKMultiPolylineRenderer(overlay: overlay)
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
//    print("did add renderers")
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
//    log("_MBMapView ")
//    
//    let myResourceOptions = ResourceOptions(accessToken: accessToken)
//    let myMapInitOptions = MapInitOptions(resourceOptions: myResourceOptions)
//    let mapView = MapboxMaps.MapView(frame: frame, mapInitOptions: myMapInitOptions)
//    return mapView
//  }
//}

struct CoordinateParser {
  static func parseCoordinates(locations: [CLLocation], distanceThreshold: Double = 250) -> [[CLLocation]] {
    var result: [[CLLocation]] = [[]]
    var temp: [CLLocation] = []

    guard locations.count > 1 else { return result }

    for (location1, location2) in zip(locations, locations[1...]) {
      temp.append(location1)

      if location1.distance(from: location2) > distanceThreshold {
        result.append(temp)
        temp = []
        continue
      }
    }
    log("updateUIView result.count \(result.count), locations.count \(locations.count)")
   return result
  }
}
