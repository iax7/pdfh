# frozen_string_literal: true

require "base64"

module Pdfh
  DocumentSubType = Struct.new(:name, :month_offset, keyword_init: true)

  DocumentType = Struct.new(:name, :re_file, :re_date, :pwd, :store_path, :name_template, :sub_types, :print_cmd,
                            keyword_init: true) do
    # @return [self]
    def initialize(args)
      super
      self.name_template ||= "{original}"
      self.re_file = Regexp.new(re_file)
      self.re_date = Regexp.new(re_date)
      self.pwd = Base64.decode64(pwd) if pwd
      self.sub_types = extract_subtype(sub_types) if sub_types
    end

    # @return [String]
    def gid
      name.downcase.gsub(/[^0-9A-Za-z\s]/, "").tr(" ", "-")
    end

    # @return [DocumentSubType]
    def sub_type(text)
      # Regexp.new(st.name).match?(name)
      sub_types&.find { |st| /#{st.name}/i.match?(text) }
    end

    private

    # @param sub_types [Array]
    # @return [DocumentSubType]
    def extract_subtype(sub_types)
      sub_types.map do |st|
        name = st["name"]
        offset = st["month_offset"].to_i
        DocumentSubType.new(name: name, month_offset: offset)
      end
    end
  end
end
