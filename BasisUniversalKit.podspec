Pod::Spec.new do |s|

  s.name         = "BasisUniversalKit"
  s.version      = "0.0.3"
  s.summary      = "Load and use Basis Universal image format in iOS."

  s.description  = <<-DESC
                    BasisUniversalKit
                   DESC

  s.homepage     = "https://github.com/imbrig/BasisUniversalKit"
  
  s.license      = { :type => "Apache-2.0", :file => "LICENSE" }

  s.authors            = { "abcd" => "abcd@abcd.com" }

  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.10"
  s.source = { :git => "https://github.com/imbrig/BasisUniversalKit.git", :tag => s.version }
  
  s.source_files  = "BasisUniversalKit/*.{h,swift}", "BasisUniversalKit/basis_universal/transcoder/*.{h,cpp,inc}"
  s.public_header_files = ["BasisUniversalKit/BasisUniversalKit.h", "BasisUniversalKit/basis_universal/transcoder/basisu.h", "BasisUniversalKit/basis_universal/basisu_transcoder.h"]
  s.library   = "abcd"
  s.swift_version = '4.2'
end
