# PDF Handler (pdfh)

[![Rubocop][rubocop-img]][rubocop-url]
[![Ruby][ruby-img]][ruby-url]
[![Conventional Commits][cc-img]][cc-url]
[![Current version][gem-img]][gem-url]

Examine all PDF files in lookup directories, remove passwords (if present), rename them, and copy them to a new directory using regular expressions.

## Installation

```bash
gem install pdfh
```

### Dependencies

You need to install pdf handling dependencies in order to use this gem.

#### macOS

```bash
brew install qpdf xpdf # < for pdftotext
```

#### Fedora

```bash
sudo dnf install -y qpdf poppler-utils
```

#### Arch

```bash
sudo pacman -S qpdf poppler
```

## Usage

After installing this gem, create your configuration file in one of the following directories:
- `~/.config/pdfh.yml`
- `~/pdfh.yml`
- or configure the `PDFH_CONFIG_FILE` environment variable

Example configuration:
```yaml
---
lookup_dirs:                   # Directories where all PDFs will be analyzed
  - ~/Downloads
destination_base_path: ~/PDFs  # Directory where all matching documents will be copied (MUST exist)
document_types:
  - name: My Bank                         # Description (type)
    re_file: '.*MyBankReg\.pdf'           # Regular expression to match its filename
    re_date: '\d{1,2} de (\w+) de (\d+)'  # Date regular expression
    pwd: base64_encoded                   # [OPTIONAL] Password if the document is protected
    store_path: "{year}/bank_docs"        # Relative path to copy this document
    name_template: '{period} {subtype}'   # Template for new filename when copied
    sub_types:                            # [OPTIONAL] In case your need an extra category
      - name: AccountX                       # Regular expression to match this subtype
        re_date: '\d{1,2} de (\w+)'          # [OPTIONAL] Date regular expression
        month_offset: -1                     # [OPTIONAL] Integer (signed) value to adjust month
zip_types:                     # [OPTIONAL] Zip files to be processed BEFORE the PDFs
  - name: My Bank 2                          # Description
    re_file: 'Document_MR5664_\d+_\d+.zip'   # Regular expression to match its filename
    pwd: base64_encoded                      # [OPTIONAL] Password if the document is protected
```

> [!CAUTION]
> `pwd` is not encrypted, so be careful with this option. It is stored as a base64 string as a very thin layer of obfuscation.
> You can use `echo -n 'password' | base64` to encode your password.

**Store Path** and **Name Template** supported placeholders:

Placeholder | Description               | Example
--- |---------------------------| ---
`{original}` | Original filename         | MyBankDocument2.pdf
`{period}`   | Year-Month                | 2022-01
`{year}`     | Year                      | 2022
`{month}`    | Month                     | 01
`{type}`     | Document type **name**    | My Bank
`{subtype}`  | Sub type **name**         | AccountX
`{extra}`    | day if captured/matched   | 01

`period`, `year`, `month` and `{extra}` are calculated from the date captured by the regular expression.

### Examples

Date text | RegEx | Captured
--- | --- | ---
`01/02/2025` | `(?<d>\d{2}\/(?<m>\d{2})\/(?<y>\d{4})` | d: `01` m: `02` y: `2025`
`072025 - ` | `(?<m>\d{2})(?<y>\d{4}) -` | m: `07` y: `2025`

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `rake install`. To release a new version, run `rake bump`, and then run `rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

```bash
rake install

# step by step
build pdfh.gemspec
gem install pdfh-*
```

To release a new version, run:

```bash
rake bump
rake release
```

This will create a git tag for the version, push git commits and tags, and upload the `.gem` file to rubygems.org.

### Conventional Commits

```bash
npm install -g @commitlint/cli @commitlint/config-conventional
commitlint --from origin --to @
```

## Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/iax7/pdfh>. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Pdfh project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/iax7/pdfh/blob/master/CODE_OF_CONDUCT.md).

<!-- Links -->
[rubocop-img]: https://github.com/iax7/pdfh/actions/workflows/rubocop-analysis.yml/badge.svg
[rubocop-url]: https://github.com/iax7/pdfh/actions/workflows/rubocop-analysis.yml
[ruby-img]: https://img.shields.io/badge/ruby-3.4-blue?style=flat&logo=ruby&logoColor=CC342D&labelColor=white
[ruby-url]: https://www.ruby-lang.org/en/
[cc-img]: https://img.shields.io/badge/Conventional%20Commits-1.0.0-%23FE5196?logo=conventionalcommits&logoColor=00&labelColor=fff
[cc-url]: https://conventionalcommits.org
[gem-img]: https://img.shields.io/gem/v/pdfh?labelColor=fff&label=version
[gem-url]: https://rubygems.org/gems/pdfh
