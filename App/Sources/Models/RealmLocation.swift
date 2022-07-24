import CoreLocation
import RealmSwift


public class RealmLocation: Object {
  @Persisted public var latitude: CLLocationDegrees
  @Persisted public var longitude: CLLocationDegrees
  @Persisted public var altitude: CLLocationDistance
  @Persisted public var horizontalAccuracy: CLLocationAccuracy
  @Persisted public var verticalAccuracy: CLLocationAccuracy
  @Persisted public var course: CLLocationDirection
  @Persisted public var courseAccuracy: CLLocationDirectionAccuracy
  @Persisted public var speed: CLLocationSpeed
  @Persisted public var speedAccuracy: CLLocationSpeedAccuracy
  @Persisted public var timestamp: Date

  
  public convenience init(location: CLLocation) {
    self.init()
    timestamp = location.timestamp
    latitude = location.coordinate.latitude
    longitude = location.coordinate.longitude
    altitude = location.altitude
    horizontalAccuracy = location.horizontalAccuracy
    verticalAccuracy = location.verticalAccuracy
    course = location.course
    courseAccuracy = location.courseAccuracy
    speed = location.speed
    speedAccuracy = location.speedAccuracy
    timestamp = location.timestamp
  }
}

extension RealmLocation {
  public func clCoordinate2d() -> CLLocationCoordinate2D {
    return .init(latitude: latitude, longitude: longitude)
  }
  
  public func location() -> CLLocation {
    return CLLocation(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                      altitude: altitude,
                      horizontalAccuracy: horizontalAccuracy,
                      verticalAccuracy: verticalAccuracy,
                      course: course,
                      courseAccuracy: courseAccuracy,
                      speed: speed,
                      speedAccuracy: speedAccuracy,
                      timestamp: timestamp)
  }
}
