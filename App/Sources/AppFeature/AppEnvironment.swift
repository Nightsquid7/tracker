import LocationFeature

public struct AppEnvironment {
  var locationClient: LocationClient
  public init(locationClient: LocationClient) {
    self.locationClient = locationClient
  }
}

extension AppEnvironment {
  public static var live: Self {
    return Self(locationClient: .live)
  }
}
