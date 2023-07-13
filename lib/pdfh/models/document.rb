# frozen_string_literal: true

module Pdfh
  # Handles the PDF detected by the rules
  class Document
    IDENT = 12

    attr_reader :text, :type, :file, :extra, :period

    # @param file [String]
    # @param type [DocumentType]
    # @param text [String]
    # @return [self]
    def initialize(file, type, text)
      @file = file
      @type = type
      Pdfh.debug "=== Document Type: #{type.name} =============================="
      @text = text
      Pdfh.debug "~~~~~~~~~~~~~~~~~~ Finding a subtype"
      @sub_type = type.sub_type(@text)
      Pdfh.debug "  SubType: #{@sub_type}"
      @companion = search_companion_files

      month, year, @extra = match_data
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
      print_info_line "Print CMD", print_cmd
      print_info_line "Processed?", "No (in Dry mode)" if Pdfh.dry?
    end

    # @return [void]
    def print_info_line(property, info)
      Pdfh.ident_print property, info.to_s, color: :light_blue, width: IDENT
    end

    # @return [String]
    def file_name_only
      File.basename(@file, File.extname(@file))
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
      @type&.name&.titleize || "N/A"
    end

    # @return [String]
    def sub_type
      @sub_type&.name&.titleize || "N/A"
    end

    # @return [String]
    def new_name
      template = @type.name_template
      new_name = template
                 .sub("{original}", file_name_only)
                 .sub("{period}", period.to_s)
                 .sub("{year}", period.year.to_s)
                 .sub("{month}", period.month.to_s)
                 .sub("{type}", type_name)
                 .sub("{subtype}", sub_type)
                 .sub("{extra}", extra || "")
      "#{new_name}.pdf"
    end

    # @return [String]
    def store_path
      @type.store_path.gsub("{YEAR}", period.year.to_s)
    end

    # @return [String]
    def print_cmd
      return "N/A" if type.print_cmd.nil? || type.print_cmd.empty?

      relative_path = File.join(store_path, new_name)
      "#{type.print_cmd} #{relative_path}"
    end

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
    def match_data
      Pdfh.debug "~~~~~~~~~~~~~~~~~~ Match Data RegEx"
      Pdfh.debug "  Using regex: #{@type.re_date}"
      Pdfh.debug "        named:   #{@type.re_date.named_captures}"
      matched = @type.re_date.match(@text)
      raise ReDateError unless matched

      Pdfh.debug "     captured: #{matched.captures}"

      return matched.captures.map(&:downcase) if @type.re_date.named_captures.empty?

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
