// swift-tools-version:5.5

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

var products: [Product] = [
  .library(
    name: "NorthLib",
    type: .static,
    //targets: ["NorthLib"]
    targets: ["zip"]
  )
]

#if os(Linux) || os(macOS)
  products.append(Product.executable(
    name: "unzip", 
    targets: ["unzip"]
  ) )
#endif

let package = Package(
  name: "NorthLib",
  defaultLocalization: "en",
  platforms: [
    .iOS(.v12),         //.v8 - .v13
    .macOS(.v10_10),    //.v10_10 - .v10_15
    .tvOS(.v13),        //.v9 - .v13
    .watchOS(.v6),      //.v2 - .v6
  ],
  products: products,
  dependencies: [
    // .package(url: /* package url */, from: "1.0.0"),
  ],
  targets: [
    .systemLibrary(
      name: "libzip", 
      path: "src/libzip",
      pkgConfig: pkgConfigZlib,
      providers: providerZlib
    ),
    .systemLibrary(
      name: "libxml2", 
      path: "src/libxml2",
      pkgConfig: pkgConfigXml,
      providers: providerXml
    ),
    .target(
      name: "lowlevel",
      dependencies: [],
      path: "src/lowlevel"
    ),
    .target(
      name: "zip",
      dependencies: ["lowlevel", "libzip"],
      path: "src/zip"
    ),
    .executableTarget(
      name: "unzip",
      dependencies: ["zip"],
      path: "src/unzip"
    ),
    .testTarget(
      name: "lowlevelTest",
      dependencies: ["zip"],
      path: "test",
      sources: ["lowlevelTest.mm"]
    ),
  ]
)
