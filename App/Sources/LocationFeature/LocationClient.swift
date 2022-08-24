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
//        // DEBUG
//        return Array(_testLocations[..<testCount])
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

        
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
          guard testCount < _testLocations.count else { return }
          locationDelegate.currentLocations.append(_testLocations[testCount])
          testCount += 1
          print("increment count \(testCount)")
        }).fire()
      }
    )
  }
}

var testCount: Int = 0
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
      print("updated currentLocations ")
      logger.info("currentLocations \(currentLocations.count)")
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


let _testLocations: [CLLocation] = [
  .init(latitude: 35.73537989, longitude: 139.77743680),
  .init(latitude: 35.73537989, longitude: 139.7774368),
  .init(latitude: 35.73547989, longitude: 139.7775368),
  .init(latitude: 35.73557989, longitude: 139.7776368),
  .init(latitude: 35.73567989, longitude: 139.7777368),
  .init(latitude: 35.735779889999996, longitude: 139.77783680000002),
  .init(latitude: 35.73587989, longitude: 139.7779368),
  .init(latitude: 35.735979889999996, longitude: 139.7780368),
  .init(latitude: 35.73607989, longitude: 139.7781368),
  .init(latitude: 35.736179889999995, longitude: 139.7782368),
  .init(latitude: 35.73627989, longitude: 139.7783368),
  .init(latitude: 35.736379889999995, longitude: 139.7784368),
  .init(latitude: 35.73647989, longitude: 139.7785368),
  .init(latitude: 35.736579889999994, longitude: 139.77863680000002),
  .init(latitude: 35.73667989, longitude: 139.7787368),
  .init(latitude: 35.736779889999994, longitude: 139.7788368),
  .init(latitude: 35.73687989, longitude: 139.7789368),
  .init(latitude: 35.73697989, longitude: 139.7790368),
  .init(latitude: 35.73707989, longitude: 139.7791368),
  .init(latitude: 35.73717989, longitude: 139.7792368),
  .init(latitude: 35.737279889999996, longitude: 139.7793368),
  .init(latitude: 35.73737989, longitude: 139.7794368),
  .init(latitude: 35.737479889999996, longitude: 139.77953680000002),
  .init(latitude: 35.73757989, longitude: 139.7796368),
  .init(latitude: 35.737679889999995, longitude: 139.7797368),
  .init(latitude: 35.73777989, longitude: 139.7798368),
  .init(latitude: 35.737879889999995, longitude: 139.7799368),
  .init(latitude: 35.73797989, longitude: 139.7800368),
  .init(latitude: 35.738079889999995, longitude: 139.7801368),
  .init(latitude: 35.73817989, longitude: 139.7802368),
  .init(latitude: 35.738279889999994, longitude: 139.78033680000001),
  .init(latitude: 35.73837989, longitude: 139.7804368),
  .init(latitude: 35.73847989, longitude: 139.7805368),
  .init(latitude: 35.73857989, longitude: 139.7806368),
  .init(latitude: 35.73867989, longitude: 139.7807368),
  .init(latitude: 35.738779889999996, longitude: 139.7808368),
  .init(latitude: 35.73887989, longitude: 139.7809368),
  .init(latitude: 35.738979889999996, longitude: 139.7810368),
  .init(latitude: 35.73907989, longitude: 139.7811368),
  .init(latitude: 35.739179889999996, longitude: 139.78123680000002),
  .init(latitude: 35.73927989, longitude: 139.7813368),
  .init(latitude: 35.739379889999995, longitude: 139.7814368),
  .init(latitude: 35.73947989, longitude: 139.7815368),
  .init(latitude: 35.739579889999995, longitude: 139.7816368),
  .init(latitude: 35.73967989, longitude: 139.7817368),
  .init(latitude: 35.739779889999994, longitude: 139.7818368),
  .init(latitude: 35.73987989, longitude: 139.7819368),
  .init(latitude: 35.73997989, longitude: 139.78203680000001),
  .init(latitude: 35.74007989, longitude: 139.78213680000002),
  .init(latitude: 35.74017989, longitude: 139.7822368),
  .init(latitude: 35.74027989, longitude: 139.7823368),
  .init(latitude: 35.74037989, longitude: 139.7824368),
  .init(latitude: 35.740479889999996, longitude: 139.7825368),
  .init(latitude: 35.74057989, longitude: 139.7826368),
  .init(latitude: 35.740679889999996, longitude: 139.7827368),
  .init(latitude: 35.74077989, longitude: 139.7828368),
  .init(latitude: 35.740879889999995, longitude: 139.78293680000002),
  .init(latitude: 35.74097989, longitude: 139.7830368),
  .init(latitude: 35.741079889999995, longitude: 139.7831368),
  .init(latitude: 35.74117989, longitude: 139.7832368),
  .init(latitude: 35.741279889999994, longitude: 139.7833368),
  .init(latitude: 35.74137989, longitude: 139.7834368),
  .init(latitude: 35.74147989, longitude: 139.7835368),
  .init(latitude: 35.74157989, longitude: 139.7836368),
  .init(latitude: 35.74167989, longitude: 139.7837368),
  .init(latitude: 35.74177989, longitude: 139.78383680000002),
  .init(latitude: 35.74187989, longitude: 139.7839368),
  .init(latitude: 35.741979889999996, longitude: 139.7840368),
  .init(latitude: 35.74207989, longitude: 139.7841368),
  .init(latitude: 35.742179889999996, longitude: 139.7842368),
  .init(latitude: 35.74227989, longitude: 139.7843368),
  .init(latitude: 35.742379889999995, longitude: 139.7844368),
  .init(latitude: 35.74247989, longitude: 139.7845368),
  .init(latitude: 35.742579889999995, longitude: 139.78463680000002),
  .init(latitude: 35.74267989, longitude: 139.7847368),
  .init(latitude: 35.742779889999994, longitude: 139.7848368),
  .init(latitude: 35.74287989, longitude: 139.7849368),
  .init(latitude: 35.742979889999994, longitude: 139.7850368),
  .init(latitude: 35.74307989, longitude: 139.7851368),
  .init(latitude: 35.74317989, longitude: 139.7852368),
  .init(latitude: 35.74327989, longitude: 139.7853368),
  .init(latitude: 35.74337989, longitude: 139.7854368),
  .init(latitude: 35.743479889999996, longitude: 139.78553680000002),
  .init(latitude: 35.74357989, longitude: 139.7856368),
  .init(latitude: 35.743679889999996, longitude: 139.7857368),
  .init(latitude: 35.74377989, longitude: 139.7858368),
  .init(latitude: 35.743879889999995, longitude: 139.7859368),
  .init(latitude: 35.74397989, longitude: 139.7860368),
  .init(latitude: 35.744079889999995, longitude: 139.7861368),
  .init(latitude: 35.74417989, longitude: 139.7862368),
  .init(latitude: 35.744279889999994, longitude: 139.78633680000002),
  .init(latitude: 35.74437989, longitude: 139.7864368),
  .init(latitude: 35.744479889999994, longitude: 139.7865368),
  .init(latitude: 35.74457989, longitude: 139.7866368),
  .init(latitude: 35.74467989, longitude: 139.7867368),
  .init(latitude: 35.74477989, longitude: 139.7868368),
  .init(latitude: 35.74487989, longitude: 139.7869368),
  .init(latitude: 35.744979889999996, longitude: 139.7870368),
  .init(latitude: 35.74507989, longitude: 139.7871368),
  .init(latitude: 35.745179889999996, longitude: 139.78723680000002),
  .init(latitude: 35.74527989, longitude: 139.7873368),
  .init(latitude: 35.745379889999995, longitude: 139.7874368),
  .init(latitude: 35.74547989, longitude: 139.7875368),
  .init(latitude: 35.745579889999995, longitude: 139.7876368),
  .init(latitude: 35.74567989, longitude: 139.7877368),
  .init(latitude: 35.745779889999994, longitude: 139.7878368),
  .init(latitude: 35.74587989, longitude: 139.7879368),
  .init(latitude: 35.745979889999994, longitude: 139.78803680000001),
  .init(latitude: 35.74607989, longitude: 139.78813680000002),
  .init(latitude: 35.74617989, longitude: 139.7882368),
  .init(latitude: 35.74627989, longitude: 139.7883368),
  .init(latitude: 35.74637989, longitude: 139.7884368),
  .init(latitude: 35.746479889999996, longitude: 139.7885368),
  .init(latitude: 35.74657989, longitude: 139.7886368),
  .init(latitude: 35.746679889999996, longitude: 139.7887368),
  .init(latitude: 35.74677989, longitude: 139.7888368),
  .init(latitude: 35.746879889999995, longitude: 139.78893680000002),
  .init(latitude: 35.74697989, longitude: 139.7890368),
  .init(latitude: 35.747079889999995, longitude: 139.7891368),
  .init(latitude: 35.74717989, longitude: 139.7892368),
  .init(latitude: 35.747279889999994, longitude: 139.7893368),
  .init(latitude: 35.74737989, longitude: 139.7894368),
  .init(latitude: 35.747479889999994, longitude: 139.7895368),
  .init(latitude: 35.74757989, longitude: 139.7896368),
  .init(latitude: 35.74767989, longitude: 139.78973680000001),
  .init(latitude: 35.74777989, longitude: 139.78983680000002),
  .init(latitude: 35.74787989, longitude: 139.7899368),
  .init(latitude: 35.747979889999996, longitude: 139.7900368),
  .init(latitude: 35.74807989, longitude: 139.7901368),
  .init(latitude: 35.748179889999996, longitude: 139.7902368),
  .init(latitude: 35.74827989, longitude: 139.7903368),
  .init(latitude: 35.748379889999995, longitude: 139.7904368),
  .init(latitude: 35.74847989, longitude: 139.7905368),
  .init(latitude: 35.748579889999995, longitude: 139.79063680000002),
  .init(latitude: 35.74867989, longitude: 139.7907368),
  .init(latitude: 35.748779889999994, longitude: 139.7908368),
  .init(latitude: 35.74887989, longitude: 139.7909368),
  .init(latitude: 35.748979889999994, longitude: 139.7910368),
  .init(latitude: 35.74907989, longitude: 139.7911368),
  .init(latitude: 35.74917989, longitude: 139.7912368),
  .init(latitude: 35.74927989, longitude: 139.7913368),
  .init(latitude: 35.74937989, longitude: 139.7914368),
  .init(latitude: 35.749479889999996, longitude: 139.79153680000002),
  .init(latitude: 35.74957989, longitude: 139.7916368),
  .init(latitude: 35.749679889999996, longitude: 139.7917368),
  .init(latitude: 35.74977989, longitude: 139.7918368),
  .init(latitude: 35.749879889999995, longitude: 139.7919368),
  .init(latitude: 35.74997989, longitude: 139.7920368),
  .init(latitude: 35.750079889999995, longitude: 139.7921368),
  .init(latitude: 35.75017989, longitude: 139.7922368),
  .init(latitude: 35.750279889999995, longitude: 139.79233680000002),
  .init(latitude: 35.75037989, longitude: 139.7924368),
  .init(latitude: 35.750479889999994, longitude: 139.7925368),
  .init(latitude: 35.75057989, longitude: 139.7926368),
  .init(latitude: 35.75067989, longitude: 139.7927368),
  .init(latitude: 35.75077989, longitude: 139.7928368),
  .init(latitude: 35.75087989, longitude: 139.7929368),
  .init(latitude: 35.750979889999996, longitude: 139.7930368),
  .init(latitude: 35.75107989, longitude: 139.7931368),
  .init(latitude: 35.751179889999996, longitude: 139.79323680000002),
  .init(latitude: 35.75127989, longitude: 139.7933368),
  .init(latitude: 35.751379889999995, longitude: 139.7934368),
  .init(latitude: 35.75147989, longitude: 139.7935368),
  .init(latitude: 35.751579889999995, longitude: 139.7936368),
  .init(latitude: 35.75167989, longitude: 139.7937368),
  .init(latitude: 35.751779889999995, longitude: 139.7938368),
  .init(latitude: 35.75187989, longitude: 139.7939368),
  .init(latitude: 35.751979889999994, longitude: 139.79403680000001),
  .init(latitude: 35.75207989, longitude: 139.7941368),
  .init(latitude: 35.75217989, longitude: 139.7942368),
  .init(latitude: 35.75227989, longitude: 139.7943368),
  .init(latitude: 35.75237989, longitude: 139.7944368),
  .init(latitude: 35.75247989, longitude: 139.7945368),
  .init(latitude: 35.75257989, longitude: 139.7946368),
  .init(latitude: 35.752679889999996, longitude: 139.7947368),
  .init(latitude: 35.75277989, longitude: 139.7948368),
  .init(latitude: 35.752879889999996, longitude: 139.79493680000002),
  .init(latitude: 35.75297989, longitude: 139.7950368),
  .init(latitude: 35.753079889999995, longitude: 139.7951368),
  .init(latitude: 35.75317989, longitude: 139.7952368),
  .init(latitude: 35.753279889999995, longitude: 139.7953368),
  .init(latitude: 35.75337989, longitude: 139.7954368),
  .init(latitude: 35.753479889999994, longitude: 139.7955368),
  .init(latitude: 35.75357989, longitude: 139.7956368),
  .init(latitude: 35.75367989, longitude: 139.79573680000001),
  .init(latitude: 35.75377989, longitude: 139.79583680000002),
  .init(latitude: 35.75387989, longitude: 139.7959368),
  .init(latitude: 35.75397989, longitude: 139.7960368),
  .init(latitude: 35.75407989, longitude: 139.7961368),
  .init(latitude: 35.754179889999996, longitude: 139.7962368),
  .init(latitude: 35.75427989, longitude: 139.7963368),
  .init(latitude: 35.754379889999996, longitude: 139.7964368),
  .init(latitude: 35.75447989, longitude: 139.7965368),
  .init(latitude: 35.754579889999995, longitude: 139.79663680000002),
  .init(latitude: 35.75467989, longitude: 139.7967368),
  .init(latitude: 35.754779889999995, longitude: 139.7968368),
  .init(latitude: 35.75487989, longitude: 139.7969368),
  .init(latitude: 35.754979889999994, longitude: 139.7970368),
  .init(latitude: 35.75507989, longitude: 139.7971368),
  .init(latitude: 35.755179889999994, longitude: 139.7972368),
  .init(latitude: 35.75527989, longitude: 139.7973368),
  .init(latitude: 35.75537989, longitude: 139.7974368),
  .init(latitude: 35.75547989, longitude: 139.79753680000002),
  .init(latitude: 35.75557989, longitude: 139.7976368),
  .init(latitude: 35.755679889999996, longitude: 139.7977368),
  .init(latitude: 35.75577989, longitude: 139.7978368),
  .init(latitude: 35.755879889999996, longitude: 139.7979368),
  .init(latitude: 35.75597989, longitude: 139.7980368),
  .init(latitude: 35.756079889999995, longitude: 139.7981368),
  .init(latitude: 35.75617989, longitude: 139.7982368),
  .init(latitude: 35.756279889999995, longitude: 139.79833680000002),
  .init(latitude: 35.75637989, longitude: 139.7984368),
  .init(latitude: 35.756479889999994, longitude: 139.7985368),
  .init(latitude: 35.75657989, longitude: 139.7986368),
  .init(latitude: 35.756679889999994, longitude: 139.7987368),
  .init(latitude: 35.75677989, longitude: 139.7988368),
  .init(latitude: 35.75687989, longitude: 139.7989368),
  .init(latitude: 35.75697989, longitude: 139.7990368),
  .init(latitude: 35.75707989, longitude: 139.7991368),
  .init(latitude: 35.757179889999996, longitude: 139.79923680000002),
  .init(latitude: 35.75727989, longitude: 139.7993368),
  .init(latitude: 35.757379889999996, longitude: 139.7994368),
  .init(latitude: 35.75747989, longitude: 139.7995368),
  .init(latitude: 35.757579889999995, longitude: 139.7996368),
  .init(latitude: 35.75767989, longitude: 139.7997368),
  .init(latitude: 35.757779889999995, longitude: 139.7998368),
  .init(latitude: 35.75787989, longitude: 139.7999368),
  .init(latitude: 35.89, longitude: 139.8),
  .init(latitude: 35.890100000000004, longitude: 139.80010000000001),
  .init(latitude: 35.8902, longitude: 139.80020000000002),
  .init(latitude: 35.8903, longitude: 139.80030000000002),
  .init(latitude: 35.8904, longitude: 139.80040000000002),
  .init(latitude: 35.8905, longitude: 139.8005),
  .init(latitude: 35.8906, longitude: 139.8006),
  .init(latitude: 35.8907, longitude: 139.8007),
  .init(latitude: 35.8908, longitude: 139.8008),
  .init(latitude: 35.8909, longitude: 139.8009),
  .init(latitude: 35.891, longitude: 139.80100000000002),
  .init(latitude: 35.8911, longitude: 139.80110000000002),
  .init(latitude: 35.8912, longitude: 139.80120000000002),
  .init(latitude: 35.8913, longitude: 139.8013),
  .init(latitude: 35.8914, longitude: 139.8014),
  .init(latitude: 35.8915, longitude: 139.8015),
  .init(latitude: 35.891600000000004, longitude: 139.8016),
  .init(latitude: 35.8917, longitude: 139.8017),
  .init(latitude: 35.8918, longitude: 139.80180000000001),
  .init(latitude: 35.8919, longitude: 139.80190000000002),
  .init(latitude: 35.892, longitude: 139.80200000000002),
  .init(latitude: 35.8921, longitude: 139.80210000000002),
  .init(latitude: 35.8922, longitude: 139.8022),
  .init(latitude: 35.8923, longitude: 139.8023),
  .init(latitude: 35.8924, longitude: 139.8024),
  .init(latitude: 35.8925, longitude: 139.8025),
  .init(latitude: 35.8926, longitude: 139.8026),
  .init(latitude: 35.8927, longitude: 139.80270000000002),
  .init(latitude: 35.8928, longitude: 139.80280000000002),
  .init(latitude: 35.8929, longitude: 139.80290000000002),
  .init(latitude: 35.893, longitude: 139.803),
  .init(latitude: 35.893100000000004, longitude: 139.8031),
  .init(latitude: 35.8932, longitude: 139.8032),
  .init(latitude: 35.8933, longitude: 139.8033),
  .init(latitude: 35.8934, longitude: 139.8034),
  .init(latitude: 35.8935, longitude: 139.8035),
  .init(latitude: 35.8936, longitude: 139.80360000000002),
  .init(latitude: 35.8937, longitude: 139.80370000000002),
  .init(latitude: 35.8938, longitude: 139.80380000000002),
  .init(latitude: 35.8939, longitude: 139.8039),
  .init(latitude: 35.894, longitude: 139.804),
  .init(latitude: 35.8941, longitude: 139.8041),
  .init(latitude: 35.8942, longitude: 139.8042),
  .init(latitude: 35.8943, longitude: 139.8043),
  .init(latitude: 35.8944, longitude: 139.80440000000002),
  .init(latitude: 35.8945, longitude: 139.80450000000002),
  .init(latitude: 35.894600000000004, longitude: 139.80460000000002),
  .init(latitude: 35.8947, longitude: 139.80470000000003),
  .init(latitude: 35.894800000000004, longitude: 139.8048),
  .init(latitude: 35.8949, longitude: 139.8049),
  .init(latitude: 35.895, longitude: 139.805),
  .init(latitude: 35.8951, longitude: 139.8051),
  .init(latitude: 35.8952, longitude: 139.8052),
  .init(latitude: 35.8953, longitude: 139.80530000000002),
  .init(latitude: 35.8954, longitude: 139.80540000000002),
  .init(latitude: 35.8955, longitude: 139.80550000000002),
  .init(latitude: 35.8956, longitude: 139.8056),
  .init(latitude: 35.8957, longitude: 139.8057),
  .init(latitude: 35.8958, longitude: 139.8058),
  .init(latitude: 35.8959, longitude: 139.8059),
  .init(latitude: 35.896, longitude: 139.806),
  .init(latitude: 35.896100000000004, longitude: 139.80610000000001),
  .init(latitude: 35.8962, longitude: 139.80620000000002),
  .init(latitude: 35.896300000000004, longitude: 139.80630000000002),
  .init(latitude: 35.8964, longitude: 139.80640000000002),
  .init(latitude: 35.8965, longitude: 139.8065),
  .init(latitude: 35.8966, longitude: 139.8066),
  .init(latitude: 35.8967, longitude: 139.8067),
  .init(latitude: 35.8968, longitude: 139.8068),
  .init(latitude: 35.8969, longitude: 139.8069),
  .init(latitude: 35.897, longitude: 139.80700000000002),
  .init(latitude: 35.8971, longitude: 139.80710000000002),
  .init(latitude: 35.8972, longitude: 139.80720000000002),
  .init(latitude: 35.8973, longitude: 139.8073),
  .init(latitude: 35.8974, longitude: 139.8074),
  .init(latitude: 35.8975, longitude: 139.8075),
  .init(latitude: 35.8976, longitude: 139.8076),
  .init(latitude: 35.8977, longitude: 139.8077),
  .init(latitude: 35.897800000000004, longitude: 139.80780000000001),
  .init(latitude: 35.8979, longitude: 139.80790000000002),
  .init(latitude: 35.898, longitude: 139.80800000000002),
  .init(latitude: 35.8981, longitude: 139.80810000000002),
  .init(latitude: 35.8982, longitude: 139.8082),
  .init(latitude: 35.8983, longitude: 139.8083),
  .init(latitude: 35.8984, longitude: 139.8084),
  .init(latitude: 35.8985, longitude: 139.8085),
  .init(latitude: 35.8986, longitude: 139.8086),
  .init(latitude: 35.8987, longitude: 139.80870000000002),
  .init(latitude: 35.8988, longitude: 139.80880000000002),
  .init(latitude: 35.8989, longitude: 139.80890000000002),
  .init(latitude: 35.899, longitude: 139.809),
  .init(latitude: 35.8991, longitude: 139.8091),
  .init(latitude: 35.8992, longitude: 139.8092),
  .init(latitude: 35.899300000000004, longitude: 139.8093),
  .init(latitude: 35.8994, longitude: 139.8094),
  .init(latitude: 35.8995, longitude: 139.8095),
  .init(latitude: 35.8996, longitude: 139.80960000000002),
  .init(latitude: 35.8997, longitude: 139.80970000000002),
  .init(latitude: 35.8998, longitude: 139.80980000000002),
  .init(latitude: 35.8999, longitude: 139.8099),
  .init(latitude: 35.9, longitude: 139.81),
  .init(latitude: 35.9001, longitude: 139.8101),
  .init(latitude: 35.9002, longitude: 139.8102),
  .init(latitude: 35.9003, longitude: 139.8103),
  .init(latitude: 35.9004, longitude: 139.81040000000002),
  .init(latitude: 35.9005, longitude: 139.81050000000002),
  .init(latitude: 35.9006, longitude: 139.81060000000002),
  .init(latitude: 35.9007, longitude: 139.81070000000003),
  .init(latitude: 35.900800000000004, longitude: 139.8108),
  .init(latitude: 35.9009, longitude: 139.8109),
  .init(latitude: 35.901, longitude: 139.811),
  .init(latitude: 35.9011, longitude: 139.8111),
  .init(latitude: 35.9012, longitude: 139.8112),
  .init(latitude: 35.9013, longitude: 139.81130000000002),
  .init(latitude: 35.9014, longitude: 139.81140000000002),
  .init(latitude: 35.9015, longitude: 139.81150000000002),
  .init(latitude: 35.9016, longitude: 139.8116),
  .init(latitude: 35.9017, longitude: 139.8117),
  .init(latitude: 35.9018, longitude: 139.8118),
  .init(latitude: 35.9019, longitude: 139.8119),
  .init(latitude: 35.902, longitude: 139.812),
  .init(latitude: 35.9021, longitude: 139.81210000000002),
  .init(latitude: 35.9022, longitude: 139.81220000000002),
  .init(latitude: 35.902300000000004, longitude: 139.81230000000002),
  .init(latitude: 35.9024, longitude: 139.81240000000003),
  .init(latitude: 35.9025, longitude: 139.8125),
  .init(latitude: 35.9026, longitude: 139.8126),
  .init(latitude: 35.9027, longitude: 139.8127),
  .init(latitude: 35.9028, longitude: 139.8128),
  .init(latitude: 35.9029, longitude: 139.8129),
  .init(latitude: 35.903, longitude: 139.81300000000002),
  .init(latitude: 35.9031, longitude: 139.81310000000002),
  .init(latitude: 35.9032, longitude: 139.81320000000002),
  .init(latitude: 35.9033, longitude: 139.8133),
  .init(latitude: 35.9034, longitude: 139.8134),
  .init(latitude: 35.9035, longitude: 139.8135),
  .init(latitude: 35.9036, longitude: 139.8136),
  .init(latitude: 35.9037, longitude: 139.8137),
  .init(latitude: 35.903800000000004, longitude: 139.81380000000001),
  .init(latitude: 35.9039, longitude: 139.81390000000002),
  .init(latitude: 35.904, longitude: 139.81400000000002),
  .init(latitude: 35.9041, longitude: 139.81410000000002),
  .init(latitude: 35.9042, longitude: 139.8142),
  .init(latitude: 35.9043, longitude: 139.8143),
  .init(latitude: 35.9044, longitude: 139.8144),
  .init(latitude: 35.9045, longitude: 139.8145),
  .init(latitude: 35.9046, longitude: 139.8146),
  .init(latitude: 35.9047, longitude: 139.81470000000002),
  .init(latitude: 35.9048, longitude: 139.81480000000002),
  .init(latitude: 35.9049, longitude: 139.81490000000002),
  .init(latitude: 35.905, longitude: 139.815),
  .init(latitude: 35.9051, longitude: 139.8151),
  .init(latitude: 35.9052, longitude: 139.8152),
  .init(latitude: 35.905300000000004, longitude: 139.8153),
  .init(latitude: 35.9054, longitude: 139.8154),
  .init(latitude: 35.9055, longitude: 139.81550000000001),
  .init(latitude: 35.9056, longitude: 139.81560000000002),
  .init(latitude: 35.9057, longitude: 139.81570000000002),
  .init(latitude: 35.9058, longitude: 139.81580000000002),
  .init(latitude: 35.9059, longitude: 139.8159),
  .init(latitude: 35.906, longitude: 139.816),
  .init(latitude: 35.9061, longitude: 139.8161),
  .init(latitude: 35.9062, longitude: 139.8162),
  .init(latitude: 35.9063, longitude: 139.8163),
  .init(latitude: 35.9064, longitude: 139.81640000000002),
  .init(latitude: 35.9065, longitude: 139.81650000000002),
  .init(latitude: 35.9066, longitude: 139.81660000000002),
  .init(latitude: 35.9067, longitude: 139.8167),
  .init(latitude: 35.906800000000004, longitude: 139.8168),
  .init(latitude: 35.9069, longitude: 139.8169),
  .init(latitude: 35.907000000000004, longitude: 139.817),
  .init(latitude: 35.9071, longitude: 139.8171),
  .init(latitude: 35.9072, longitude: 139.8172),
  .init(latitude: 35.9073, longitude: 139.81730000000002),
  .init(latitude: 35.9074, longitude: 139.81740000000002),
  .init(latitude: 35.9075, longitude: 139.81750000000002),
  .init(latitude: 35.9076, longitude: 139.8176),
  .init(latitude: 35.9077, longitude: 139.8177),
  .init(latitude: 35.9078, longitude: 139.8178),
  .init(latitude: 35.9079, longitude: 139.8179),
  .init(latitude: 35.908, longitude: 139.818),
  .init(latitude: 35.9081, longitude: 139.81810000000002),
  .init(latitude: 35.9082, longitude: 139.81820000000002),
  .init(latitude: 35.908300000000004, longitude: 139.81830000000002),
  .init(latitude: 35.9084, longitude: 139.81840000000003),
  .init(latitude: 35.908500000000004, longitude: 139.8185),
  .init(latitude: 35.9086, longitude: 139.8186),
  .init(latitude: 35.9087, longitude: 139.8187),
  .init(latitude: 35.9088, longitude: 139.8188),
  .init(latitude: 35.9089, longitude: 139.8189),
  .init(latitude: 35.909, longitude: 139.81900000000002),
  .init(latitude: 35.9091, longitude: 139.81910000000002),
  .init(latitude: 35.9092, longitude: 139.81920000000002),
  .init(latitude: 35.9093, longitude: 139.8193),
  .init(latitude: 35.9094, longitude: 139.8194),
  .init(latitude: 35.9095, longitude: 139.8195),
  .init(latitude: 35.9096, longitude: 139.8196),
  .init(latitude: 35.9097, longitude: 139.8197),
  .init(latitude: 35.9098, longitude: 139.81980000000001),
  .init(latitude: 35.9099, longitude: 139.81990000000002),

]
