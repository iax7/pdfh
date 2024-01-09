# frozen_string_literal: true

require "optparse"

module Pdfh
  # Handles Argument options
  class OptParser
    OPT_PARSER = OptionParser.new do |opts|
      opts.default_argv
      # Process ARGV
      opts.banner = "Usage: #{opts.program_name} [options] [file1 ...]"
      opts.separator ""
      opts.separator "Specific options:"

      opts.on("-tID", "--type=ID", "Document type id (requires a trailing file list)")
      opts.on_tail("-T", "--list-types", "List document types in configuration") do
        settings = SettingsBuilder.build
        ident = 4
        max_width = settings.document_types.map { |t| t.gid.size }.max
        puts "#{" " * ident}#{"ID".ljust(max_width)}  Type Name"
        puts "#{" " * ident}#{"—" * max_width}  #{"—" * 23}"
        settings.document_types.each do |type|
          puts "#{" " * ident}#{type.gid.ljust(max_width).yellow}  #{type.name.inspect}"
        end
        exit
      end
      opts.on_tail("-V", "--version", "Show version") do
        puts "#{opts.program_name} v#{Pdfh::VERSION}"
        exit
      end
      opts.on_tail("-h", "--help", "help (this dialog)") do
        puts opts
        exit
      end

      opts.on("-v", "--verbose", "Show more output. Useful for debug")
      opts.on("-d", "--dry", "Dry run, does not write new pdf")
    end

    class << self
      # @return [Hash]
      def parse_argv
        Pdfh.instance_variable_set(:@console, Console.new(false))

        options = { dry: false, verbose: false }
        OPT_PARSER.parse!(into: options)
        options[:files] = ARGV if ARGV.any?
        options.transform_keys { |key| key.to_s.tr("-", "_").to_sym }
      rescue OptionParser::InvalidOption => e
        error_print e.message, exit_app: false
        puts OPT_PARSER.help
        exit 1
      end
    end
  end
end
