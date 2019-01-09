# frozen_string_literal: true

require 'simplecov'
require 'simplecov-console'

# Simplecov
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::Console,
  SimpleCov::Formatter::HTMLFormatter
])
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/bin/'
  add_filter '/exe/'
  add_group 'Classes', '/lib/pdfh/'
end

require 'bundler/setup'
require 'pdfh'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
    expectations.syntax = :expect
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!
end
