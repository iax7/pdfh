# frozen_string_literal: true

require "fileutils"

module Pdfh
  # Main functionality. This class is intended to manage the pdf documents
  class DocumentProcessor
    # @return [self]
    def initialize
      @options = Pdfh.parse_argv
      Pdfh.verbose = options[:verbose]
      Pdfh.dry = options[:dry]
      Pdfh.verbose_print(options)
      @mode = options.key?(:type) ? :file : :directory
    end

    # @return [void]
    def start
      @settings = Settings.new(Pdfh.search_config_file)
      puts "Destination path: #{@settings.base_path.colorize(:light_blue)}" if Pdfh.verbose?

      @mode == :file ? process_files : process_lookup_dirs
    rescue SettingsIOError => e
      Pdfh.error_print(e.message, exit_app: false)
      Pdfh.create_settings_file
      exit(1)
    rescue StandardError => e
      Pdfh.error_print e.message
    end

    private

    attr_reader :options

    # @param [String] file_name
    # @return [DocumentType]
    def match_doc_type(file_name)
      @settings.document_types.each do |type|
        match = type.re_file.match(file_name)
        return type if match
      end
      nil
    end

    # @return [DocumentType]
    def doc_type_by_id(id)
      @settings.document_types.find { |t| t.gid == id }
    end

    # @return [void]
    def process_files
      type_id = options[:type]
      raise ArgumentError, "No files provided to process #{type_id.inspect} type." unless options[:files]

      type = doc_type_by_id(type_id)
      puts
      options[:files].each do |file|
        unless File.exist?(file)
          Pdfh.warn_print "File #{file.inspect} does not exist."
          next
        end
        unless File.extname(file) == ".pdf"
          Pdfh.warn_print "File #{file.inspect} is not a pdf."
          next
        end
        process_document(file, type)
      end
    end

    # @return [void]
    def process_lookup_dirs
      @settings.lookup_dirs.each do |work_directory|
        process_directory(work_directory)
      end
    end

    # @param [String] work_directory
    # @return [Enumerator]
    def process_directory(work_directory)
      Pdfh.headline(work_directory)
      processed_count = 0
      ignored_files = []
      files = Dir["#{work_directory}/*.pdf"]
      files.each do |pdf_file|
        type = match_doc_type(pdf_file)
        if type
          processed_count += 1
          process_document(pdf_file, type)
        else
          ignored_files << basename_without_ext(pdf_file)
        end
      end
      puts "  (No files processed)".colorize(:light_black) if processed_count.zero?
      return unless Pdfh.verbose?

      puts "\n  No document type found for these PDF files:" if ignored_files.any?
      ignored_files.each.with_index(1) { |file, index| Pdfh.ident_print index, file, color: :magenta }
    end

    ##
    # Generate document, and process actions
    # @param [String] file
    # @param [DocumentType] type
    # @return [void]
    def process_document(file, type)
      base = File.basename(file)
      puts "Working on #{base.colorize(:light_green)}"
      pad = 12
      Pdfh.ident_print "Type", type.name, color: :light_blue, width: pad
      doc = Document.new(file, type)
      Pdfh.ident_print "Sub-Type", doc.sub_type, color: :light_blue, width: pad
      Pdfh.ident_print "Period", doc.period, color: :light_blue, width: pad
      Pdfh.ident_print "New Name", doc.new_name, color: :light_blue, width: pad
      Pdfh.ident_print "Store Path", doc.store_path, color: :light_blue, width: pad
      Pdfh.ident_print "Other files", doc.companion_files(join: true), color: :light_blue, width: pad
      Pdfh.ident_print "Print CMD", doc.print_cmd, color: :light_blue, width: pad
      Pdfh.ident_print "Processed?", "No (in Dry mode)", color: :red, width: pad if Pdfh.dry?
      write_pdf(doc)
    rescue StandardError => e
      Pdfh.ident_print "Doc Error", e.message, color: :red, width: pad
    end

    def write_pdf(document)
      base_path = @settings.base_path
      full_path = File.join(base_path, document.store_path, document.new_name)
      dir_path = File.join(base_path, document.store_path)

      FileUtils.mkdir_p(dir_path) unless File.exist?(dir_path)

      document.pdf_doc.write_new_pdf(dir_path, full_path)
      make_document_backup(document)
      copy_companion_files(dir_path, document)
    end

    # Create a backup of original document
    def make_document_backup(document)
      Pdfh.verbose_print "~~~~~~~~~~~~~~~~~~ Creating PDF backup"
      Dir.chdir(document.home_dir) do
        Pdfh.verbose_print "  Working on: #{document.home_dir.inspect} directory"
        Pdfh.verbose_print "    mv #{document.file_name.inspect} -> #{document.backup_name.inspect}"
        File.rename(document.file_name, document.backup_name) unless Pdfh.dry?
      end
    end

    def copy_companion_files(destination, document)
      Pdfh.verbose_print "~~~~~~~~~~~~~~~~~~ Writing Companion files"
      document.companion_files.each do |file|
        Pdfh.verbose_print "  Working on #{file.inspect}..."
        src_name = File.join(document.home_dir, file)
        src_ext = File.extname(file)
        dest_name = File.basename(document.new_name, ".pdf")
        dest_full = File.join(destination, "#{dest_name}#{src_ext}")
        Pdfh.verbose_print "    cp #{src_name} --> #{dest_full}"
        FileUtils.cp(src_name, dest_full) unless Pdfh.dry?
      end
    end

    # @return [String]
    def basename_without_ext(file)
      File.basename(file, File.extname(file))
    end
  end
end
