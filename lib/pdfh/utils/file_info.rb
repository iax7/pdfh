# frozen_string_literal: true

module Pdfh
  # Encapsulates file system metadata for a PDF file path.
  # Responsible for all file name derivations (extension, base name, backup name, etc.).
  class FileInfo
    # @param file_path [String] Absolute or relative path to the PDF file
    # @return [self]
    def initialize(file_path)
      @path = file_path.to_s
    end

    # @return [String] Full path to the file
    attr_reader :path

    # @return [String] File name without extension (e.g., "cuenta")
    def stem
      File.basename(@path, extension)
    end
    alias name_only stem

    # @return [String] File extension including the dot (e.g., ".pdf")
    def extension
      File.extname(@path)
    end

    # @return [String] Complete file name (e.g., "cuenta.pdf")
    def name
      File.basename(@path)
    end

    # @return [String] Backup file name with .bkp extension (e.g., "cuenta.pdf.bkp")
    def backup_name
      "#{name}.bkp"
    end

    # @return [String] Directory path containing the file
    def dir
      File.dirname(@path)
    end

    # @return [String] File name
    def to_s
      name
    end
  end
end
