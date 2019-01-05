# frozen_string_literal: true

require 'colorize'

module Pdfh
  class Error < StandardError; end

  ##
  # Keeps Verbose option in whole project
  class Verbose
    @active = false
    class << self
      attr_writer :active

      def active?
        @active
      end

      def print(msg = '')
        puts msg.colorize(:cyan) if active?
      end
    end
  end

  ##
  # Keeps Dry run option in whole project
  class Dry
    @active = false
    class << self
      attr_writer :active

      def active?
        @active
      end
    end
  end
end
