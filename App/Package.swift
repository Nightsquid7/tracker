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
         .package(url: "https://github.com/realm/realm-swift.git", from: "10.28.2")
    ],
    
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
      .target(name: "AppFeature",
              dependencies: [
                .product(name: "ComposableArchitecture",
                         package: "swift-composable-architecture"),
                "LocationFeature",
                "MapFeature"
                    ]),
      
        .target(name: "LocationFeature",
                dependencies: [
                  .product(name: "ComposableArchitecture",
                           package: "swift-composable-architecture"),
                
                    .product(name: "RealmSwift", package: "realm-swift"),
                    "Models"
                ]),
      
        .target(name: "MapFeature",
                dependencies: [
                  .product(name: "ComposableArchitecture",
                           package: "swift-composable-architecture"),
              
                ]),
      
        .target(name: "Models", dependencies: [
          .product(name: "RealmSwift", package: "realm-swift"),
        ]),
                
      ]
)
