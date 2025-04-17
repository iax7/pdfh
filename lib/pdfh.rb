# frozen_string_literal: true

require "base64"
require "colorize"
require "fileutils"
require "forwardable"
require "tempfile"
require "yaml"

require_relative "ext/string"

# Models
require_relative "pdfh/models/document"
require_relative "pdfh/models/document_period"
require_relative "pdfh/models/document_sub_type"
require_relative "pdfh/models/document_type"
require_relative "pdfh/models/settings"

# Utils
require_relative "pdfh/utils/console"
require_relative "pdfh/utils/dependency_validator"
require_relative "pdfh/utils/month"
require_relative "pdfh/utils/opt_parser"
require_relative "pdfh/utils/options"
require_relative "pdfh/utils/pdf_file_handler"
require_relative "pdfh/utils/rename_validator"
require_relative "pdfh/utils/settings_builder"

require_relative "pdfh/main"
require_relative "pdfh/settings_template"
require_relative "pdfh/version"

# Gem entry point
module Pdfh
  REQUIRED_CMDS = %i[qpdf pdftotext].freeze

  # Settings not found
  class SettingsIOError < StandardError; end

  # Regular Date Error, when there is not match
  class ReDateError < StandardError
    # @return [self]
    def initialize(msg = "Date regular expression did not find a match in document.")
      super
    end
  end

  class << self
    extend Forwardable
    def_delegators :@options, :verbose?, :dry?, :file_mode?
    def_delegators :@console, :ident_print, :warn_print, :error_print, :backtrace_print, :headline, :debug, :info, :print_options
  end
end
