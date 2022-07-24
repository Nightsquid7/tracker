import Combine
import ComposableArchitecture
import CoreLocation
import Models
import RealmSwift
import LoggerFeature

public struct LocationClient {
  public var startListening: () -> Effect<LocationEvent, Never>
  public var getAllSavedCoordinates: () -> [CLLocationCoordinate2D]
  public var getAllSavedLocations: () -> [CLLocation]
  public var getDistances: () -> Void
  public var deleteRealm: () -> Void
}


extension LocationClient {
  public static var live: Self {
    
    let locationManager = CLLocationManager()
    let locationDelegate = LocationDelegate()
      
    locationManager.delegate = locationDelegate
    
    
    return Self(
      startListening: {
        
        
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
      
      getAllSavedCoordinates: {
        return Array(locationDelegate.realm.objects(RealmLocation.self).sorted(by: { $0.timestamp > $1.timestamp }).map { $0.clCoordinate2d() })
      },
      
      getAllSavedLocations: {
        return Array(locationDelegate.realm.objects(RealmLocation.self).sorted(by: { $0.timestamp > $1.timestamp }).map { $0.location() })
      }, getDistances: {
        let locations = locationDelegate.realm.objects(RealmLocation.self).sorted(by: { $0.timestamp > $1.timestamp })
        var locationsToDelete: [RealmLocation] = []
        for (loc1, loc2) in zip(locations, locations[1...]) {
          let distance = loc1.location().distance(from: loc2.location())
          if distance < 20 {
            print("We should delete realm with distance: \(distance) \(loc2)")
            locationsToDelete.append(loc2)
          }
        }
        try! locationDelegate.realm.write {
          locationDelegate.realm.delete(locationsToDelete)
        }
      },
      
      deleteRealm: {
        print("Delete all")
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
  case message(String)
  case error
  
  public func toString() -> String {
    switch self {
    case .location(let location):
      return "\(location.timestamp.description(with: .current)) lat: \(String(format: "%3.3f", location.coordinate.latitude)) long: \(String(format: "%3.3f", location.coordinate.longitude))"
    case .message(let message):
      return message
    case .error: return "error"
    }
  }
}

final class LocationDelegate: NSObject, CLLocationManagerDelegate {
  let publisher = PassthroughSubject<LocationEvent, Never>()
  let realm: Realm
  // cache the last saved location to avoid checking db every time location is received
  var lastSavedLocation: CLLocation?
  
  override init() {
    var config = Realm.Configuration()
    config.deleteRealmIfMigrationNeeded = true
    realm = try! Realm(configuration: config)
  }
    
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    logger.info("received locations: \(locations.count)")
    guard let mostRecentLocation = locations.last else { return }
    if lastSavedLocation == nil {
      lastSavedLocation = realm.objects(RealmLocation.self).max(by: { $0.timestamp < $1.timestamp})?.location()
      logger.info("lastSavedLocation is nil, lastSavedLocation in database is: \(lastSavedLocation)")
    }
    
    guard let lastSavedLocation = lastSavedLocation else {
      // Save the point to realm and exit
      logger.info("lastSavedLocation is nil, cache lastSavedLocation, save mostRecentLocation to realm")
      lastSavedLocation = mostRecentLocation
      do {
        try realm.write {
          realm.add(RealmLocation(location: mostRecentLocation))
        }
      } catch {
        logger.info("error saving realm \(error)")
      }
      return
    }
    
    logger.info("mostRecentLocation speed: \(mostRecentLocation.speed) .distance(from: lastSavedLocation) \(mostRecentLocation.distance(from: lastSavedLocation)) \n \(mostRecentLocation)")
    
    if mostRecentLocation.distance(from: lastSavedLocation) > 10 && mostRecentLocation.speed > 0 {
      logger.info("save point with distance \(mostRecentLocation.distance(from: lastSavedLocation)), speed: \(mostRecentLocation.speed)")
      do {
        try realm.write {
          realm.add(RealmLocation(location: mostRecentLocation))
        }
        publisher.send(.location(mostRecentLocation) )
      } catch {
        logger.info("error saving realm \(error)")
      }
    }
    
    self.lastSavedLocation = mostRecentLocation
  }
  
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    logger.info("received error \(error)")
    publisher.send(.error)
  }
}
