# frozen_string_literal: true

module Pdfh
  # Handles the PDF detected by the rules
  class Document
    attr_reader :text, :type, :file, :extra, :period

    # @param file [String]
    # @param type [DocumentType]
    # @param text [String]
    # @return [self]
    def initialize(file, type, text)
      @file = file
      @type = type
      @text = text
    end

    # @return [void]
    def process
      Pdfh.debug "=== Document Type: #{type.name} =============================="
      Pdfh.debug "~~~~~~~~~~~~~~~~~~ Finding a subtype"
      @sub_type = type.sub_type(@text)
      Pdfh.debug "  SubType: #{@sub_type}"
      @companion = search_companion_files

      month, year, @extra = match_date(@sub_type&.re_date || @type.re_date)
      @period = DocumentPeriod.new(day: extra, month: month, month_offset: @sub_type&.month_offset, year: year)
      Pdfh.debug "  Period: #{@period.inspect}"
    end

    # @return [void]
    def print_info
      print_info_line "Type", type.name
      print_info_line "Sub-Type", sub_type
      print_info_line "Period", period
      print_info_line "New Name", new_name
      print_info_line "Store Path", store_path
      print_info_line "Extra files", companion_files(join: true)
      print_info_line "Processed?", "No (in Dry mode)" if Pdfh.dry?
    end

    # @return [void]
    def print_info_line(property, info)
      Pdfh.ident_print property, info.to_s, color: :light_blue, width: 12
    end

    # @return [String]
    def file_name_only
      File.basename(@file, file_extension)
    end

    # @return [String]
    def file_extension
      File.extname(@file)
    end

    # @return [String]
    def file_name
      File.basename(@file)
    end

    # @return [String]
    def backup_name
      "#{file_name}.bkp"
    end

    # @return [String]
    def type_name
      type&.name&.titleize || "N/A"
    end

    # @return [String]
    def sub_type
      @sub_type&.name&.titleize || "N/A"
    end

    # @return [Hash{Symbol->String}]
    def rename_data
      {
        original: file_name_only,
        period: period.to_s,
        year: period.year.to_s,
        month: period.month.to_s,
        type: type_name,
        subtype: sub_type,
        extra: extra || ""
      }.freeze
    end

    # @return [String]
    def new_name
      new_name = type.generate_new_name(rename_data)
      "#{new_name}#{file_extension}"
    end

    # @return [String]
    def store_path
      type.generate_path(rename_data)
    end

    # @return [String (frozen)]
    def companion_files(join: false)
      return @companion unless join

      @companion.empty? ? "N/A" : @companion.join(", ")
    end

    # @return [String]
    def home_dir
      File.dirname(@file)
    end

    # @return [String]
    def to_s
      @file
    end

    private

    # named matches can appear in any order with names 'd', 'm' and 'y'
    # unnamed matches needs to be in order month, year
    # @return [Array] - format [month, year, day]
    # @param regex [RegularExpression]
    def match_date(regex)
      Pdfh.debug "~~~~~~~~~~~~~~~~~~ Match Data RegEx"
      Pdfh.debug "  Using regex: #{regex}"
      Pdfh.debug "        named:   #{regex.named_captures}"
      matched = regex.match(@text)
      raise ReDateError unless matched

      Pdfh.debug "     captured: #{matched.captures}"

      return matched.captures.map(&:downcase) if regex.named_captures.empty?

      extra = matched.captures.size > 2 ? matched[:d] : nil
      [matched[:m].downcase, matched[:y], extra]
    end

    # @return [Array]
    def search_companion_files
      Pdfh.debug "~~~~~~~~~~~~~~~~~~ Searching Companion files"
      Pdfh.debug "  Searching on: #{home_dir.inspect}"
      Dir.chdir(home_dir) do
        files_matching = Dir["#{file_name_only}.*"]
        companion = files_matching.reject { |file| file.include? ".pdf" }
        Pdfh.debug "    Found: #{companion.inspect}"

        companion
      end
    end
  end
end
