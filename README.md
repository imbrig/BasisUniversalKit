# BasisUniversalKit

BasisUniversalKit is a high performance framework for loading and displaying basis-universal images in iOS and macOS. It's built on top of (https://github.com/BinomialLLC/basis_universal) with basis-universal support and written in Objective-C and Swift wrappers. Special mention goes to https://metalbyexample.com/basis-universal/ for using the MBEBasisTextureLoader class for loading images and returning Metal Textures.

## What and Why?

## Installation

### Requirement

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects.

CocoaPods 0.36 adds supports for Swift and embedded frameworks. You can install it with the following command:

```bash
$ gem install cocoapods
```

To integrate BasisUniversalKit into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

target 'your_app' do
  pod 'BasisUniversalKit', '~> 1.0'
end
```

Then, run the following command:

```bash
$ pod install
```
Note that in some projects, the `modular_headers` flag needs to be set to true. The PodFile for the parent project should for example look like below.
```pod 'BasisUniversalKit', :git => 'git@github.com:imbrig/BasisUniversalKit.git', :tag => '1.0.0', :modular_headers => true```

You should open the `{Project}.xcworkspace` instead of the `{Project}.xcodeproj` after you installed anything from CocoaPods.

For more information about how to use CocoaPods, I suggest [this tutorial](http://www.raywenderlich.com/64546/introduction-to-cocoapods-2).

## Acknowledgement

## Reference

## License

### Changelog ###
### 1.0.0
* Initial release after testing and configuring cocoapods.