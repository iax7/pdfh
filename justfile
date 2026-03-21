# Run commands through bundle if present

set shell := ["bash", "-c"]

# List all available tasks
default:
    @just --list

# --- Installation and setup ---

# Install gems and system dependencies via mise
[group('setup')]
setup:
    mise install
    bundle install

# Update gems
[group('setup')]
update:
    bundle update --bundler
    bundle update --all

# --- Testing and quality ---

# Run all checks (linting and tests)
[group('test')]
check: lint test

# Run all tests with RSpec
[group('test')]
test:
    bundle exec rspec

# Run a specific test (e.g., just test-file spec/models/user_spec.rb:42)
[group('test')]
test-file path:
    bundle exec rspec {{ path }}

# Run the linter (RuboCop) and auto-fix simple issues
[group('test')]
lint:
    bundle exec rubocop -a

# Open coverage HTML report
[group('test')]
coverage:
    @[[ -f coverage/index.html ]] && open coverage/index.html || echo "Coverage report not found"

# --- Version management and release ---

# Bump version (major|minor|tiny)
[group('release')]
bump type='tiny':
    bundle exec rake "bump[{{ type }}]"
    bundle install

# Build and install the gem locally
[group('release')]
install:
    bundle exec rake install

# Create a git tag, build and push gem to RubyGems
[group('release')]
release:
    bundle exec rake release
