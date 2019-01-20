Pod::Spec.new do |s|
  s.name             = 'Path.swift'
  s.version          = '0.4.1'
  s.summary          = 'Delightful, robust file-pathing functions'
  s.homepage         = 'https://github.com/mxcl/Path.swift'
  s.license          = { :type => 'Unlicense', :file => 'LICENSE.md' }
  s.author           = { 'mxcl' => 'mxcl@me.com' }
  s.source           = { :git => 'https://github.com/mxcl/Path.swift.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/mxcl'

  s.osx.deployment_target = '10.10'
  s.ios.deployment_target = '8.0'
  s.tvos.deployment_target = '10.0'
  s.watchos.deployment_target = '3.0'

  s.source_files = 'Sources/*'
  
  s.swift_version = "4.2"
end
