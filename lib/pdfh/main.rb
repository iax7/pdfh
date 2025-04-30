# frozen_string_literal: true

module Pdfh
  # Main functionality. This class is intended to manage the pdf documents
  class Main
    class << self
      # @param argv [Array<String>]
      # @return [void]
      def start(argv:)
        arg_options = Pdfh::OptParser.new(argv: argv).parse_argv
        @options = Options.new(arg_options)
        assign_global_utils(@options)
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

      # @param options [Options]
      # @return [void]
      def assign_global_utils(options)
        Pdfh.instance_variable_set(:@options, options)
        Pdfh.instance_variable_set(:@console, Console.new(options.verbose?))
      end

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
      def process_zip_files(work_directory)
        @settings.zip_types&.each do |zip_type|
          find_files(work_directory, :zip).each do |file|
            next unless zip_type.re_file.match?(File.basename(file))

            Pdfh.info " > Processing zip file: #{file.green}"
            password_opt = "-P #{zip_type.password}" if zip_type.password?
            `unzip -o #{password_opt} #{file} -d #{work_directory}`
          end
        end
      end

      # @param directory [String]
      # @param type [String, Symbol]
      # @return [Array<String>]
      def find_files(directory, type)
        glob = File.join(directory, "*.#{type}")
        Dir.glob(glob)
      end

      def process_directory(work_directory)
        Pdfh.headline(work_directory)
        process_zip_files(work_directory) if @settings.zip_types?
        processed_result = RunResult.new
        files = find_files(work_directory, :pdf)
        files.each do |pdf_file|
          type = match_doc_type(pdf_file)
          if type
            PdfFileHandler.new(pdf_file, type).process_document(settings.base_path)
            processed_result.add_processed(pdf_file)
          else
            processed_result.add_ignored(pdf_file)
          end
        end
        print_processing_results(processed_result)
      end

      # @return [String]
      def base_name_no_ext(file)
        File.basename(file, File.extname(file))
      end

      def print_processing_results(result)
        Pdfh.info "  (No files processed)".colorize(:light_black) if result.processed.empty?
        return unless Pdfh.verbose?

        Pdfh.info "\n  No document type found for these PDF files:" if result.ignored.any?
        result.ignored.each.with_index(1) do |file, index|
          Pdfh.ident_print index, base_name_no_ext(file), color: :magenta
        end
      end
    end

    # keeps track of the processed and ignored files
    class RunResult
      attr_reader :processed, :ignored

      # @return [self]
      def initialize
        @processed = []
        @ignored = []
      end

      # @return [void]
      def add_ignored(file) = @ignored << file

      # @return [void]
      def add_processed(file) = @processed << file
    end
  end
end
