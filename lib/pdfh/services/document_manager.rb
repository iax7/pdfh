# frozen_string_literal: true

module Pdfh
  module Services
    # Manages the documents, rename, move, etc.
    class DocumentManager
      PDF_UNLOCKED_MAGIC_SUFFIX = "_unlocked"

      # @param document [Document]
      # @param base_path [String]
      # @param dry_run [Boolean]
      # @return [DocumentManager]
      def initialize(document, base_path:, dry_run:)
        @document = document
        @base_path = base_path
        @dry_run = dry_run
      end

      # @return [void]
      def call
        destination_dir = File.join(@base_path, @document.store_path)
        destination_file = File.join(destination_dir, @document.new_name)

        print_info(destination_dir) if Pdfh.logger.verbose?
        create_destination_dir(destination_dir)
        copy_pdf(destination_file)
        move_companion_files(destination_dir)
        backup_original
      end

      private

      # @!attribute [rw] document
      #   @return [Document]
      attr_accessor :document

      # @return [Boolean]
      def dry_run? = @dry_run

      # @param dir [String]
      # @return [void]
      def create_destination_dir(dir)
        return if Dir.exist?(dir)

        Pdfh.logger.debug "Creating directory: #{dir}"
        FileUtils.mkdir_p(dir) unless @dry_run
      end

      # @param destination_file [String]
      # @return [void]
      def copy_pdf(destination_file)
        source_file = @document.file_info.path

        companion_extensions = companion_files.map { File.extname(_1).delete(".") }
        companion_str = companion_extensions.any? ? " [#{companion_extensions.join(", ").colorize(:magenta)}]" : ""
        message = format("[%<type>s] %<file>s -> %<dest>s#{companion_str}",
                         type: document.type.name.ljust(15).colorize(:green),
                         file: document.file_info.name.colorize(:blue),
                         dest: document.new_name.colorize(:cyan))
        if @dry_run
          Pdfh.logger.info "#{"dry".colorize(:red)} #{message}" unless Pdfh.logger.verbose?
          return
        end

        Pdfh.logger.info "#{"".colorize(:green)} #{message}" unless Pdfh.logger.verbose?
        FileUtils.cp(source_file, destination_file, preserve: true)
      end

      # @param destination_dir [String]
      # @return [void]
      def move_companion_files(destination_dir)
        companion_files.each do |companion|
          source = companion
          dest_name = File.basename(@document.new_name, @document.file_info.extension) + File.extname(companion)
          destination = File.join(destination_dir, dest_name)

          FileUtils.cp(source, destination, preserve: true) unless dry_run?
        end
      end

      # @return [void]
      def backup_original
        source_file = @document.file_info.path
        backup_file = "#{source_file}.bkp"

        FileUtils.mv(source_file, backup_file) unless dry_run?
      end

      # Finds companion files by removing the _unlocked suffix from the PDF name if present.
      # This allows PDFs unlock by qpdf to locate their original companion files (e.g., .xml, .txt)
      # that were never renamed with the _unlocked suffix.
      #
      # @return [Array<String>] array of non-PDF files with the same base name
      # @example
      #   # If document is "cuenta_unlocked.pdf", searches for "cuenta.*"
      #   # Returns ["cuenta.xml", "cuenta.txt"] (excluding "cuenta.pdf")
      def companion_files
        dir = @document.file_info.dir
        base_name = @document.file_info.stem.delete_suffix(PDF_UNLOCKED_MAGIC_SUFFIX)

        Dir.glob(File.join(dir, "#{base_name}.*")).reject do |file|
          File.extname(file) == ".pdf"
        end
      end

      # @param property [String]
      # @param info [String]
      # @return [void]
      def print_info_line(property, info)
        Pdfh.logger.ident_print property, info.to_s, color: :light_blue, width: 12
      end

      # @param destination_dir [String]
      # @return [void]
      def print_info(destination_dir)
        print_info_line "Type", document.type.name
        print_info_line "Period", document.date_info.period
        print_info_line "New Name", document.new_name
        print_info_line "Store Path", destination_dir
        print_info_line "Extra files", companion_files.any? ? companion_files.join(", ") : "—"
        print_info_line "Processed?", "No (in Dry mode)" if dry_run?
      end
    end
  end
end
