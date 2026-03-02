# frozen_string_literal: true

# Standard library
require "fileutils"
require "tempfile"
require "yaml"

# External dependencies
require "colorize"

# Models
require_relative "pdfh/models/document"
require_relative "pdfh/models/document_type"
require_relative "pdfh/models/run_options"
require_relative "pdfh/models/settings"

# Utils
require_relative "pdfh/utils/console"
require_relative "pdfh/utils/dependency_validator"
require_relative "pdfh/utils/month"
require_relative "pdfh/utils/rename_validator"

# Services
require_relative "pdfh/services/directory_scanner"
require_relative "pdfh/services/opt_parser"
require_relative "pdfh/services/settings_validator"
require_relative "pdfh/services/settings_builder"
require_relative "pdfh/services/pdf_text_extractor"
require_relative "pdfh/services/document_matcher"
require_relative "pdfh/services/document_manager"

require_relative "pdfh/main"
require_relative "pdfh/version"

# Gem entry point
module Pdfh
  PROGRAM_NAME = "pdfh"
  REQUIRED_CMDS = %i[qpdf pdftotext].freeze

  # Settings not found
  class SettingsIOError < StandardError; end

  # Regular Date Error, when there is not match
  class ReDateError < StandardError
    # @param msg [String]
    # @return [ReDateError]
    def initialize(msg = "Date regular expression did not find a match in document.")
      super
    end
  end

  class << self
    # @!attribute [w] logger
    #   @return [Console]
    attr_writer :logger

    # @return [Console]
    def logger
      @logger ||= Console.new(false)
    end
  end
end
