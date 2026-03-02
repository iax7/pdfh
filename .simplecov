# frozen_string_literal: true

require "English"

SimpleCov.start do
  # Basic configuration
  enable_coverage :branch
  minimum_coverage line: 75, branch: 40

  # Filters to exclude files that don't need coverage
  add_filter "/spec/"
  add_filter "/bin/"
  add_filter "/exe/"
  add_filter "/vendor/"

  # HTML formatter only - no console noise
  formatter SimpleCov::Formatter::HTMLFormatter

  # Groups to organize the report
  add_group "Models", "lib/pdfh/models"
  add_group "Services", "lib/pdfh/services"
  add_group "Utils", "lib/pdfh/utils"

  # Track files
  track_files "lib/**/*.rb"

  # Show clearer messages on failure
  at_exit do
    # Only run if there is no other error
    SimpleCov.result.format! if $ERROR_INFO.nil? || ($ERROR_INFO.is_a?(SystemExit) && $ERROR_INFO.success?)
  end
end
