# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'guvera/dynamodb/version'

Gem::Specification.new do |spec|
  spec.name          = "guvera-dynamodb"
  spec.version       = Guvera::Dynamodb::VERSION
  spec.authors       = ["Ray Hilton"]
  spec.email         = ["ray.hilton@guvera.com"]
  spec.summary       = %q{A DynamoDB model mapping tool for ruby.}
  spec.description   = %q{The motivation of this project was to create something like Dynamoid except using AWS SDK v2 and allowing access to modern DynamoDB features.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "aws-sdk", "> 2.1"
  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
