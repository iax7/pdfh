## v0.2.0
* Major gem refactoring
* Changed setting `base_path` to `destination_base_path`
* Add DocumentType listing option on executable file
* Add process individual documents providing type and files
  ```bash
  pdfh -t document_type_id path/to_files.pdf
  ```
* Add settings.yml template in order to create a sample file

## v0.1.9
* Add dependencies validation at run

## v0.1.5
* Add print_cmd field in config file for information purposes
* Settings now validates a no existing directory
* Refactor for easier maintenance

## v0.1.4
* Add titleize format when writing new file

## v0.1.3
* Fixed copy companion files, which was not copying the files.

## v0.1.2
* Initial Release
