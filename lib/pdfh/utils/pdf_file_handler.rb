# frozen_string_literal: true

module Pdfh
  # Handles the PDF file
  class PdfFileHandler
    attr_reader :file, :type, :document

    # @param [String] file
    # @param [DocumentType, nil] type
    # @return [self]
    def initialize(file, type)
      @file = file
      @type = type
    end

    # @return [boolean]
    def type?
      !!type
    end

    # Generate document, and process actions
    # @return [void]
    def process_document(base_path)
      Pdfh.info "Working on #{base_name.colorize(:light_green)}"
      raise IOError, "File #{file} not found" unless File.exist?(file)

      @document = Document.new(file, type, extract_text)
      document.process
      document.print_info
      write_pdf(base_path)

      nil
    rescue StandardError => e
      Pdfh.ident_print "Doc Error", e.message, color: :red, width: 12
    end

    # Create a backup of original document
    # @return [void]
    def make_document_backup(document)
      Pdfh.debug "~~~~~~~~~~~~~~~~~~ Creating PDF backup"
      Dir.chdir(document.home_dir) do
        Pdfh.debug "  Working on: #{document.home_dir.inspect} directory"
        Pdfh.debug "    mv #{document.file_name.inspect} -> #{document.backup_name.inspect}"
        File.rename(document.file_name, document.backup_name) unless Pdfh.dry?
      end
    end

    # @return [void]
    def copy_companion_files(destination, document)
      Pdfh.debug "~~~~~~~~~~~~~~~~~~ Writing Companion files"
      document.companion_files.each do |file|
        Pdfh.debug "  Working on #{file.inspect}..."
        src_name = File.join(document.home_dir, file)
        src_ext = File.extname(file)
        dest_name = File.basename(document.new_name, ".pdf")
        dest_full = File.join(destination, "#{dest_name}#{src_ext}")
        Pdfh.debug "    cp #{src_name} --> #{dest_full}"
        FileUtils.cp(src_name, dest_full) unless Pdfh.dry?
      end
    end

    # @return [String]
    def base_name
      File.basename(file)
    end

    private

    # @return [void]
    def write_pdf(base_path)
      full_path = File.join(base_path, document.store_path, document.new_name)
      dir_path = File.join(base_path, document.store_path)

      FileUtils.mkdir_p(dir_path)

      write_new_pdf(dir_path, full_path)
      make_document_backup(document)
      copy_companion_files(dir_path, document)
    rescue StandardError => e
      Pdfh.ident_print "Doc Error", e.message, color: :red, width: IDENT
    end

    def qpdf_command(*args)
      password_option = type&.password ? "--password=#{type&.password.inspect} " : ""

      %(qpdf #{password_option}--decrypt #{args.join(" ")})
    end

    # Gets the text from the pdf in order to execute
    # the regular expression matches
    # @return [String]
    def extract_text
      temp = Tempfile.new("pdfh")
      Pdfh.debug "~~~~~~~~~~~~~~~~~~ Extract PDF text"
      Pdfh.debug "  --> #{temp.path} temporal file assigned."

      cmd1 = qpdf_command("--stream-data=uncompress", file.inspect, temp.path)
      Pdfh.debug "  DeCrypt Command: #{cmd1}"
      _result = `#{cmd1}`

      cmd2 = %(pdftotext -enc UTF-8 #{temp.path} -)
      Pdfh.debug "  Extract Command: #{cmd2}"
      text = `#{cmd2}`
      Pdfh.debug "  Text: #{text.inspect}"
      text
    end

    # @return [void]
    def write_new_pdf(dir_path, full_path)
      Pdfh.debug "~~~~~~~~~~~~~~~~~~ Writing PDFs"
      raise IOError, "Path #{dir_path} not found." unless Dir.exist?(dir_path)

      cmd = qpdf_command(file.inspect, full_path.inspect)
      Pdfh.debug "  Write PDF Command: #{cmd}"

      return if Pdfh.dry?

      _result = `#{cmd}`
      raise IOError, "New PDF file #{full_path.inspect} was not created." unless File.file?(full_path)
    end
  end
end
