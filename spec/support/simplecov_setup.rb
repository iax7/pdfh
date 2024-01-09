# frozen_string_literal: true

require "simplecov"
require "simplecov-console"

SimpleCov.start do
  add_filter "/spec/"
  add_filter "/bin/"
  add_filter "/exe/"

  formatter SimpleCov::Formatter::MultiFormatter.new([SimpleCov::Formatter::Console,
                                                      SimpleCov::Formatter::HTMLFormatter])

  %w[models utils].each do |folder|
    relative_path = "lib/pdfh/#{folder}"
    add_group(folder, relative_path) if Dir.exist?(relative_path)
  end
end
