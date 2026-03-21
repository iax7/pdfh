# frozen_string_literal: true

require "colorize"
require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task default: :spec

desc "Bump gem version number (tiny|minor|major)"
task :bump, :type do |_t, args|
  args.with_defaults(type: :tiny)

  version_file = File.join(__dir__, "lib", "pdfh", "version.rb")
  content = File.read(version_file)

  version_pattern = /VERSION = "(?<major>\d+)\.(?<minor>\d+)\.(?<tiny>\d+)"/
  match = content.match(version_pattern)

  major = match[:major].to_i
  minor = match[:minor].to_i
  tiny = match[:tiny].to_i

  case args.type.to_sym
  when :major
    major += 1
    minor = 0
    tiny = 0
  when :minor
    minor += 1
    tiny = 0
  when :tiny
    tiny += 1
  end

  current_version = "#{match[:major]}.#{match[:minor]}.#{match[:tiny]}"
  next_version = "#{major}.#{minor}.#{tiny}"

  new_content = content.gsub(version_pattern, "VERSION = \"#{next_version}\"")
  File.write(version_file, new_content)

  puts "Successfully bumped from #{current_version.red} to #{next_version.green}"
  puts "\n> Building v#{next_version.green}..."
  puts `rake build`
end
