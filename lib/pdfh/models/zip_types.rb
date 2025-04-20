# frozen_string_literal: true

module Pdfh
  # Zip files which contains PDF files that need pre-processing
  class ZipType
    include Concerns::PasswordDecodable

    attr_reader :name, :re_file, :pwd

    # @param args [Hash]
    # @return [self]
    def initialize(args)
      args.each { |k, v| instance_variable_set(:"@#{k}", v) }
      @re_file = Regexp.new(re_file)
    end
  end
end
