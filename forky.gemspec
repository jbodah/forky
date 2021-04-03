# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'forky/version'

Gem::Specification.new do |spec|
  spec.name          = 'forky'
  spec.version       = Forky::VERSION
  spec.authors       = ['Josh Bodah']
  spec.email         = ['jb3689@yahoo.com']

  spec.summary       = 'A library for simple distributed tasks'
  spec.homepage      = 'https://github.com/jbodah/forky'
  spec.license       = 'MIT'

  spec.files         = Dir.glob('lib/**/*') + %w[CHANGELOG.md LICENSE.txt README.md Rakefile]
  spec.test_files    = Dir.glob('{test,spec}/**/*')
  spec.require_path  = 'lib'

  spec.required_ruby_version = '>= 2.4'

  spec.add_dependency 'concurrent-ruby'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
end
