Pod::Spec.new do |s|
  s.name             = "SODAKit"
  s.version          = "0.1"
  s.summary          = "SODAKit is a native Swift library to access Socrata OpenData servers. It is compatible with iOS 8 and OS X 10.10."
  s.homepage         = "http://socrata.github.io/soda-swift/"
  s.license          = 'Apache'
  s.author           = { "Chris Metcalf" => "" }
  s.source           = { :git => "https://github.com/socrata/soda-swift.git", :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.9'
  s.tvos.deployment_target = "9.0"
  s.watchos.deployment_target = "2.0"
  s.requires_arc = true
  s.source_files  = ['SODAKit/**/*.swift', 'SODAKit/**/*.h']
  s.xcconfig      = {
                    }
end
