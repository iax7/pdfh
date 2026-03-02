# frozen_string_literal: true

module Pdfh
  # Handles the PDF detected by the rules
  class Document
    # @!attribute [r] text
    #   @return [String] The extracted text from the PDF
    # @!attribute [r] type
    #   @return [DocumentType] The type of the document
    # @!attribute [r] file
    #   @return [File] The file object
    # @!attribute [r] date_captures
    #   @return [Hash] The captured date components from regex
    attr_reader :text, :type, :file, :date_captures

    # @param file [String] Path to the PDF file
    # @param type [DocumentType] Type of the document
    # @param text [String] Extracted text from the PDF
    # @param date_captures [Hash] Captured date components from regex
    # @return [self] A new Document instance
    def initialize(file, type, text, date_captures)
      @file = File.new(file)
      @type = type
      @text = text
      @date_captures = date_captures
    end

    # @return [String] File name without extension
    def file_name_only
      File.basename(@file, file_extension)
    end

    # @return [String] File extension including the dot (e.g., ".pdf")
    def file_extension
      File.extname(@file)
    end

    # @return [String] Complete file name
    def file_name
      File.basename(@file)
    end

    # @return [String] Backup file name with .bkp extension
    def backup_name
      "#{file_name}.bkp"
    end

    # @return [String] Document type name or "N/A" if type is nil
    def type_name
      type&.name || "N/A"
    end

    # @return [Integer] Normalized month number (1-12)
    def month
      @month ||= Month.normalize_to_i(@date_captures["m"])
    end

    # Q1: Jan-Mar, Q2: Apr-Jun, Q3: Jul-Sep, Q4: Oct-Dec
    # @return [Integer] Quarter (1-4) based on the month
    def quarter
      @quarter ||= ((month - 1) / 3) + 1
    end

    # B1: Jan-Feb, B2: Mar-Apr, B3: May-Jun, B4: Jul-Aug, B5: Sep-Oct, B6: Nov-Dec
    # @return [Integer] Bimester (1-6) based on the month
    def bimester
      @bimester ||= ((month - 1) / 2) + 1
    end

    # @return [Integer] Full year (e.g., 2024)
    def year
      return @year if @year

      raw_year = @date_captures["y"]
      @year = (raw_year.size == 2 ? "20#{raw_year}" : raw_year).to_i
    end

    # @return [String, nil] Day of month if captured, nil otherwise
    def day
      @date_captures["d"]
    end

    # @return [String] Period in format "YYYY-MM"
    def period
      "#{year}-#{month.to_s.rjust(2, "0")}"
    end

    # Used to replace variables in the rename pattern i.e {original}, {period}, etc.
    # @return [Hash{Symbol=>String}] Hash containing rename variables
    def rename_data
      {
        original: file_name_only,
        period: period,
        year: year.to_s,
        month: month.to_s,
        quarter: "Q#{quarter}",
        bimester: "B#{bimester}",
        name: type_name,
        day: day || ""
      }.freeze
    end

    # @return [String] New file name with extension
    def new_name
      new_name = type.name_validator.gsub(rename_data)
      "#{new_name}#{file_extension}"
    end

    # @return [String] Storage path for the document
    def store_path
      type.path_validator.gsub(rename_data)
    end

    # @return [String] Directory path containing the file
    def home_dir
      File.dirname(@file)
    end

    # @return [String] File name
    def to_s
      file_name
    end
  end
end
