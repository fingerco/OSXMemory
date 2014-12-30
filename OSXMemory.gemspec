Gem::Specification.new do |s|
  s.name        = 'OSXMemory'
  s.version     = '0.0.1'
  s.date        = '2014-12-30'
  s.summary     = "Memory Editing library for 64-bit Mac OSX applications"
  s.description = "Memory Editing library for 64-bit Mac OSX applications"
  s.authors     = ["Cory Finger"]
  s.email       = 'fingerco@ccs.neu.edu'
  s.files       = ["lib/OSXMemory.rb"]
  s.homepage    = 'https://github.com/fingerco/OSXMemory'
  s.license     = 'MIT'

  s.add_runtime_dependency "ffi"
end