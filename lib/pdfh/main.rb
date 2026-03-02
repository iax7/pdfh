# frozen_string_literal: true

module Pdfh
  # Main functionality. This class is intended to manage the pdf documents
  class Main
    class << self
      # @param argv [Array<String>]
      # @return [void]
      def start(argv:)
        arg_options = Services::OptParser.new(argv: argv).parse_argv
        options = RunOptions.new(**arg_options)

        # Initialize the global logger
        Pdfh.logger = Console.new(options.verbose?)
        Pdfh.logger.print_options(arg_options)

        settings = Services::SettingsBuilder.call
        Pdfh.logger.debug "Destination path: #{settings.base_path.colorize(:light_blue)}"

        files = Services::DirectoryScanner.new(settings.lookup_dirs).scan
        matcher = Services::DocumentMatcher.new(settings.document_types)

        files.each do |file_path|
          Pdfh.logger.info "Working on: #{file_path.colorize(:green)}" if Pdfh.logger.verbose?
          text = Services::PdfTextExtractor.call(file_path)

          documents = matcher.match(file_path, text)
          next Pdfh.logger.debug "No document type match found for #{file_path.colorize(:yellow)}" if documents.empty?

          unless documents.one?
            matches = documents.map { _1.type.name.inspect }.join(", ")
            next Pdfh.logger.warn_print "Skipping #{file_path.inspect} as multiple matches found: #{matches}."
          end

          Services::DocumentManager.new(documents.first, base_path: settings.base_path, dry_run: options.dry?).call
        end

        nil
      rescue SettingsIOError => e
        Pdfh.logger.error_print(e.message, exit_app: false)
        exit(1)
      rescue StandardError => e
        Pdfh.logger.backtrace_print(e) if Pdfh.logger.verbose?
        Pdfh.logger.error_print(e.message)
      end
    end
  end
end
