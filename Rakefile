# frozen_string_literal: true

require 'colorize'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'versionomy'

RSpec::Core::RakeTask.new(:spec)

task default: :spec

desc 'Bump gem version number (tiny|minor|major)'
task :bump, :type do |_t, args|
  args.with_defaults(type: :tiny)
  version_file = File.join(__dir__, 'lib', 'pdfh', 'version.rb')
  content = File.read(version_file)

  version_pattern = /(?<major>\d+)\.(?<minor>\d+)\.(?<tiny>\d+)/
  current_version = content.match(version_pattern)
  next_version    = Versionomy.parse(current_version.to_s).bump(args.type).to_s

  File.write(version_file, content.gsub(version_pattern, "\\1#{next_version}\\3"))

  puts "Successfully bumped from #{current_version.to_s.red} to #{next_version.green}"
end
