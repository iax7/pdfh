# frozen_string_literal: true

require 'fileutils'

module Pdfh
  ##
  # Handles the PDF detected by the rules
  # TODO: Replace command utils with this gem
  #  require 'pdf-reader'
  #
  #  reader = PDF::Reader.new(temp)
  #  reader.pages.each do |page|
  #      @text << page.text
  #  end
  class Document
    attr_accessor :text, :type, :file, :extra

    MONTHS = {
      enero: 1,
      febrero: 2,
      marzo: 3,
      abril: 4,
      mayo: 5,
      junio: 6,
      julio: 7,
      agosto: 8,
      septiembre: 9,
      octubre: 10,
      noviembre: 11,
      diciembre: 12
    }.freeze

    def initialize(file, type, _options = {})
      @file = file
      @type = type
      @month_offset = 0
      @year_offset = 0

      raise IOError, "File #{file} not found" unless File.exist?(file)

      Verbose.print "=== Type: #{type_name} =================="
      @text = pdf_text
      Verbose.print "  Text extracted: #{@text}"
      @sub_type = extract_subtype(@type.sub_types)
      Verbose.print "  SubType: #{@sub_type}"
      @month, @year, @extra = match_data
      Verbose.print "==== Assigned: #{@month}, #{@year}, #{@extra} ==( Month, Year, Extra )================"
      @companion = find_companion_files
    end

    def period
      m = month.to_s.rjust(2, '0')
      y = year
      "#{y}-#{m}"
    end

    def month
      m = normalize_month + @month_offset

      case m
      when 0 then
        @year_offset = -1
        12
      when 13 then
        @year_offset = 1
        1
      else m
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
      @type ? @type.name : 'N/A'
    end

    def sub_type
      @sub_type ? @sub_type.name : 'N/A'
    end

    def new_name
      template = @type.to_h.key?(:name_template) ? @type.name_template : '{original}'
      new_name = template
                 .gsub(/\{original\}/, file_name_only)
                 .gsub(/\{period\}/, period)
                 .gsub(/\{type\}/, type_name)
                 .gsub(/\{subtype\}/, sub_type)
                 .gsub(/\{extra\}/, extra || '')
      "#{new_name}.pdf"
    end

    def store_path
      @type.store_path.gsub(/\{YEAR\}/, year.to_s)
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
      STR
    end

    def companion_files(join: false)
      @companion unless join

      @companion.empty? ? 'N/A' : @companion.join(', ')
    end

    def write_pdf(base_path)
      Verbose.print '~~~~~~~~~~~~~~~~~~ Writing PDFs'
      full_path = File.join(base_path, store_path, new_name)
      dir_path = File.join(base_path, store_path)

      raise IOError, "Path #{dir_path} was not found." unless Dir.exist?(dir_path)

      password_opt = "--password='#{@type.pwd}'" if @type.pwd
      cmd = %(qpdf #{password_opt} --decrypt '#{@file}' '#{full_path}')
      Verbose.print "  Write pdf command: #{cmd}"

      return if Dry.active?

      _result = `#{cmd}`
      raise IOError, "File #{full_path} was not created." unless File.file?(full_path)

      # Making backup of original
      Dir.chdir(home_dir) do
        File.rename(file, backup_name)
      end

      copy_companion_files(dir_path)
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

    def normalize_month
      month_num = @month.to_i
      return month_num if month_num.positive?

      if @month.size == 3
        MONTHS.keys.each do |mon|
          return MONTHS[mon] if mon.to_s[0, 3] == @month
        end
      end

      MONTHS[@month.to_sym]
    end

    def home_dir
      File.dirname(@file)
    end

    def pdf_text
      temp = `mktemp`.chomp
      Verbose.print "  --> #{temp} temporal file assigned."

      password_opt = "--password='#{@type.pwd}'" if @type.pwd
      cmd = %(qpdf #{password_opt} --decrypt --stream-data=uncompress '#{@file}' '#{temp}')
      Verbose.print "  Command: #{cmd}"
      _result = `#{cmd}`
      Verbose.print 'Password removed.'

      cmd2 = %(pdftotext -enc UTF-8 '#{temp}' -)
      Verbose.print "  Command: #{cmd2}"
      `#{cmd2}`
    end

    def match_data
      Verbose.print '~~~~~~~~~~~~~~~~~~ RegEx'
      Verbose.print "  Using regex: #{@type.re_date}"
      Verbose.print "        named:   #{@type.re_date.named_captures}"
      matched = @type.re_date.match(@text)
      Verbose.print "     captured: #{matched.captures}"

      return matched.captures.map(&:downcase) if @type.re_date.named_captures.empty?

      extra = matched.captures.size > 2 ? matched[3] : nil
      [matched[:m].downcase, matched[:y], extra]
    end

    def find_companion_files
      Verbose.print '~~~~~~~~~~~~~~~~~~ Searching Companion files'
      Verbose.print "   Working on dir: #{home_dir}"
      Dir.chdir(home_dir) do
        all_files = Dir["#{file_name_only}.*"]
        companion = all_files.reject { |f| f.include? 'pdf' }
        Verbose.print "     - #{companion.join(', ')}"

        companion || []
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
