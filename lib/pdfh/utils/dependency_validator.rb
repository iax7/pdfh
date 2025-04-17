# frozen_string_literal: true

require "open3"

module Pdfh
  module Utils
    # Provides methods to validate external dependencies
    module DependencyValidator
      module_function

      # Validates if the required command-line applications are installed
      # @param apps [Array<String>] names of required command-line applications
      # @return [Boolean] true if all applications are installed, false otherwise
      def installed?(*apps)
        missing = apps.filter_map do |app|
          _stdout, _stderr, status = Open3.capture3("which #{app}")

          app.to_s unless status.success?
        end

        if missing.any?
          errors = missing.map(&:red)
          puts "Required dependency #{errors.join(", ")} not found. Please install it before continuing."
        end
        missing.empty?
      end

      # @param apps [Array<String>]
      # @return [Boolean] true if any application is missing, false if all are installed
      def missing?(*apps)
        !installed?(*apps)
      end
    end
  end
end
