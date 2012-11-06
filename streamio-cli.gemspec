# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'streamio-cli/version'

Gem::Specification.new do |gem|
  gem.name          = "streamio-cli"
  gem.version       = Streamio::Exporter::VERSION
  gem.authors       = ["David Backeus"]
  gem.email         = ["david.backeus@streamio.com"]
  gem.summary       = "Command line interface for exporting data from Streamio accounts."
  gem.homepage      = "https://github.com/streamio/streamio-exporter"

  gem.files         = Dir.glob("lib/**/*") + Dir.glob("bin/*") + %w(README.md LICENSE CHANGELOG.md)

  gem.executables   = "streamio"

  gem.add_dependency "streamio", "~> 0.9.2"
  gem.add_dependency "thor", "~> 0.16.0"
  gem.add_dependency "ruby-progressbar", "~> 1.0.2"
  gem.add_dependency "excon", "~> 0.16.7"

  gem.add_development_dependency "rake", "~> 0.9.2"
end
