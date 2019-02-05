# frozen_string_literal: true

module Pdfh
  ##
  # Handles the Pdf document text extraction and password removal
  # TODO: Replace command utils with this gem
  #  require 'pdf-reader'
  #
  #  reader = PDF::Reader.new(temp)
  #  reader.pages.each do |page|
  #      @text << page.text
  #  end
  class PdfHandler
    attr_reader :file, :password

    def initialize(file, password)
      @file = file
      @password = password
    end

    ##
    # Gets the text from the pdf in order to execute
    # the regular expresiom matches
    def extract_text
      temp = `mktemp`.chomp
      Verbose.print "  --> #{temp} temporal file assigned."

      password_opt = "--password='#{@password}'" if @password
      cmd = %(qpdf #{password_opt} --decrypt --stream-data=uncompress '#{@file}' '#{temp}')
      Verbose.print "  Command: #{cmd}"
      _result = `#{cmd}`

      cmd2 = %(pdftotext -enc UTF-8 '#{temp}' -)
      Verbose.print "  Command: #{cmd2}"
      text = `#{cmd2}`
      Verbose.print "  Text extracted: #{text}"
      text
    end

    def write_pdf(dir_path, full_path)
      Verbose.print '~~~~~~~~~~~~~~~~~~ Writing PDFs'
      raise IOError, "Path #{dir_path} not found." unless Dir.exist?(dir_path)

      password_opt = "--password='#{@password}'" if @password
      cmd = %(qpdf #{password_opt} --decrypt '#{@file}' '#{full_path}')
      Verbose.print "  Write pdf command: #{cmd}"

      return if Dry.active?

      _result = `#{cmd}`
      raise IOError, "File #{full_path} was not created." unless File.file?(full_path)
    end
  end
end
