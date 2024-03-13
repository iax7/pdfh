# frozen_string_literal: true

module Pdfh
  # Represents a type of document that can be processed by pdfh
  DocumentType = Struct.new(:name, :re_file, :re_date, :pwd, :store_path, :name_template, :sub_types, :print_cmd,
                            keyword_init: true) do
    # @return [self]
    def initialize(args)
      super
      self.name_template ||= "{original}"
      self.re_file = Regexp.new(re_file)
      self.re_date = Regexp.new(re_date)
      self.sub_types = extract_subtype(sub_types) if sub_types
      @rename_validator = RenameValidator.new(name_template)
      raise "Invalid name template, unknown: #{@rename_validator.unknown.join(", ")}" unless @rename_validator.valid?
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
      @rename_validator.name(values)
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
  end
end
