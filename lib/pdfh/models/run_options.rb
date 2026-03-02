# frozen_string_literal: true

module Pdfh
  # Runtime options for the application
  class RunOptions
    # @param verbose [Boolean]
    # @param dry [Boolean]
    # @return [RunOptions]
    def initialize(verbose: false, dry: false)
      @verbose = verbose
      @dry = dry
    end

    # @return [Boolean]
    def verbose? = @verbose

    # @return [Boolean]
    def dry? = @dry
  end
end
