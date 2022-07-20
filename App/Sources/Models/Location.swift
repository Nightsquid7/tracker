import CoreLocation
import RealmSwift


public class RealmLocation: Object {
  @Persisted public var timestamp: Date
  @Persisted public var latitude: CLLocationDegrees
  @Persisted public var longitude: CLLocationDegrees
  
  public convenience init(location: CLLocation) {
    self.init()
    timestamp = location.timestamp
    latitude = location.coordinate.latitude
    longitude = location.coordinate.longitude
  }
}

extension RealmLocation {
  public func clCoordinate2d() -> CLLocationCoordinate2D {
    return .init(latitude: latitude, longitude: longitude)
  }
}
