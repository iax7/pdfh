# PDF Handler (pdfh)

[![Rubocop][rubocop-img]][rubocop-url]
[![Ruby][ruby-img]][ruby-url]
[![Conventional Commits][cc-img]][cc-url]
[![Current version][gem-img]][gem-url]

Examine all PDF files in lookup directories, identify them using regular expressions, rename them, and copy them to organized directories.

## Installation

```bash
gem install pdfh
```

### Dependencies

You need to install `pdftotext` to extract text from PDF files.

#### macOS

```bash
brew install xpdf
```

#### Fedora

```bash
sudo dnf install -y poppler-utils
```

#### Arch

```bash
sudo pacman -S poppler
```

## Usage

After installing this gem, create your configuration file in one of the following directories:

- `~/.config/pdfh.yml`
- `~/pdfh.yml`
- or configure the `PDFH_CONFIG_FILE` environment variable

Then run:

```bash
pdfh
```

The tool will:

1. Scan all PDFs in the configured `lookup_dirs`
2. Extract text from each PDF using `pdftotext`
3. Match the extracted text from each PDF against your configured `document_types` (via `re_id`)
4. Copy matched documents to organized directories within `destination_base_path`
5. Rename files according to your `name_template`

### Configuration

Example configuration:

```yaml
---
lookup_dirs:                   # Directories where all PDFs will be analyzed
  - ~/Downloads
destination_base_path: ~/PDFs  # Directory where all matching documents will be copied (MUST exist)
document_types:
  - name: My Bank                         # Description (type)
    re_id: 'Account ID: 12334-\w{3}'      # [OPTIONAL (uses name as fallback)] RegEx to match from PDF content as document identifier
    re_date: '\d{1,2} de (\w+) de (\d+)'  # Date RegEx (to extract from PDF content)
    store_path: "{year}/bank_docs"        # Relative path to copy this document
    name_template: '{period} {name}'      # [OPTIONAL] Template for new filename when copied
```

### Placeholders

**Store Path** and **Name Template** support the following placeholders:

| Placeholder | Description | Example |
| --- | --- | --- |
| `{original}` | Original filename | `MyBankDocument2.pdf` |
| `{period}` | Year-Month | `2022-07` |
| `{year}` | Year | `2022` |
| `{month}` | Month | `07` |
| `{day}` | Day (if captured) | `01` |
| `{quarter}` | Quarter (Q1-Q4) | `Q3` |
| `{bimester}` | Bimester (B1-B6) | `B4` |
| `{name}` | Document type **name** | `My Bank` |

The `period`, `year`, `month`, `day`, `quarter` and `bimester` placeholders are calculated from the date captured by the `re_date` regular expression.

### Date Extraction Examples

The `re_date` regex extracts date information from the PDF content:

| Date text | RegEx | Captured |
| --- | --- | --- |
| `01/02/2025` | `(?<d>\d{2})\/(?<m>\d{2})\/(?<y>\d{4})` | d: `01` m: `02` y: `2025` |
| `072025 -` | `(?<m>\d{2})(?<y>\d{4}) -` | m: `07` y: `2025` |
| `31 de julio de 2025` | `\d{1,2} de (\w+) de (\d+)` | month: `julio` year: `2025` |

Named captures supported: `y` for year, `m` for month, `d` for day.

If named captures are not used, the regex groups will be matched in order: `month`, `year`.

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

## Command Options

Run with verbose output:

```bash
pdfh -v
```

Run in dry-run mode (no files will be moved):

```bash
pdfh --dry
```

Show version:

```bash
pdfh --version
```

<!-- Links -->
[rubocop-img]: https://github.com/iax7/pdfh/actions/workflows/rubocop-analysis.yml/badge.svg
[rubocop-url]: https://github.com/iax7/pdfh/actions/workflows/rubocop-analysis.yml
[ruby-img]: https://img.shields.io/badge/ruby-4.0-blue?style=flat&logo=ruby&logoColor=CC342D&labelColor=white
[ruby-url]: https://www.ruby-lang.org/en/
[cc-img]: https://img.shields.io/badge/Conventional%20Commits-1.0.0-%23FE5196?logo=conventionalcommits&logoColor=00&labelColor=fff
[cc-url]: https://conventionalcommits.org
[gem-img]: https://img.shields.io/gem/v/pdfh?labelColor=fff&label=version
[gem-url]: https://rubygems.org/gems/pdfh
