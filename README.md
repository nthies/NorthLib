[![SPM compatible](https://img.shields.io/badge/SPM-compatible-4BC51D.svg?style=flat)](https://github.com/apple/swift-package-manager)

# NorthLib

NorthLib is a library of Swift types primarily intended to support iOS development.
Although the main focus is on iOS, we modularized the library so that limited support
for other platforms is available.
Beside some wrappers of system libraries (to make these libraries available in Swift)
the following modules are available:

- NorthLowLevel<br/>
  Offers some C-functions based on POSIX libc library functions. Since Swift's
  standard library still lacks base OS functionality we feel the necessity to
  provide some minimal Swift types in NorthBase (see below) to be independent 
  from Apple's Foundation module. Thus at least some functionality is available
  for Swift programs running on Linux.
  In addition we offer an interface for reading zip-Files as a stream, i.e. the
  ability to unpack a zip data stream without having to wait for the final table
  of contents.
  
- NorthBase<br/>
  Offers Swift types purely based on the Swift standard library, NorthLowLevel
  and POSIX functions (e.g. class File). 
  
- NorthFoundation<br/>
  Extends NorthBase and imports _Foundation_ to offer additional Functionality which
  is only available on MacOS and iOS (+ derivatives).
  
- NorthUIKit<br/>
  Imports _UIKit_ and is therefore only available on iOS compatible platforms. 
  In a later release we might support Mac Catalyst as well.
  
- NorthLib<br/>
  Is a tiny module that only imports NorthBase, NorthFoundation, NorthUIKit and
  re-exports all symbols from these modules, similar to how UIKit re-exports the
  symbols from Foundation.
  
- unzip<br/>
  Is an executable based on NorthBase to test the zip stream unpacker.
  
## File-Tree

The source files are grouped under the _src_ subdirectory. C library wrappers 
reside in C&lt;library&gt; directories and the above noted modules are organized in:
````
  LowLevel   -> NorthLowLevel sources
  Base       -> NorthBase sources
  Foundation -> NorthFoundation sources
  UIKit      -> NorthUIKit sources
  unzip      -> unzip test utility
````

## How to build

To build the NorthLib library use:
````
  swift build --product NorthLib
````
or to build the optimized release version:
````
  swift build -c release --product NorthLib
````
The _unzip_ utility is built using: 
  swift build -c release --product unzip
````

## How to use

Add the dependency to the product NorthLib either to your Package.swift or to 
your Xcode project and link to libc++ and libz, eg. in Package.swift add:
````
  linkerSettings: [.linkedLibrary("z"), .linkedLibrary("c++")] 
````
to your target's definition.

## Authors

Norbert Thies, norbert@taz.de<br/>
Ringo Müller, ringo.mueller@taz.de

## License

NorthLib is available under the LGPL. See the LICENSE file for more info.
