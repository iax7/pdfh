# frozen_string_literal: true

require 'yaml'
require 'ostruct'
require 'base64'

module Pdfh
  ##
  # Handles the config yaml data mapping, and associates a file name with a doc type
  class Settings
    attr_accessor :scrape_dirs, :base_path, :document_types

    def initialize(file)
      file_hash = YAML.load_file(file)
      Verbose.print "Loaded configuration file: #{file}"

      self.scrape_dirs = file_hash['scrape_dirs'].map do |d|
        File.expand_path(d)
      end
      self.base_path = File.expand_path(file_hash['base_path'])
      self.document_types = process_doc_types(file_hash['document_types'])

      Verbose.print 'Processing directories:'
      scrape_dirs.each { |d| Verbose.print "  - #{d}" }
      Verbose.print
    end

    ##
    # @param [String] file_name
    # @return [OpenStruct]
    def match_doc_type(file_name)
      document_types.each do |type|
        match = type.re_file.match(file_name)
        return type if match
      end
      nil
    end

    private

    def process_doc_types(doc_types)
      doc_types.map do |x|
        object = OpenStruct.new(x)
        object.re_file = Regexp.new(object.re_file)
        object.re_date = Regexp.new(object.re_date)
        object.pwd = object.pwd ? Base64.decode64(object.pwd) : nil
        object
      end
    end
  end
end
