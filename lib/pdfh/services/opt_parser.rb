# frozen_string_literal: true

require "optparse"

module Pdfh
  module Services
    # Handles Argument options
    class OptParser
      # @param argv [Array<String>] command line arguments (ie. ARGV)
      # @param console [Pdfh::Console, nil]
      # @return [self]
      def initialize(argv:, console: nil)
        @argv = argv
        @console = console || Console.new(false)
        @options = {
          verbose: false,
          dry: false
        }
      end

      # @return [Hash] Parsed options including flags and file arguments
      def parse_argv
        option_parser = build_option_parser
        option_parser.parse!(@argv)
        @options
      rescue OptionParser::InvalidOption => e
        @console.error_print(e.message, exit_app: false)
        @console.info option_parser.help
        exit 1
      end

      private

      # @return [OptionParser] Configured OptionParser instance
      def build_option_parser
        OptionParser.new do |opts|
          opts.banner = "Usage: #{opts.program_name} [options]"
          opts.separator ""
          opts.separator "Specific options:"

          opts.on("-v", "--verbose", "Show more output. Useful for debug") { @options[:verbose] = true }
          opts.on("-d", "--dry", "Dry run, does not write new pdf") { @options[:dry] = true }
          opts.on_tail("-T", "--list-types", "List document types in configuration") { list_types && exit }
          opts.on_tail("-V", "--version", "Show version") { version || exit }
          opts.on_tail("-h", "--help", "help (this dialog)") { help || exit }
        end
      end

      # @return [nil]
      def version
        @console.info "#{build_option_parser.program_name} v#{Pdfh::VERSION}"
      end

      # @return [nil]
      def help
        @console.info build_option_parser
      end

      # Lists the available document types
      # @return [nil]
      def list_types
        # Temporarily set logger for loading settings
        Pdfh.logger = @console

        settings = SettingsBuilder.call
        spacing = " " * 2
        max_width = settings.document_types.map { |t| t.gid.size }.max
        @console.info "#{spacing}#{"ID".ljust(max_width)}  Type Name"
        @console.info "#{spacing}#{"—" * max_width}  #{"—" * 23}"
        settings.document_types.each do |type|
          @console.info "#{spacing}#{type.gid.ljust(max_width).yellow}  #{type.name}"
        end
      end
    end
  end
end
