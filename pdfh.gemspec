# frozen_string_literal: true

require "uri"
require_relative "lib/pdfh/version"

Gem::Specification.new do |spec|
  spec.name          = "pdfh"
  spec.version       = Pdfh::VERSION
  spec.authors       = ["Isaias Piña"]
  spec.email         = ["iax7@users.noreply.github.com"]

  spec.summary       = "Organize PDF files"
  spec.description   = "Examine all PDF files in Look up directories, remove password (if has one), " \
                       "rename and copy to a new directory using regular expressions."
  spec.homepage      = "https://github.com/iax7/pdfh"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.5.0")

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = URI.join(spec.homepage, "CHANGELOG.md").to_s

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:\.\w+|doc|test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "colorize", "~> 0.8.0"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.metadata["rubygems_mfa_required"] = "true"
end
