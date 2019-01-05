# frozen_string_literal: true

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

      Verbose.print "=== Type: #{type.name} =================="
      @text = pdf_text
      Verbose.print "Text extracted: #{@text}"
      @month, @year, @extra = match_data
      Verbose.print "==== Assigned: #{@month}, #{@year}, #{@extra} ==( Month, Year, Extra )================"
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

    def sub_type
      type.subtype ? type.subtype.name : 'N/A'
    end

    def new_name
      template = @type.to_h.key?(:name_template) ? @type.name_template : '{original}'
      new_name = template
                 .gsub(/\{original\}/, file_name_only)
                 .gsub(/\{period\}/, period)
                 .gsub(/\{subtype\}/, sub_type)
                 .gsub(/\{extra\}/, extra || '')
      "#{new_name}.pdf"
    end

    def store_path
      @type.store_path.gsub(/\{YEAR\}/, year.to_s)
    end

    def to_s
      <<~STR
        Name     : #{file_name_only}
        Sub Type : #{sub_type}
        Period   : #{period}
        File Path: #{file}
        File Name: #{file_name}
        New Name : #{new_name}
        StorePath: #{store_path}
      STR
    end

    def companion_files(join: false)
      files = find_companion_files

      files unless join

      files.empty? ? 'N/A' : files.join(', ')
    end

    def write_pdf(base_path)
      full_path = File.join(base_path, store_path, new_name)
      dir_path = File.join(base_path, store_path)

      raise IOError unless Dir.exist?(dir_path)

      password_opt = "--password='#{@type.pwd}'" if @type.pwd
      cmd = %(qpdf #{password_opt} --decrypt '#{@file}' '#{full_path}')
      Verbose.print "  Write pdf command: #{cmd}"

      return if Dry.active?

      _result = `#{cmd}`
      raise IOError unless File.file?(full_path)

      # Making backup of original
      bkp_name = "#{file_name}.bkp"
      File.rename(file, bkp_name)

      copy_companion_files(dir_path)
    end

    private

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

        companion || []
      end
    end

    def copy_companion_files(destination)
      find_companion_files.each do |file|
        Verbose.print "  cp #{file} --> #{destination}"
        FileUtils.cp(file, destination)
      end
    end
  end
end
