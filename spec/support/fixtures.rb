module FixturesSupport
  def fixture(filename)
    File.join(root_path, "/spec/support/fixtures", filename)
  end

  def root_path
    File.expand_path('../../..', __FILE__)
  end
end

RSpec.configure do |config|
  config.include FixturesSupport
end
