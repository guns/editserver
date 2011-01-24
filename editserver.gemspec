# -*- encoding: utf-8 -*-

$:.unshift File.expand_path('../lib', __FILE__)
require 'editserver/version'

Gem::Specification.new do |s|
  s.name        = 'editserver'
  s.version     = Editserver::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Sung Pae']
  s.email       = ['sung@metablu.com']
  s.homepage    = 'http://github.com/guns/editserver'
  s.summary     = %q{Your favorite editor, in every app}
  s.description = %Q{Simple local server for editing text in your favorite editor.}

  s.rubyforge_project = 'editserver'

  s.files         = %x(git ls-files).split "\n"
  s.test_files    = %x(git ls-files -- {test,spec,features}/*).split "\n"
  s.executables   = %x(git ls-files -- bin/*).split("\n").map { |f| File.basename f }
  s.require_paths = ['lib']

  s.add_dependency 'rack', '~> 1.2'

  s.add_development_dependency 'minitest', '~> 2.0'
  s.add_development_dependency 'ruby-debug19' if RUBY_VERSION >= '1.9.0'
end
