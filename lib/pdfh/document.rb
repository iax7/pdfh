# frozen_string_literal: true

module Pdfh
  # Handles the PDF detected by the rules
  class Document
    attr_reader :text, :type, :file, :extra, :pdf_doc, :period

    # @param file [String]
    # @param type [DocumentType]
    # @return [self]
    def initialize(file, type)
      raise IOError, "File #{file} not found" unless File.exist?(file)

      @file = file
      @type = type
      Pdfh.verbose_print "=== Document Type: #{type.name} =============================="
      @pdf_doc = PdfHandler.new(file, type.pwd)
      @text = @pdf_doc.extract_text
      Pdfh.verbose_print "~~~~~~~~~~~~~~~~~~ Finding a subtype"
      @sub_type = type.sub_type(@text)
      Pdfh.verbose_print "  SubType: #{@sub_type}"
      @companion = search_companion_files

      month, year, @extra = match_data
      @period = DocumentPeriod.new(day: extra, month: month, month_offset: @sub_type&.month_offset, year: year)
      Pdfh.verbose_print "  Period: #{@period.inspect}"
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
      Pdfh.verbose_print "~~~~~~~~~~~~~~~~~~ Match Data RegEx"
      Pdfh.verbose_print "  Using regex: #{@type.re_date}"
      Pdfh.verbose_print "        named:   #{@type.re_date.named_captures}"
      matched = @type.re_date.match(@text)
      raise ReDateError unless matched

      Pdfh.verbose_print "     captured: #{matched.captures}"

      return matched.captures.map(&:downcase) if @type.re_date.named_captures.empty?

      extra = matched.captures.size > 2 ? matched[:d] : nil
      [matched[:m].downcase, matched[:y], extra]
    end

    # @return [Array]
    def search_companion_files
      Pdfh.verbose_print "~~~~~~~~~~~~~~~~~~ Searching Companion files"
      Pdfh.verbose_print "  Searching on: #{home_dir.inspect}"
      Dir.chdir(home_dir) do
        files_matching = Dir["#{file_name_only}.*"]
        companion = files_matching.reject { |file| file.include? ".pdf" }
        Pdfh.verbose_print "    Found: #{companion.inspect}"

        companion
      end
    end
  end
end
