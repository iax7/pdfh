# frozen_string_literal: true

# lib = File.expand_path("lib", __dir__)
# $LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require_relative "lib/pdfh/version"

Gem::Specification.new do |spec|
  spec.name          = "pdfh"
  spec.version       = Pdfh::VERSION
  spec.authors       = ["Isaias Piña"]
  spec.email         = ["iax7@users.noreply.github.com"]

  spec.summary       = "Organize PDF files"
  spec.description   = "Examine all PDF files in scrape directories, remove password (if has one), "\
                       "rename and copy to a new directory using regular expresions."
  spec.homepage      = "https://github.com/iax7/pdfh"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.5.0")

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org"

    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = spec.homepage
    spec.metadata["changelog_uri"] = "https://raw.githubusercontent.com/iax7/pdfh/master/CHANGELOG.md"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:\.\w+|docs|test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "colorize", "~> 0.8.0"
end
