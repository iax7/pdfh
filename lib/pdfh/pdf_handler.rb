# frozen_string_literal: true

module Pdfh
  # Handles the Pdf document text extraction and password removal
  # TODO: Replace command utils with this gem
  #  require 'pdf-reader'
  #
  #  reader = PDF::Reader.new(temp)
  #  reader.pages.each do |page|
  #      @text << page.text
  #  end
  class PdfHandler
    attr_reader :file

    # @return [self]
    def initialize(file, password)
      @file = file
      @password_option = password ? "--password=#{password.inspect} " : ""
    end

    ##
    # Gets the text from the pdf in order to execute
    # the regular expresion matches
    # @return [String]
    def extract_text
      temp = `mktemp`.chomp
      Pdfh.verbose_print "~~~~~~~~~~~~~~~~~~ Extract PDF text"
      Pdfh.verbose_print "  --> #{temp.inspect} temporal file assigned."

      cmd = %(qpdf #{@password_option}--decrypt --stream-data=uncompress #{@file.inspect} #{temp.inspect})
      Pdfh.verbose_print "  DeCrypt Command: #{cmd}"
      _result = `#{cmd}`

      cmd2 = %(pdftotext -enc UTF-8 #{temp.inspect} -)
      Pdfh.verbose_print "  Extract Command: #{cmd2}"
      text = `#{cmd2}`
      Pdfh.verbose_print "  Text: #{text.inspect}"
      text
    end

    # @return [void]
    def write_new_pdf(dir_path, full_path)
      Pdfh.verbose_print "~~~~~~~~~~~~~~~~~~ Writing PDFs"
      raise IOError, "Path #{dir_path} not found." unless Dir.exist?(dir_path)

      cmd = %(qpdf #{@password_option}--decrypt #{@file.inspect} #{full_path.inspect})
      Pdfh.verbose_print "  Write PDF Command: #{cmd}"

      return if Pdfh.dry?

      _result = `#{cmd}`
      raise IOError, "New PDF file #{full_path.inspect} was not created." unless File.file?(full_path)
    end
  end
end
