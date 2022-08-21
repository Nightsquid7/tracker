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
  public var getCurrentLocations: () -> [CLLocation]
  public var getDistances: () -> Void
  public var deleteRealm: () -> Void
  public var testLocations: () -> Void
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
        locationManager.activityType = .otherNavigation
        locationManager.startMonitoringSignificantLocationChanges()
        
        locationManager.delegate = locationDelegate

        
        return locationDelegate
          .publisher
          .eraseToEffect()
      },
      
      getAllSavedCoordinates: {
        return Array(locationDelegate.realm.objects(RealmLocation.self).sorted(by: { $0.timestamp > $1.timestamp }).map { $0.clCoordinate2d() })
      },
      
      getAllSavedLocations: {
        // print locations...
        //        Array(locationDelegate.realm.objects(RealmLocation.self).sorted(by: { $0.timestamp > $1.timestamp }).map { $0.location() }).forEach { print($0)}
        return Array(locationDelegate.realm.objects(RealmLocation.self).sorted(by: { $0.timestamp > $1.timestamp }).map { $0.location() })
      }, getCurrentLocations: {
        return locationDelegate.currentLocations
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
      },
      testLocations: {
        print("Test locations")
        let locations = [
          CLLocation(coordinate: CLLocationCoordinate2D(latitude: 35.736378, longitude: 139.778412), altitude: 0, horizontalAccuracy: 0, verticalAccuracy: 0, course: 0, speed: 1, timestamp: Date(timeIntervalSinceNow: -6)),
          CLLocation(coordinate: CLLocationCoordinate2D(latitude: 35.736004, longitude: 139.778314), altitude: 0, horizontalAccuracy: 0, verticalAccuracy: 0, course: 0, speed: 1, timestamp: Date(timeIntervalSinceNow: -5)),
          CLLocation(coordinate: CLLocationCoordinate2D(latitude: 35.735638, longitude: 139.778314), altitude: 0, horizontalAccuracy: 0, verticalAccuracy: 0, course: 0, speed: 1, timestamp: Date(timeIntervalSinceNow: -4)),
          CLLocation(coordinate: CLLocationCoordinate2D(latitude: 35.735072, longitude: 139.778400), altitude: 0, horizontalAccuracy: 0, verticalAccuracy: 0, course: 0, speed: 1, timestamp: Date(timeIntervalSinceNow: -3)),
          CLLocation(coordinate: CLLocationCoordinate2D(latitude: 35.734863, longitude: 139.778658), altitude: 0, horizontalAccuracy: 0, verticalAccuracy: 0, course: 0, speed: 1, timestamp: Date(timeIntervalSinceNow: -2)),
          CLLocation(coordinate: CLLocationCoordinate2D(latitude: 35.734218, longitude: 139.778765), altitude: 0, horizontalAccuracy: 0, verticalAccuracy: 0, course: 0, speed: 1, timestamp: Date(timeIntervalSinceNow: -1)),
        ]
        
        logger.info("Programatically adding locations..")
        for location in locations {
          print("add locations \(location)")
          locationDelegate.locationManager(locationManager, didUpdateLocations: [location])
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
  case updatedLocation
  case message(String)
  case error
}

final class LocationDelegate: NSObject, CLLocationManagerDelegate {
  let publisher = PassthroughSubject<LocationEvent, Never>()
  let realm: Realm
  // cache the last saved location to avoid checking db every time location is received
  var lastSavedLocation: CLLocation?
  
  var currentLocations: [CLLocation] = [] {
    didSet(newValue) {
      print("updated currentLocations")
      publisher.send(.updatedLocation)
    }
  }
  
  override init() {
    var config = Realm.Configuration(shouldCompactOnLaunch: { totalBytes, usedBytes in
      logger.info("bytes used \(usedBytes)  total bytes\(totalBytes)")
      return false
    })
    config.deleteRealmIfMigrationNeeded = true
    realm = try! Realm(configuration: config)
    
    let path = realm.configuration.fileURL!.path
    let attributes = try! FileManager.default.attributesOfItem(atPath: path)
    if let fileSize = attributes[FileAttributeKey.size] as? Double {
      logger.info("size of realm: \(fileSize)")
      
      logger.info("realmLocation memoryLayout: \(MemoryLayout<RealmLocation>.size)")
      
      logger.info("class_getInstanceSize(RealmLocation.self) \(class_getInstanceSize(RealmLocation.self))")
      print(fileSize)
    }
  }
    
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    logger.info("received locations: \(locations.count)")
    // FIXME: don't get this from database, store this in KeyChain
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
        currentLocations.append(mostRecentLocation)
//        publisher.send(.location(mostRecentLocation) )
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
