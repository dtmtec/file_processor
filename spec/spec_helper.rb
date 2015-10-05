require "bundler/setup"

require 'simplecov'
SimpleCov.start do
  add_filter '/spec'
end

Bundler.require :default

begin
  require 'byebug'
rescue LoadError
end

root = File.expand_path('../..', __FILE__)

Dir[File.join(root, "spec/support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
end
