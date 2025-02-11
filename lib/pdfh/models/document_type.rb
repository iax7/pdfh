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
      self.sub_types = extract_subtype(sub_types) if sub_types
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

    # @return [boolean]
    def base64?
      pwd.is_a?(String) && Base64.strict_encode64(Base64.decode64(pwd)) == pwd
    end

    # @param sub_types [Array]
    # @return [DocumentSubType]
    def extract_subtype(sub_types)
      sub_types.map do |st|
        name = st[:name]
        offset = st[:month_offset].to_i
        DocumentSubType.new(name: name, month_offset: offset)
      end
    end

    # @raise [ArgumentError] when called
    # @return [void]
    def raise_validators_error
      template = "has invalid %<1>s. Unknown tokens: %<2>s"
      path_errors = format(template, :store_path, @path_validator.unknown_list) unless @path_validator.valid?
      name_errors = format(template, :name_template, @name_validator.unknown_list) unless @name_validator.valid?
      raise ArgumentError, "Document type #{name.inspect} #{path_errors} #{name_errors}"
    end
  end
end
