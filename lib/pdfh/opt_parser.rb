# frozen_string_literal: true

require "optparse"

module Pdfh
  OPT_PARSER = OptionParser.new do |opts|
    opts.default_argv
    # Process ARGV
    opts.banner = "Usage: #{opts.program_name} [options] [file1 ...]"
    opts.separator ""
    opts.separator "Specific options:"

    opts.on("-tID", "--type=ID", "Document type id (requires a trailing file list)")
    opts.on_tail("-T", "--list-types", "List document types in configuration") do
      settings = Settings.new(Pdfh.search_config_file)
      ident = 4
      max_width = settings.document_types.map { |t| t.gid.size }.max
      puts "#{" " * ident}#{"ID".ljust(max_width)}  Type Name"
      puts "#{" " * ident}#{"-" * max_width}  -----------------------"
      settings.document_types.each do |type|
        puts "#{" " * ident}#{type.gid.ljust(max_width)}  #{type.name.inspect}"
      end
      exit
    rescue SettingsIOError => e
      Pdfh.error_print(e.message, exit_app: false)
      Pdfh.create_settings_file
      exit(1)
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
end
