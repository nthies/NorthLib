// swift-tools-version:5.5

// Set isIos to false to build executables and to omit iOS-specific modules
var isIos = false

import PackageDescription

#if os(Linux)
  let pkgConfigXml: String? = "libxml-2.0"
  let pkgConfigZlib: String? = "zlib"
#else
  let pkgConfigXml: String? = nil
  let pkgConfigZlib: String? = nil
#endif

let providerXml: [SystemPackageProvider] = [ .apt(["libxml2-dev"]) ]
let providerZlib: [SystemPackageProvider] = [ .apt(["zlib-dev"]) ]

var linkerSettings: [LinkerSetting] = [.linkedLibrary("z"), .linkedLibrary("c++")]

var targets: [Target] = [
  .systemLibrary(
    name: "Clibcpp", 
    path: "src/Clibcpp"
  ),
  .systemLibrary(
    name: "Clibzip", 
    path: "src/Clibzip",
    pkgConfig: pkgConfigZlib,
    providers: providerZlib
  ),
  .systemLibrary(
    name: "Clibxml2", 
    path: "src/Clibxml2",
    pkgConfig: pkgConfigXml,
    providers: providerXml
  ),
  .target(
    name: "NorthLowLevel",
    dependencies: ["Clibcpp", "Clibzip"],
    path: "src/LowLevel",
    exclude: ["doc"]
  ),
  .target(
    name: "NorthBase",
    dependencies: ["NorthLowLevel"],
    path: "src/Base"
  ),
  .testTarget(
    name: "TestLowlevel",
    dependencies: ["NorthLowLevel"],
    path: "test/LowLevel",
    linkerSettings: linkerSettings
  ),
  .testTarget(
    name: "TestBase",
    dependencies: ["NorthBase"],
    path: "test/Base",
    exclude: ["test.zip"],
    linkerSettings: linkerSettings
  ),
]

var targetsFoundation: [Target] = [
  .target(
    name: "NorthFoundation",
    dependencies: ["NorthBase"],
    path: "src/Foundation"
  ),
  .testTarget(
    name: "TestFoundation",
    dependencies: ["NorthFoundation"],
    path: "test/Foundation",
    linkerSettings: linkerSettings
  ),
]

var northDep: Target.Dependency = "NorthBase"

#if canImport(Foundation)
  targets.append(contentsOf: targetsFoundation)
  northDep = Target.Dependency("NorthFoundation")
#endif

let targetsNorthLib: [Target] = [
  .target(
    name: "NorthLib",
    dependencies: [northDep],
    path: "src/NorthLib",
    linkerSettings: linkerSettings
  ),
]

let targetsNorthLibUIKit: [Target] = [
  .target(
    name: "NorthUIKit",
    dependencies: ["NorthFoundation"],
    path: "src/UIKit"
  ),
  .target(
    name: "NorthLib",
    dependencies: ["NorthUIKit"],
    path: "src/NorthLib",
    linkerSettings: linkerSettings
  ),
  .testTarget(
    name: "TestUIKit",
    dependencies: ["NorthUIKit"],
    path: "test/UIKit",
    linkerSettings: linkerSettings
  ),
]

var executableTargets: [Target] = [
  .executableTarget(
    name: "unzip",
    dependencies: [
      "NorthBase",
      .product(name: "ArgumentParser", package: "swift-argument-parser"),
    ],
    path: "src/unzip",
    linkerSettings: linkerSettings
  ),
]

func getTargets(isIos: Bool = true) -> [Target] {
  if isIos { targets.append(contentsOf: targetsNorthLibUIKit) }
  else { 
    targets.append(contentsOf: targetsNorthLib) 
    targets.append(contentsOf: executableTargets) 
  }
  return targets
}

var products: [Product] = [
  .library(
    name: "NorthLib",
    type: .static,
    targets: ["NorthLib"]
  )
]

var executableProducts: [Product] = [
  .executable(
    name: "unzip", 
    targets: ["unzip"]
  ),
]

func getProducts(isIos: Bool = true) -> [Product] {
  if !isIos { products.append(contentsOf: executableProducts) }
  return products
}

var dependencies: [Package.Dependency] = []
var executableDependencies: [Package.Dependency] = [
  .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
]

func getDependencies(isIos: Bool = true) -> [Package.Dependency] {
  if !isIos { dependencies.append(contentsOf: executableDependencies) }
  return dependencies
}

let package = Package(
  name: "NorthLib",
  defaultLocalization: "en",
  platforms: [.iOS(.v13), .macOS(.v10_15), .tvOS(.v13), .watchOS(.v6)],
  products: getProducts(isIos: isIos),
  dependencies: getDependencies(isIos: isIos),
  targets: getTargets(isIos: isIos),
  cxxLanguageStandard: .cxx20
)
