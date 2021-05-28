Pod::Spec.new do |spec|
  spec.name           = "Path.swift"
  spec.version        = ENV['VERSION'] || "0.0.1"
  spec.summary        = "Delightful, robust, cross-platform and chainable file-pathing functions."
  spec.homepage       = "https://github.com/mxcl/Path.swift"
  spec.license        = "Unlicense"
  spec.author         = { "Max Howell" => "mxcl@me.com" }
  spec.source         = { :git => "https://github.com/mxcl/Path.swift.git", :tag => "#{spec.version}" }
  spec.source_files   = "Sources/*.swift"
  spec.swift_versions = ['4.2', '5']
  spec.module_name    = 'Path'
  spec.osx.deployment_target     = '10.10'
  spec.ios.deployment_target     = '8.0'
  spec.tvos.deployment_target    = '9.0'
  spec.watchos.deployment_target = '2.0'
end
