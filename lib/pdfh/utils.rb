# frozen_string_literal: true

require 'colorize'

# Contains all generic short functionality
module Pdfh
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

  def self.print_error(exception, exit_app: true)
    line = exception.backtrace[0].match(/:(?<line>\d+)/)[:line]
    puts "Error, Line[#{line}]: #{exception.message}.".colorize(:red)
    exit 1 if exit_app
  end
end
