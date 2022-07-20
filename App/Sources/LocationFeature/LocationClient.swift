import Combine
import ComposableArchitecture
import CoreLocation
import Models
import RealmSwift

public struct LocationClient {
  public var startListening: () -> Effect<LocationEvent, Never>
  public var getSavedLocations: () -> [LocationEvent]
  public var getAllSavedCoordinates: () -> [CLLocationCoordinate2D]
  public var deleteRealm: () -> Void
}


extension LocationClient {
  public static var live: Self {
    
    let locationManager = CLLocationManager()
    let locationDelegate = LocationDelegate()
      
    locationManager.delegate = locationDelegate
    
    
    return Self(
      startListening: {
//        try! locationDelegate.realm.write {
//          locationDelegate.realm.deleteAll()
//        }
        
        locationManager.requestAlwaysAuthorization()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
        locationManager.startUpdatingLocation()
        
        locationManager.delegate = locationDelegate

        return locationDelegate
          .publisher
          .eraseToEffect()
      },
      
      getSavedLocations: {
        return Array(locationDelegate.realm.objects(RealmLocation.self).sorted(by: {$0.timestamp > $1.timestamp}).map { LocationEvent._location($0) })
      },
      
      getAllSavedCoordinates: {
        return Array(locationDelegate.realm.objects(RealmLocation.self).sorted(by: { $0.timestamp > $1.timestamp }).map { $0.clCoordinate2d() })
      },
      
      deleteRealm: {
        print("delete all")
        try! locationDelegate.realm.write {
          locationDelegate.realm.deleteAll()
        }
      }
    )
  }
}

public struct Location: Equatable {
  var location: CLLocation
}


public enum LocationEvent: Equatable, Hashable {
  case location(CLLocation)
  case _location(RealmLocation)
  case message(String)
  case error
  
  public func toString() -> String {
    switch self {
    case .location(let location):
      return "\(location.timestamp.description(with: .current)) lat: \(String(format: "%3.3f", location.coordinate.latitude)) long: \(String(format: "%3.3f", location.coordinate.longitude))"
    case ._location(let realmLocation):
      return "\(realmLocation.timestamp.description(with: .current)) lat: \(String(format: "%3.8f", realmLocation.latitude)) long: \(String(format: "%3.8f", realmLocation.longitude))"
    case .message(let message):
      return message
    case .error: return "error"
    }
  }
}

final class LocationDelegate: NSObject, CLLocationManagerDelegate {
  let publisher = PassthroughSubject<LocationEvent, Never>()
  let realm = try! Realm()
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    print("received locations \(locations )")
    locations.forEach { print("$0.horizontalAccuracy \($0.horizontalAccuracy)", "$0.verticalAccuracy \($0.verticalAccuracy), \n speed \($0.speed)")}
    
    do {
      try realm.write {
        realm.add(RealmLocation(location: locations[0]))
      }
    } catch {
      print("error saving realm \(error)")
    }
    
    publisher.send(.location(locations[0]) )
  }
  
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    print("received error \(error)")
    publisher.send(.error)
  }
}

extension CLLocation: Equatable {
  
}
