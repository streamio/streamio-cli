require 'bundler'
Bundler.require

require 'webmock/rspec'

RSpec.configure do |config|
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end

def webmock_fixture(path)
  File.read("#{fixture_path}/webmock/#{path}")
end

def fixture_path
  @fixture_path ||= File.join(File.dirname(__FILE__), 'fixtures')
end
