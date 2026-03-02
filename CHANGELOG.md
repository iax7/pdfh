# Changelog

## v4.0.0 - 2026-03-21

### Breaking

- Old settings file is not compatible with this version; update to the new format described in README.
- Drop password/Base64 handling; require only `pdftotext` command.
- Remove subtypes and ZIP processing support.

### Added

- New name template placeholders: `{day}`, `{quarter}`, `{bimester}`, `{name}`.

### Changed

- Remove `{extra}` and `{type}` placeholders from name template.
- Refactor processing flow into services (scanner, extractor, matcher, manager).
- Drop document identification by file name; identify documents by content with `re_id`.
- Improve logging and error handling with a global logger.
- Update README usage and configuration docs.

## v3.3.1 - 2026-03-06

- Add document type required fields validation
- Upgrade to Ruby 4
- Upgrade gems and mise tasks

## v3.3.0 - 2025-05-06

- Add zip file pre-processing and zip_type model
- Decouple main and opt_parser from ARGV
- Add PasswordDecodable module and move dependency check to utils
- Add pre-commit config and update RuboCop config
- Update Ruby version and dependencies; improve coverage and docs

## v3.2.0 - 2025-04-01

- Change document_type to a class and add re_date support for sub types
- Add more config file locations
- Remove undocumented print_cmd field
- Add backtrace console output
- Migrate to mise and upgrade Ruby/dependencies

## v3.1.0 - 2024-05-03

- Handle store_path placeholders as name_template

## v3.0.3 - 2024-03-15

- Move document rename to its own object
- Add debug gem
- Fix minor documentation issues

## v3.0.2 - 2024-01-10

- Fix `undefined method` when an invalid option is provided
- Fix and add tests to get above 90% coverage

## v3.0.1 - 2024-01-09

- Refactor classes for better readability
- Upgrade to Ruby v3.3.0 and require at least Ruby 3.0.0
- Upgrade gem dependencies

## v3.0.0 - 2022-08-01

- Migrate to `asdf` from `rvm`
- Upgrade old gems
- Bump to v3 (as this is project's third iteration)

## v0.2.0 - 2021-05-14

- Major gem refactoring
- Change setting `base_path` to `destination_base_path`
- Add DocumentType listing option on executable file
- Add process individual documents providing type and files

    ```bash
    pdfh -t document_type_id path/to_files.pdf
    ```

- Add `settings.yml` template in order to create a sample file

## v0.1.9 - 2021-03-02

- Add dependencies validation at run

## v0.1.5 - 2019-04-01

- Add `print_cmd` field in config file for information purposes
- Settings now validates an unexisting directory
- Refactor for easier maintenance

## v0.1.4 - 2019-01-28

- Add titleize format when writing new file

## v0.1.3 - 2019-01-18

- Fixed copy companion files, which was not copying the files.

## v0.1.2 - 2019-01-10

- Initial Release
