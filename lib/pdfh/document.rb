# frozen_string_literal: true

require 'fileutils'
require 'pdfh/month'
require 'ext/string'

##
# main module
module Pdfh
  using Extensions

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
    attr_reader :text, :type, :file, :extra

    def initialize(file, type, _options = {})
      raise IOError, "File #{file} not found" unless File.exist?(file)

      @file = file
      @type = type
      @month_offset = 0
      @year_offset = 0

      Verbose.print "=== Type: #{type_name} =================="
      extract_pdf_text
      @sub_type = extract_subtype(@type.sub_types)
      Verbose.print "  SubType: #{@sub_type}"
      match_data
      find_companion_files
    end

    def period
      formated_month = month.to_s.rjust(2, '0')
      "#{year}-#{formated_month}"
    end

    def month
      month = Month.normalize(@month) + @month_offset

      case month
      when 0 then
        @year_offset = -1
        12
      when 13 then
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
      return nil if type.print_cmd.nil? || type.print_cmd.empty?

      type.print_cmd
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

      make_document_backup
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

    def home_dir
      File.dirname(@file)
    end

    ##
    # Gets the text from the pdf in order to execute
    # the regular expresiom matches
    def extract_pdf_text
      temp = `mktemp`.chomp
      Verbose.print "  --> #{temp} temporal file assigned."

      password_opt = "--password='#{@type.pwd}'" if @type.pwd
      cmd = %(qpdf #{password_opt} --decrypt --stream-data=uncompress '#{@file}' '#{temp}')
      Verbose.print "  Command: #{cmd}"
      _result = `#{cmd}`
      Verbose.print '  Password removed.'

      cmd2 = %(pdftotext -enc UTF-8 '#{temp}' -)
      Verbose.print "  Command: #{cmd2}"
      @text = `#{cmd2}`
      Verbose.print "  Text extracted: #{@text}"
    end

    def match_data
      Verbose.print '~~~~~~~~~~~~~~~~~~ RegEx'
      Verbose.print "  Using regex: #{@type.re_date}"
      Verbose.print "        named:   #{@type.re_date.named_captures}"
      matched = @type.re_date.match(@text)
      Verbose.print "     captured: #{matched.captures}"

      return matched.captures.map(&:downcase) if @type.re_date.named_captures.empty?

      extra = matched.captures.size > 2 ? matched[3] : nil
      @month = matched[:m].downcase
      @year = matched[:y]
      @extra = extra
      Verbose.print "==== Assigned: #{@month}, #{@year}, #{@extra} ==( Month, Year, Extra )================"
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
