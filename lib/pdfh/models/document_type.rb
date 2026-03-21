# frozen_string_literal: true

module Pdfh
  # Represents a type of document that can be processed by pdfh
  class DocumentType
    REQUIRED_KEYS = %i[name re_date store_path].freeze
    DEFAULT_NAME_TEMPLATE = "{name} {period}"

    # @!attribute [r] name
    #   @return [String] The name of the document type
    # @!attribute [r] re_id
    #   @return [Regexp] The regular expression to extract the document ID
    # @!attribute [r] re_date
    #   @return [Regexp] The regular expression to extract dates
    # @!attribute [r] store_path
    #   @return [String] The path where the document will be stored
    # @!attribute [r] name_template
    #   @return [String] The template for generating document names
    # @!attribute [r] path_validator
    #   @return [RenameValidator] The validator for the storage path
    # @!attribute [r] name_validator
    #   @return [RenameValidator] The validator for the document name
    attr_reader :name, :re_id, :re_date, :store_path, :name_template, :path_validator, :name_validator

    # @param args [Hash] The initialization arguments
    # @return [DocumentType]
    def initialize(args)
      args.each { |k, v| instance_variable_set(:"@#{k}", v) }
      return if missing_keys?

      @name = name.to_s.strip
      @re_id = Regexp.new(re_id || name)
      @re_date = Regexp.new(re_date)
      @name_template = name_template || DEFAULT_NAME_TEMPLATE
      @path_validator = RenameValidator.new(store_path)
      @name_validator = RenameValidator.new(@name_template)
    end

    # @return [Boolean]
    def valid?
      missing_keys.empty? &&
        @path_validator.valid? &&
        @name_validator.valid?
    end

    # @return [Hash{String => Object}]
    def to_h
      instance_variables.to_h { |var| [var.to_s.delete_prefix("@"), instance_variable_get(var)] }
    end

    # removes special characters from string and replaces spaces with dashes
    # @example
    #   "Test This?%&".gid # => "test-this"
    # @return [String]
    def gid
      name.downcase.gsub(/[^0-9A-Za-z\s]/, "").tr(" ", "-")
    end

    # @return [Array<Symbol>]
    def missing_keys
      @missing_keys ||= REQUIRED_KEYS.select { |key| instance_variable_get(:"@#{key}").to_s.strip.empty? }
    end

    # @return [Boolean]
    def missing_keys? = missing_keys.any?
  end
end
