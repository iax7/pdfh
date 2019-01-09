# frozen_string_literal: true

require 'pdfh/version'
require 'pdfh/settings'
require 'pdfh/document'
require 'pdfh/utils'

##
# Gem entry point
module Pdfh
  def self.main(options = {})
    Verbose.active = options[:verbose]
    Dry.active = options[:dry]

    settings = Settings.new(search_config_file)

    settings.scrape_dirs.each do |work_directory|
      print_separator(work_directory)
      ignored_files = []
      Dir["#{work_directory}/*.pdf"].each do |file|
        base_name = File.basename(file, File.extname(file))
        type = settings.match_doc_type(file)
        unless type
          ignored_files << base_name
          next
        end

        pad = 12
        puts "Working on #{base_name.colorize(:light_green)}"
        print_ident 'Type', type.name, :light_blue, width: pad
        doc = Document.new(file, type)
        print_ident 'Sub-Type', doc.sub_type, :light_blue, width: pad
        print_ident 'Period', doc.period, :light_blue, width: pad
        print_ident 'New Name', doc.new_name, :light_blue, width: pad
        print_ident 'Store Path', doc.store_path, :light_blue, width: pad
        print_ident 'Other files', doc.companion_files(join: true), :light_blue, width: pad
        doc.write_pdf(settings.base_path)
      end

      puts "\nNo account was matched for these PDF files:" unless ignored_files.empty?
      ignored_files.each.with_index(1) do |file, index|
        print_ident index, file, :red
      end
    end
  rescue StandardError => e
    line = e.backtrace[0].match(/:(\d+)/)[1]
    puts "Error, #{e.message}. #{line}".colorize(:red)
    exit 1
  end

  def self.print_separator(title)
    _rows, cols = `stty size`.split.map(&:to_i)
    sep = "\n#{'-' * 40} #{title} "
    remaining_cols = cols - sep.size
    sep += '-' * remaining_cols if remaining_cols.positive?
    puts sep.colorize(:light_yellow)
  end

  def self.print_ident(field, value, color = :green, width: 3)
    field_str = field.to_s.rjust(width)
    value_str = value.colorize(color)
    puts "#{' ' * 4}#{field_str}: #{value_str}"
  end

  def self.search_config_file
    name = File.basename($PROGRAM_NAME)
    names_to_look = ["#{name}.yml", "#{name}.yaml"]
    dir_order = [Dir.pwd, File.expand_path('~')]

    dir_order.each do |dir|
      names_to_look.each do |file|
        f = File.join(dir, file)
        return f if File.file?(f)
      end
    end

    raise StandardError, "no configuraton file (#{names_to_look.join(' or ')}) was found\n       within paths: #{dir_order.join(', ')}"
  end
end
