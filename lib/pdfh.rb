# frozen_string_literal: true

require "ext/string"
require "colorize"

require "pdfh/version"
require "pdfh/document_period"
require "pdfh/document_type"
require "pdfh/document"
require "pdfh/month"
require "pdfh/opt_parser"
require "pdfh/pdf_handler"
require "pdfh/settings"
require "pdfh/settings_template"
require "pdfh/document_processor"

# Gem entry point
module Pdfh
  # Settings not found
  class SettingsIOError < StandardError; end

  # Regular Date Error, when there is not match
  class ReDateError < StandardError
    def initialize(msg = "Date regular expression did not find a match in document.")
      super
    end
  end

  class << self
    attr_writer :verbose, :dry, :mode

    # @return [Boolean]
    def verbose?
      @verbose
    end

    # @return [Boolean]
    def dry?
      @dry
    end

    # @return [Boolean]
    def file_mode?
      @mode == :file
    end

    # Returns rows, cols
    # TODO: review https://gist.github.com/nixpulvis/6025433
    # @return [Array<Integer, Integer>]
    def console_size
      `stty size`.split.map(&:to_i)
    end

    # Prints visual separator in shell for easier reading for humans
    # @example output
    #   [Title Text] -----------------------
    # @param msg [String]
    # @return [void]
    def headline(msg)
      _, cols = console_size
      line_length = cols - (msg.size + 5)
      left  = "\033[31m#{"—" * 3}\033[0m"
      right = "\033[31m#{"—" * line_length}\033[0m"
      puts "\n#{left} \033[1;34m#{msg}\033[0m #{right}"
    end

    # @param msg [Object]
    # @return [void]
    def verbose_print(msg = nil)
      puts msg.to_s.colorize(:cyan) if verbose?
    end

    # @param message [String]
    # @param exit_app [Boolean] exit application if true (default)
    # @return [void]
    def error_print(message, exit_app: true)
      puts "Error, #{message}".colorize(:red)
      exit 1 if exit_app
    end

    # @param message [String]
    # @return [void]
    def warn_print(message)
      puts message.colorize(:yellow)
    end

    # @return [void]
    def ident_print(field, value, color: :green, width: 3)
      field_str = field.to_s.rjust(width)
      value_str = value.colorize(color)
      puts "#{" " * 4}#{field_str}: #{value_str}"
    end

    # @return [Hash]
    def parse_argv
      options = {}
      OPT_PARSER.parse!(into: options)
      options[:files] = ARGV if ARGV.any?
      options.transform_keys { |key| key.to_s.tr("-", "_").to_sym }
    rescue OptionParser::InvalidOption => e
      error_print e.message, exit_app: false
      puts OPT_PARSER.help
      exit 1
    end

    # @return [String]
    def config_file_name
      File.basename($PROGRAM_NAME)
    end

    # @return [void]
    def create_settings_file
      full_path = File.join(File.expand_path("~"), "#{config_file_name}.yml")
      return if File.exist?(full_path) # double check

      File.write(full_path, Pdfh::SETTINGS_TEMPLATE.to_yaml)
      puts "Settings #{full_path.inspect.colorize(:green)} was created."
    end

    # @raise [SettingsIOError] if no file is found
    # @return [String]
    def search_config_file
      names_to_look = %W[#{config_file_name}.yml #{config_file_name}.yaml]
      dir_order = [Dir.pwd, File.expand_path("~")]

      dir_order.each do |dir|
        names_to_look.each do |file|
          path = File.join(dir, file)
          return path if File.exist?(path)
        end
      end

      raise SettingsIOError, "no configuration file (#{names_to_look.join(" or ")}) was found\n       " \
                             "within paths: #{dir_order.join(", ")}"
    end
  end
end
