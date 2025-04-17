# frozen_string_literal: true

module Pdfh
  # Main functionality. This class is intended to manage the pdf documents
  class Main
    class << self
      # @return [void]
      def start
        arg_options = Pdfh::OptParser.parse_argv
        @options = Options.new(arg_options)

        Pdfh.instance_variable_set(:@options, options)
        Pdfh.instance_variable_set(:@console, Console.new(options.verbose?))
        Pdfh.print_options(arg_options)

        @settings = SettingsBuilder.build
        Pdfh.debug "Destination path: #{settings.base_path.colorize(:light_blue)}"

        options.file_mode? ? process_provided_files : process_lookup_dirs
      rescue SettingsIOError => e
        Pdfh.error_print(e.message, exit_app: false)
        Pdfh.create_settings_file
        exit(1)
      rescue StandardError => e
        Pdfh.backtrace_print e if Pdfh.verbose?
        Pdfh.error_print(e.message)
      end

      private

      attr_reader :options, :settings

      # @param [String] file_name
      # @return [DocumentType, nil]
      def match_doc_type(file_name)
        settings.document_types.each do |type|
          match = type.re_file.match(file_name)
          return type if match
        end
        nil
      end

      # @return [void]
      def process_provided_files
        type_id = options.type
        raise ArgumentError, "No files provided to process #{type_id.inspect} type." unless options.files?

        type = settings.document_type(type_id)
        Pdfh.error_print "Type #{type_id.inspect} was not found." if type.nil?
        options.files.each do |file|
          next Pdfh.warn_print "File #{file.inspect} does not exist." unless File.exist?(file)
          next Pdfh.warn_print "File #{file.inspect} is not a pdf." unless File.extname(file) == ".pdf"

          PdfFileHandler.new(file, type).process_document(settings.base_path)
        end
      end

      # @return [void]
      def process_lookup_dirs
        settings.lookup_dirs.each do |work_directory|
          process_directory(work_directory)
        end
      end

      # @param [String] work_directory
      # @return [void]
      def process_directory(work_directory)
        Pdfh.headline(work_directory)
        processed_count = 0
        ignored_files = []
        files = Dir["#{work_directory}/*.pdf"]
        files.each do |pdf_file|
          type = match_doc_type(pdf_file)
          if type
            processed_count += 1
            PdfFileHandler.new(pdf_file, type).process_document(settings.base_path)
          else
            ignored_files << base_name_no_ext(pdf_file)
          end
        end
        puts "  (No files processed)".colorize(:light_black) if processed_count.zero?
        return unless Pdfh.verbose?

        puts "\n  No document type found for these PDF files:" if ignored_files.any?
        ignored_files.each.with_index(1) { |file, index| Pdfh.ident_print index, file, color: :magenta }
      end

      # @return [String]
      def base_name_no_ext(file)
        File.basename(file, File.extname(file))
      end
    end
  end
end
