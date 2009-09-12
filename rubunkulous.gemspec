GEM_NAME    = "rubunkulous"
AUTHOR      = "John Manoogian III"
EMAIL       = "jm3@jm3.net"
HOMEPAGE    = "http://jm3.net/"
SUMMARY     = "reentrant link-checker for del.icio.us power-users"
GEM_VERSION = "0.0.3"

spec = Gem::Specification.new do |s|
  s.files       = %w(bin/rubunkulous)
  s.bindir      = "bin"
  s.executables = ["rubunkulous"]
  s.default_executable = "rubunkulous"
  
  # my versions are in the commented parens below; YMMV:
  s.add_dependency('curb') # (0.5.1.0)
  s.add_dependency('moneta') # (0.6.0)
  s.add_dependency('progressbar') # (0.0.3)

  s.name              = GEM_NAME
  s.version           = GEM_VERSION
  s.platform          = Gem::Platform::RUBY
  s.has_rdoc          = true
  s.summary           = SUMMARY
  s.description       = s.summary
  s.author            = AUTHOR
  s.email             = EMAIL
  s.homepage          = HOMEPAGE
  s.rubyforge_project = 'rubunkulous'
end
