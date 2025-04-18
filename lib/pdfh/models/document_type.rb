# frozen_string_literal: true

module Pdfh
  # Represents a type of document that can be processed by pdfh
  class DocumentType
    include Concerns::PasswordDecodable

    # @!attribute [r] name
    #   @return [String] The name of the document type.
    # @!attribute [r] re_file
    #   @return [Regexp] The regular expression to match file names.
    # @!attribute [r] re_date
    #   @return [Regexp] The regular expression to extract dates and its information.
    # @!attribute [r] pwd
    #   @return [String, nil] The base64 password for the document type, if any.
    # @!attribute [r] store_path
    #   @return [String] The path where the document will be stored.
    # @!attribute [r] name_template
    #   @return [String] The template for generating document names.
    # @!attribute [r] sub_types
    #   @return [Array<DocumentSubType>, nil] The subtypes of the document, if any.
    attr_reader :name, :re_file, :re_date, :pwd, :store_path, :name_template, :sub_types

    # @param args [Hash]
    # @return [self]
    def initialize(args)
      args.each { |k, v| instance_variable_set(:"@#{k}", v) }
      @name_template ||= "{original}"
      @re_file = Regexp.new(re_file)
      @re_date = Regexp.new(re_date)
      @sub_types = extract_subtypes(sub_types) if sub_types&.any?
      @path_validator = RenameValidator.new(store_path)
      @name_validator = RenameValidator.new(name_template)
      return if @path_validator.valid? && @name_validator.valid?

      raise_validators_error
    end

    # @return [Hash{Symbol->any}]
    def to_h
      instance_variables.to_h { |var| [var.to_s.delete_prefix("@"), instance_variable_get(var)] }
    end

    # removes special characters from string and replaces spaces with dashes
    # @example usage
    #   "Test This?%&".gid
    #   # => "test-this"
    # @return [String]
    def gid
      name.downcase.gsub(/[^0-9A-Za-z\s]/, "").tr(" ", "-")
    end

    # search the subtype name in the pdf document
    # @return [DocumentSubType]
    def sub_type(text)
      # Regexp.new(st.name).match?(name)
      sub_types&.find { |st| /#{st.name}/i.match?(text) }
    end

    # @param values [Hash{Symbol->String}
    # @return [String]
    def generate_new_name(values)
      @name_validator.gsub(values)
    end

    # @param values [Hash{Symbol->String}
    # @return [String]
    def generate_path(values)
      @path_validator.gsub(values)
    end

    private

    attr_accessor :path_validator, :name_validator

    # @param sub_types [Array<Hash{Symbol->String}>]
    # @return [Array<DocumentSubType>]
    def extract_subtypes(sub_types)
      sub_types.map do |st|
        data = {
          name: st[:name],
          month_offset: st[:month_offset].to_i,
          re_date: st[:re_date] && Regexp.new(st[:re_date])
        }.compact
        DocumentSubType.new(data)
      end
    end

    # @raise [ArgumentError] when called
    # @return [void]
    def raise_validators_error
      template = "has invalid %<field>s[Unknown tokens=%<error>s]"
      errors = []
      errors << format(template, field: :store_path, error: path_validator.unknown_list) unless path_validator.valid?
      errors << format(template, field: :name_template, error: name_validator.unknown_list) unless name_validator.valid?
      raise ArgumentError, "Document type #{name.inspect} #{errors.join(", ")}"
    end
  end
end
