# frozen_string_literal: true

module Pdfh
  # Lightweight struct that connects a PDF file with its matched document type and
  # extracted text. All file metadata, date interpretation, and rename resolution
  # are accessible through dedicated value objects (FileInfo, DateInfo).
  class Document
    # @!attribute [r] file_info
    #   @return [FileInfo] File metadata wrapper
    # @!attribute [r] type
    #   @return [DocumentType] Matched document type
    # @!attribute [r] text
    #   @return [String] Extracted text from the PDF
    # @!attribute [r] date_info
    #   @return [DateInfo] Parsed date value object
    attr_reader :file_info, :type, :text, :date_info

    # @param file [String] Path to the PDF file
    # @param type [DocumentType] Type of the document
    # @param text [String] Extracted text from the PDF
    # @param date_captures [Hash{String => String}] Captured date components from regex
    # @return [self] A new Document instance
    def initialize(file, type, text, date_captures)
      @type = type
      @text = text
      @file_info = FileInfo.new(file)
      @date_info = DateInfo.new(date_captures)
    end

    # @return [String] Document type name or "N/A" if type is nil
    def type_name
      type&.name || "N/A"
    end

    # @return [String] File name
    def to_s
      file_info.name
    end

    # @return [String] New file name with extension (e.g., "2024-01 Cuenta.pdf")
    def new_name
      "#{@type.name_validator.gsub(rename_data)}#{@file_info.extension}"
    end

    # @return [String] Storage path for the document (e.g., "2024/Edo Cuenta")
    def store_path
      @type.path_validator.gsub(rename_data)
    end

    private

    # Used to replace variables in the rename pattern i.e {original}, {period}, etc.
    # @return [Hash{Symbol => String}] Hash containing rename variables
    def rename_data
      @rename_data ||= {
        original: @file_info.stem,
        period: @date_info.period,
        year: @date_info.year.to_s,
        month: @date_info.month.to_s,
        quarter: "Q#{@date_info.quarter}",
        bimester: "B#{@date_info.bimester}",
        name: @type.name,
        day: @date_info.day || ""
      }.freeze
    end
  end
end
