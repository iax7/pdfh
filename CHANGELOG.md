## v3.0.2
- Fix `undefined method` when an invalid option is provided
- Fix and add tests to get above 90% coverage

## v3.0.1
- Refactor classes for better readability
- Upgrade to Ruby v3.3.0 and require at least Ruby 3.0.0
- Upgrade gem dependencies

## v3.0.0
- Migrate to `asdf` from `rvm`
- Upgrade old gems
- Bump to v3 (as this is project's third iteration)

## v0.2.0
- Major gem refactoring
- Change setting `base_path` to `destination_base_path`
- Add DocumentType listing option on executable file
- Add process individual documents providing type and files
    ```bash
    pdfh -t document_type_id path/to_files.pdf
    ```
- Add `settings.yml` template in order to create a sample file

## v0.1.9
- Add dependencies validation at run

## v0.1.5
- Add `print_cmd` field in config file for information purposes
- Settings now validates an unexisting directory
- Refactor for easier maintenance

## v0.1.4
- Add titleize format when writing new file

## v0.1.3
- Fixed copy companion files, which was not copying the files.

## v0.1.2
- Initial Release
