Gem::Specification.new do |s|
  s.name        = 'Exspec'
  s.version     = '1.0.2'
  s.date        = '2013-03-10'
  s.summary     = "Exspec test framework"
  s.description = "Don't write specs anymore, just save 'em while testing your code interactively. Specs will become a byproduct."
  s.authors     = ["Helge Holzmann"]
  s.email       = 'helgeho@invelop.de'
  s.files       = Dir["{lib}/**/*.rb"]
  s.executables << 'exspec'
  s.homepage    = 'https://github.com/helgeho/Exspec'
  s.add_dependency('activesupport')
end