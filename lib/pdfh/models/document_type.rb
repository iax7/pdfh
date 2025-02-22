# frozen_string_literal: true

module Pdfh
  # Represents a type of document that can be processed by pdfh
  DocumentType = Struct.new(:name, :re_file, :re_date, :pwd, :store_path, :name_template, :sub_types,
                            keyword_init: true) do
    # @return [self]
    def initialize(args)
      super
      self.name_template ||= "{original}"
      self.re_file = Regexp.new(re_file)
      self.re_date = Regexp.new(re_date)
      self.sub_types = extract_subtypes(sub_types) if sub_types&.any?
      @path_validator = RenameValidator.new(store_path)
      @name_validator = RenameValidator.new(name_template)
      return if @path_validator.valid? && @name_validator.valid?

      raise_validators_error
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

    # @return [String]
    def password
      return Base64.decode64(pwd) if base64?

      pwd
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

    # @return [boolean]
    def base64?
      pwd.is_a?(String) && Base64.strict_encode64(Base64.decode64(pwd)) == pwd
    end

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
