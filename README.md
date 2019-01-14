# Pdfh

Examine all PDF files in scrape directories, remove password (if has one), rename and copy to a new directory using regular expresions.

## Installation

```bash
gem install pdfh
```

## Usage

After installing this gem you need to create your configuration file on your home folder.
`pdfh.yml`
```yaml
---
scrape_dirs:       # Directories where all pdf's are going to be analyzed
  - ~/Downloads
base_path: ~/PDFs  # Directory where all matching documents will be copied
document_types:
  - name: Document From Bank              # Description
    re_file: '.*MyBankReg\.pdf'           # Regular expression to match its filename
    re_date: 'al \d{1,2} de (\w+) del? (\d+)' # Date regular expresion
    pwd: base64string                     # [OPTIONAL] Password if the document is protected
    store_path: "{YEAR}/bank_docs"        # Relative path to copy this document
    name_template: '{period} {subtype}'   # Template for new filename when copied
    sub_types:                            # [OPTIONAL] In case your need an extra category 
      - name: Account1                       # Regular expresion to match this subtype
        month_offset: -1                     # [OPTIONAL] Integer value to adjust month
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

```bash
build pdfh.gemspec
gem install pdfh-*
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/iax7/pdfh. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Pdfh project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/iax7/pdfh/blob/master/CODE_OF_CONDUCT.md).
