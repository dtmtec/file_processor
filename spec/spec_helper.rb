require "bundler/setup"

require 'simplecov'
SimpleCov.start

Bundler.require :default

root = File.expand_path('../..', __FILE__)

Dir[File.join(root, "spec/support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
end
