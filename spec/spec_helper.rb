# frozen_string_literal: true

require "bundler/setup"
require "pry"
# Load support files
Dir[File.expand_path(File.join("spec", "support", "**", "*.rb"))].each { |f| require f }

require "pdfh"
require_relative "shared_config"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before do
    stub_const("ENV", ENV.to_hash.merge("PDFH_CONFIG_FILE" => nil))
  end
end
