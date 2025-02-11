# frozen_string_literal: true

module Pdfh
  # All console output formats
  class Console
    # @return [self]
    def initialize(verbose)
      @verbose = verbose
    end

    # @return [void]
    def debug(message = nil)
      msg = message.to_s
      msg = msg.colorize(:cyan) unless msg.colorized?
      output(msg) if verbose?
    end

    # @return [void]
    def info(message)
      output(message)
    end

    # Prints visual separator in shell for easier reading for humans
    # @example output
    # ——— Title ——————————————— ... ——————
    # @param title [String]
    # @return [void]
    def headline(title)
      _, cols = console_size
      line_length = cols - (title.size + 5)
      left  = ("—" * 3).to_s.red
      right = ("—" * line_length).to_s.red
      output "\n#{left} #{title.colorize(color: :blue, mode: :bold)} #{right}"
    end

    # @param message [String]
    # @param exit_app [Boolean] exit application if true (default)
    # @return [void]
    def error_print(message, exit_app: true)
      output "Error, #{message}".colorize(:red)
      exit 1 if exit_app
    end

    # @param e [StandardError]
    # @return [void]
    def backtrace_print(e)
      e.backtrace&.each do |line|
        output "  ↳ #{line.sub("#{Dir.pwd}/", "")}".colorize(:light_black)
      end
    end

    # @param message [String]
    # @return [void]
    def warn_print(message)
      output "Warning, #{message}".colorize(:yellow)
    end

    # @example usage
    #   ident_print("Name", "iax")
    #   # =>     Name: "iax"
    # @return [void]
    def ident_print(field, value, color: :green, width: 3)
      field_str = field.to_s.rjust(width)
      value_str = value.colorize(color)
      output "#{" " * 4}#{field_str}: #{value_str}"
    end

    # Show options used to run the current sync job
    # @param options [Hash]
    # @return [void]
    def print_options(options) # rubocop:disable Metrics/CyclomaticComplexity
      max_size = options.keys.map(&:size).max + 3
      options.each do |key, value|
        left  = key.inspect.rjust(max_size).cyan
        right = case value
                when NilClass   then value.inspect.colorize(color: :black, mode: :bold)
                when TrueClass  then value.inspect.colorize(color: :green, mode: :bold)
                when FalseClass then value.inspect.colorize(color: :red, mode: :bold)
                when Symbol     then value.inspect.yellow
                when String     then value.inspect.light_magenta
                else
                  value.inspect.red
                end
        debug "#{left} => #{right}"
      end

      nil
    end

    private

    # @return [boolean]
    def verbose?
      @verbose
    end

    # @return [void]
    def output(msg)
      puts(msg)
    end

    # Returns rows, cols
    # TODO: review https://gist.github.com/nixpulvis/6025433
    # @return [Array<Integer, Integer>]
    def console_size
      `stty size`.split.map(&:to_i)
    end
  end
end
