# AGENTS.md

Guide for agentic coding assistants working in this repository.

## Quick Facts

- Project: `pdfh` (Ruby gem + CLI)
- Runtime Ruby: 4.0 via `mise` (`mise.toml`); gemspec minimum `>= 3.2.0`
- Linting: RuboCop (TargetRubyVersion 3.2); plugins: `rubocop-performance`, `rubocop-factory_bot`, `rubocop-rake`
- Tests: RSpec with `expect` syntax and no monkey patching
- Key runtime deps: `colorize ~> 1.1` (logging colors)

## Build, Lint, Test

Run from repo root. Prefer `mise` tasks when available.

```bash
# Tests
bundle exec rspec
mise run test

# Single test file or example
bundle exec rspec spec/pdfh/models/document_spec.rb
bundle exec rspec spec/pdfh/models/document_spec.rb:42

# Lint
bundle exec rubocop
mise run lint

# Auto-fix linting issues
bundle exec rubocop -a

# Build gem
rake build

# Interactive console
bin/console
```

Useful `mise` tasks (`mise.toml`):

- `mise run lint`
- `mise run test` (runs `bundle exec rspec --order random --format documentation`)
- `mise run check` (runs lint + test)
- `mise run bump[major|minor|tiny]`
- `mise run pre` (runs `pre-commit run --all-files`)
- `mise run update` (runs `bundle update`)
- `mise run release` (builds gem + pushes to RubyGems)

## Repository Layout

- `exe/pdfh` CLI entrypoint
- `lib/pdfh` gem code
- `lib/pdfh/services` service objects
- `lib/pdfh/models` domain models
- `lib/pdfh/utils` shared utilities
- `spec/` RSpec tests, mirrors `lib/` structure

## Processing Flow (High Level)

```text
exe/pdfh → Main.start → OptParser → SettingsBuilder → SettingsValidator
                                                            ↓
                                         DirectoryScanner.scan (finds *.pdf)
                                                            ↓
                                          PdfTextExtractor.call
                                                            ↓
                                          DocumentMatcher.match
                                                            ↓
                                          DocumentManager.call
```

Key service objects in `lib/pdfh/services/`:

- `DirectoryScanner` — globs `*.pdf` from configured `lookup_dirs`
- `PdfTextExtractor` — shells out `pdftotext -enc UTF-8 -layout`
- `DocumentMatcher` — iterates `DocumentType`s; matches `re_id` then `re_date`
- `DocumentManager` — creates dest dir, copies/renames PDF, copies companion files
- `SettingsBuilder` — locates and parses `pdfh.yml`
- `SettingsValidator` — validates settings; raises `ArgumentError` on fatal errors, warns and skips on soft errors (e.g. missing lookup dirs)
- `OptParser` — parses `ARGV` into `RunOptions`

## Code Style and Conventions

General:

- Always include `# frozen_string_literal: true` at the top of Ruby files.
- Use double-quoted strings (RuboCop enforces this).
- Max line length is 120 characters (see `.rubocop.yml`).
- Prefer small, focused classes and service objects for side effects.
- Avoid global state except for `Pdfh.logger` (centralized logger).

Imports / requires:

- Use `require` for gem dependencies and `require_relative` for local files in tests.
- In specs, `spec/spec_helper.rb` loads SimpleCov and shared config; do not load it twice.

Formatting:

- RuboCop is authoritative; follow alignment and formatting it enforces.
- Hash alignment uses table style for hash rockets.

Types and documentation:

- All methods must have YARD documentation.
- `@return` is mandatory and must describe the return value.
- Add `@param` tags with types and names for each parameter.
- For complex methods, add a short explanatory comment block and an `@example`.

Naming:

- Use descriptive names; classes and modules are `CamelCase`, methods and variables are `snake_case`.
- Prefer explicit domain names (e.g., `DocumentManager`, `SettingsBuilder`).
- Keep abbreviations consistent with existing code (e.g., `pdf`, `dir`).

Error handling:

- Use `Pdfh.logger` for user-facing errors and verbose debug output.
- `Main.start` rescues `SettingsIOError` and `StandardError` and exits with status 1.
- Custom exceptions defined in `lib/pdfh.rb`: `SettingsIOError` (config not found), `ReDateError` (date regex no match).
- `SettingsValidator` raises `ArgumentError` for fatal config errors; warns and skips for recoverable ones (e.g. a lookup dir that doesn't exist).
- Favor raising domain-specific errors in services and handle them in entrypoints.
- Avoid rescuing broadly in inner layers unless re-raising with context.

Side effects and IO:

- File system changes are centralized in `DocumentManager`.
- Respect `dry_run` / `--dry` to avoid writing files.
- When copying/moving files, preserve metadata if possible (`FileUtils` with `preserve: true`).

Testing:

- RSpec uses `expect` syntax and disables monkey patching.
- Specs mirror the `lib/` structure; keep tests close to the corresponding module.
- Use FactoryBot factories in `spec/factories/` when needed.

## Configuration and Templates

- Configuration is loaded from `$PDFH_CONFIG_FILE`, then CWD, `~/.config/`, then `~/`.
- Document templates use `{placeholder}` tokens defined in `Document#rename_data`.
- Date regex supports named captures `(?<m>...)` / `(?<y>...)` / `(?<d>...)` or positional captures.

## Dependency Checks

- External tools: `pdftotext` (required) and `qpdf` (declared but not actively called in v4) must be available; checked via `DependencyValidator`.

## Pitfalls

- **v4 breaking change**: Config format changed in v4.0.0 — old configs are incompatible. `re_id` matches PDF *text content* (not filename). New placeholders: `{day}`, `{quarter}`, `{bimester}`, `{name}`.
- **Multi-match behavior**: PDFs matching more than one `DocumentType` are silently skipped (see `Main.start`).
- **`_unlocked` suffix**: `DocumentManager` strips `_unlocked` when locating companion files — legacy pattern from `qpdf` unlocking.
- **Config search path**: `$PDFH_CONFIG_FILE` → CWD → `~/.config/` → `~/`. Error message does not list paths checked.
- **Colorize in tests**: Logging output is colored via `colorize`; specs mock `Console` with shared context `"with silent console"` to suppress output.

## Suggested Workflow for Agents

- Read existing classes/services before adding new ones to match patterns.
- Prefer minimal changes; update specs alongside behavior changes.
- Run `mise run lint` and `mise run test` before finalizing changes.
- Keep changes localized; avoid touching unrelated files.

## Examples

Run a single spec:

```bash
bundle exec rspec spec/pdfh/models/document_spec.rb:42
```

Run lint + test:

```bash
mise run check
```
