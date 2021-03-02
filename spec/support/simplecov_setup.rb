# frozen_string_literal: true

require "simplecov"
require "simplecov-console"

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
                                                                 SimpleCov::Formatter::Console,
                                                                 SimpleCov::Formatter::HTMLFormatter
                                                               ])

SimpleCov.start do
  add_filter "/spec/"
  add_filter "/bin/"
  add_filter "/exe/"
  add_group "Classes", "/lib/pdfh/"
end
