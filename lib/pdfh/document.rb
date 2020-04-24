# frozen_string_literal: true

require 'fileutils'
require 'pdfh/month'
require 'pdfh/pdf_handler'
require 'ext/string'

##
# main module
module Pdfh
  using Extensions

  ##
  # Regular Date Error, when there is not match
  class ReDateError < StandardError
    def initialize(message = 'No data matched your date regular expression')
      super(message)
    end
  end

  ##
  # Handles the PDF detected by the rules
  class Document
    attr_reader :text, :type, :file, :extra

    def initialize(file, type, _options = {})
      raise IOError, "File #{file} not found" unless File.exist?(file)

      @file = file
      @type = type
      @month_offset = 0
      @year_offset = 0

      @pdf_doc = PdfHandler.new(file, @type.pwd)

      Verbose.print "=== Type: #{type_name} =================="
      @text = @pdf_doc.extract_text
      @sub_type = extract_subtype(@type.sub_types)
      Verbose.print "  SubType: #{@sub_type}"
      @month, @year, @extra = match_data
      Verbose.print "==== Assigned: #{@month}, #{@year}, #{@extra} ==( Month, Year, Extra )================"
      find_companion_files
    end

    def write_pdf(base_path)
      full_path = File.join(base_path, store_path, new_name)
      dir_path = File.join(base_path, store_path)

      FileUtils.mkdir_p(dir_path) unless File.exist?(dir_path)

      @pdf_doc.write_pdf(dir_path, full_path)

      return if Dry.active?

      make_document_backup
      copy_companion_files(dir_path)
    end

    def period
      formated_month = month.to_s.rjust(2, '0')
      "#{year}-#{formated_month}"
    end

    def month
      month = Month.normalize(@month) + @month_offset

      case month
      when 0
        @year_offset = -1
        12
      when 13
        @year_offset = 1
        1
      else month
      end
    end

    def year
      tmp = @year.size == 2 ? "20#{@year}" : @year
      tmp.to_i + @year_offset
    end

    def file_name_only
      File.basename(@file, File.extname(@file))
    end

    def file_name
      File.basename(@file)
    end

    def backup_name
      "#{file_name}.bkp"
    end

    def type_name
      @type ? @type.name.titleize : 'N/A'
    end

    def sub_type
      @sub_type ? @sub_type.name.titleize : 'N/A'
    end

    def new_name
      template = @type.to_h.key?(:name_template) ? @type.name_template : '{original}'
      new_name = template
                 .sub('{original}', file_name_only)
                 .sub('{period}', period)
                 .sub('{type}', type_name)
                 .sub('{subtype}', sub_type)
                 .sub('{extra}', extra || '')
      "#{new_name}.pdf"
    end

    def store_path
      @type.store_path.gsub(/\{YEAR\}/, year.to_s)
    end

    def print_cmd
      return 'N/A' if type.print_cmd.nil? || type.print_cmd.empty?

      relative_path = File.join(store_path, new_name)
      "#{type.print_cmd} #{relative_path}"
    end

    def to_s
      <<~STR
        Name:      #{file_name_only}
        Type:      #{type_name}
        Sub Type:  #{sub_type}
        Period:    #{period}
        File Path: #{file}
        File Name: #{file_name}
        New Name:  #{new_name}
        StorePath: #{store_path}
        Companion: #{companion_files(join: true)}
        Print Cmd: #{print_cmd}
      STR
    end

    def companion_files(join: false)
      @companion unless join

      @companion.empty? ? 'N/A' : @companion.join(', ')
    end

    private

    ##
    # @param [Array] subtypes
    # @return [OpenStruct]
    def extract_subtype(sub_types)
      return nil if sub_types.nil? || sub_types.empty?

      sub_types.each do |st|
        is_matched = Regexp.new(st['name']).match?(@text)
        next unless is_matched

        sub = OpenStruct.new(st)
        @month_offset = sub.month_offset || 0
        return sub
      end
      nil
    end

    def home_dir
      File.dirname(@file)
    end

    ##
    # named matches can appear in any order with names 'd', 'm' and 'y'
    # unamed matches needs to be in order month, year
    # @return [Array] - format [month, year, day]
    def match_data
      Verbose.print '~~~~~~~~~~~~~~~~~~ RegEx'
      Verbose.print "  Using regex: #{@type.re_date}"
      Verbose.print "        named:   #{@type.re_date.named_captures}"
      matched = @type.re_date.match(@text)
      raise ReDateError unless matched

      Verbose.print "     captured: #{matched.captures}"

      return matched.captures.map(&:downcase) if @type.re_date.named_captures.empty?

      extra = matched.captures.size > 2 ? matched[:d] : nil
      [matched[:m].downcase, matched[:y], extra]
    end

    ##
    # Create a backup of original document
    def make_document_backup
      Dir.chdir(home_dir) do
        File.rename(file, backup_name)
      end
    end

    def find_companion_files
      Verbose.print '~~~~~~~~~~~~~~~~~~ Searching Companion files'
      Verbose.print "   Working on dir: #{home_dir}"
      Dir.chdir(home_dir) do
        all_files = Dir["#{file_name_only}.*"]
        companion = all_files.reject { |file| file.include? 'pdf' }
        Verbose.print "     - #{companion.join(', ')}"

        @companion = companion || []
      end
    end

    def copy_companion_files(destination)
      Verbose.print '~~~~~~~~~~~~~~~~~~ Writing Companion files'
      @companion.each do |file|
        Verbose.print "  Working on #{file}..."
        src_name = File.join(home_dir, file)
        src_ext = File.extname(file)
        dest_name = File.basename(new_name, '.pdf')
        dest_full = File.join(destination, "#{dest_name}#{src_ext}")
        Verbose.print "    cp #{src_name} --> #{dest_full}"
        FileUtils.cp(src_name, dest_full)
      end
    end
  end
end
