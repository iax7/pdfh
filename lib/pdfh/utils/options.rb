# frozen_string_literal: true

module Pdfh
  # Argument Options object container
  class Options
    attr_reader :type, :files

    # @param arg_options [Hash]
    # @return [self]
    def initialize(arg_options)
      @verbose = arg_options[:verbose]
      @dry = arg_options[:dry]
      @type = arg_options[:type]
      @files = arg_options[:files] || []
      @mode = type ? :file : :directory
    end

    # @return [Boolean]
    def verbose?
      @verbose
    end

    # @return [Boolean]
    def dry?
      @dry
    end

    # @return [Boolean]
    def file_mode?
      @mode == :file
    end

    # @return [Boolean]
    def files?
      !!@files&.any?
    end
  end
end
