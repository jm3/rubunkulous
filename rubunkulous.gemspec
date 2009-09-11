
GEM_NAME    = "rubunkulous"
AUTHOR      = "John Manoogian III"
EMAIL       = "jm3@jm3.net"
HOMEPAGE    = "http://jm3.net/"
SUMMARY     = "reentrant link-checker for del.icio.us power-users"
GEM_VERSION = "0.0.1"

spec = Gem::Specification.new do |s|
  s.files = %w(bin/rubunkulous.rb)
  s.add_dependency('curb')
  s.add_dependency('moneta')
  s.add_dependency('moneta/basic_file')
  s.add_dependency('moneta/xattr')
  s.add_dependency('net/https')
  s.add_dependency('progressbar')
  s.add_dependency('rexml/document')

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
