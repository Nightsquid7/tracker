// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "App",
    platforms: [
      .macOS(.v11),
      .iOS(.v14)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "App",
            targets: ["AppFeature"]),
    ],
    
    dependencies: [
         .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "0.35.0"),
         .package(url: "https://github.com/realm/realm-swift.git", from: "10.28.2"),
         .package(url: "https://github.com/kean/Pulse", from: "1.1.0")
    ],
    
    targets: [
       
      .target(name: "AppFeature",
              dependencies: [
                .product(name: "ComposableArchitecture",
                         package: "swift-composable-architecture"),
                "LocationFeature",
                "LoggerFeature",
                "MapFeature",
                "TrackerUI",
                .productItem(name: "Pulse",
                             package: "Pulse"),
                .productItem(name: "PulseUI",
                             package: "Pulse"),
                    ]),
              
        .target(name: "LoggerFeature", dependencies: [.productItem(name: "Pulse",
                                                                   package: "Pulse"),]),
        .target(name: "LocationFeature",
                dependencies: [
                  .product(name: "ComposableArchitecture",
                           package: "swift-composable-architecture"),
                
                    .product(name: "RealmSwift", package: "realm-swift"),
                    "Models",
                    "LoggerFeature",
                    .productItem(name: "Pulse",
                                 package: "Pulse"),
                ]),
      
        .target(name: "MapFeature",
                dependencies: [
                  .product(name: "ComposableArchitecture",
                           package: "swift-composable-architecture"),
                  .productItem(name: "Pulse",
                               package: "Pulse"),
                  "LoggerFeature",
              
                ]),
      
        .target(name: "Models", dependencies: [
          .product(name: "RealmSwift", package: "realm-swift"),
          .productItem(name: "Pulse",
                       package: "Pulse"),
        ]),
      
        .target(name: "TrackerUI",
                dependencies: [
                  .product(name: "ComposableArchitecture",
                           package: "swift-composable-architecture"),
//                  "LocationFeature",
//                  "LoggerFeature",
                  "MapFeature",
                  .productItem(name: "Pulse",
                               package: "Pulse"),
                  .productItem(name: "PulseUI",
                               package: "Pulse"),
                      ]),
                
      ]
)
