require 'simplecov'
require 'simplecov-rcov'

SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
SimpleCov.start do
  add_filter "vendor"
  add_filter "examples"
  add_filter "spec"
end if ENV["COVERAGE"]

require 'colloquy'

RSpec.configure do |config|
  config.raise_errors_for_deprecations!
end
