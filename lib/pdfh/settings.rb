# frozen_string_literal: true

require "yaml"

module Pdfh
  # Handles the config yaml data mapping, and associates a file name with a doc type
  class Settings
    attr_reader :lookup_dirs, :base_path, :document_types

    # @param config_file [String]
    # @return [self]
    def initialize(config_file)
      file_hash = YAML.load_file(config_file)
      Pdfh.verbose_print "Loaded configuration file: #{config_file}"

      process_lookup_dirs(file_hash["lookup_dirs"])
      process_destination_base(file_hash["destination_base_path"])

      Pdfh.verbose_print "Configured Look up directories:"
      lookup_dirs.each_with_index { |dir, idx| Pdfh.verbose_print "  #{idx + 1}. #{dir}" }
      Pdfh.verbose_print

      @document_types = load_doc_types(file_hash["document_types"])
    end

    private

    # @return [void]
    def process_lookup_dirs(lookup_dirs_list)
      @lookup_dirs = lookup_dirs_list.filter_map do |dir|
        expanded = File.expand_path(dir)
        unless File.directory?(expanded)
          Pdfh.verbose_print "  ** Error, Directory #{dir} does not exists."
          next
        end
        expanded
      end
      raise ArgumentError, "No valid Look up directories configured." if lookup_dirs.empty?
    end

    # @return [void]
    def process_destination_base(dir)
      @base_path = File.expand_path(dir)
      raise ArgumentError, "Destination base directory is not configured." if @base_path.nil?
      raise ArgumentError, "Destination base directory #{@base_path} does not exist." unless File.directory?(@base_path)
    end

    # @return [Array<DocumentType>]
    def load_doc_types(doc_types)
      doc_types.map { |data| DocumentType.new(data) }
    end
  end
end
