# frozen_string_literal: true

require_relative "support/simplecov_setup"

require "bundler/setup"
require "pdfh"
require_relative "shared_config"

# Load other support files (excluding simplecov_setup which is already loaded)
Dir[File.expand_path("spec/support/**/*.rb")].each do |f|
  require f unless f.end_with?("simplecov_setup.rb")
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.warnings = false

  config.before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("PDFH_CONFIG_FILE").and_return(nil)
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("PDFH_CONFIG_FILE", anything).and_return(nil)
  end
end
