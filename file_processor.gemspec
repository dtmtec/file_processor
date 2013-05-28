# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'file_processor/version'

Gem::Specification.new do |gem|
  gem.name          = "file_processor"
  gem.version       = FileProcessor::VERSION
  gem.authors       = ["Vicente Mundim"]
  gem.email         = ["vicente.mundim@gmail.com"]
  gem.description   = %q{A more powerful CSV file processor}
  gem.summary       = %q{A more powerful CSV file processor}

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
