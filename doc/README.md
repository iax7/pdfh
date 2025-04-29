# Legacy

This project was born as a bash script. It was initially ported to a Python script while I was learning Python. As my Ruby was more polished it ended as a Ruby gem. Below is the old Bash and Python code, provided just for fun.

## Bash Code (v1)

```bash
#!/bin/env bash
. .common # this script is hosted in my dotfiles repo

YEAR=$(date +%Y)
PASS=SECR3T_PASSWORD
GREP_PERIOD='al [0-9]{1,2} de ([A-Zz-z]*) de.? [0-9]+'
#Path to move, Dropbox. Use "{YEAR}" to replace with actual year
MVTO=../"Impuestos/FISCAL-{YEAR}/Edo Cuenta"

app_installed qpdf

count=$(find . -type f -name '[!2]*.pdf' | wc -l)
if [ "$count" == '0' ]; then
    echo -e "${RED}Error, no pdf files found.${RST}"
    exit 1
fi

for pdf in [!2]*.pdf; do
    [ ! -r "$pdf" ] && echo -e "${RED}Error, can't access $pdf${RST}" && exit 1
    echo -e "Working on ${GRE}$pdf${RST}..."

    # Decrypt PDF and uncompress to work with it
    temp=$(mktemp)
    #trap 'rm $temp' 0 SIGINT SIGQUIT SIGTERM
    qpdf --password="$PASS" --decrypt --stream-data=uncompress "$pdf" "$temp"

    # Extract Data from PDF
    account=$(strings "$temp" | grep -ioE 'platinum|perfiles' | head -1)
    account=${account,,}
    account=${account^}
    echo -e "        account: ${BLU}$account${RST}"
    #period=$(strings "$temp" | grep -iEo 'al [0-9]{1,2} de ([A-Zz-z]*) de [0-9]+' | tail -1)
    #month=$(echo "$period" | tr ' ' '\n'| tail -3 | head -1)
    #year=$(echo "$period" | tr ' ' '\n' | tail -1)
    period=$(pdftotext "$temp" - | grep -iEo "$GREP_PERIOD" | tail -1 )
    month=$(echo "$period" | awk '{print $4}')
    year=$(echo "$period" | awk '{print $6}')
    period=${month,,}

    if [ -z "$period" ]; then
      echo -e "${RED}Error, period not found.${RST}"
      exit 1
    fi

    number=$(convert_month $period)
    if [ "$account" == "Perfiles" ]; then
        #number=$(( number - 1 ))
        number=$(echo "$number - 1" | bc)
        if [ "${#number}" -eq 1 ]; then
          number="0$number"
        fi
    fi
    echo -e "         period: ${BLU}$year-$period${RST}"

    #Prepare new PDF
    newfile="$year-${number} ${account}.pdf"
    #pdftk "$pdf" input_pw "$PASS" output "$newfile"
    qpdf --password="$PASS" --decrypt "$pdf" "$newfile"
    if [ -f "$newfile" ]; then
        mv "$pdf" "${newfile/.pdf/}_$pdf"
        echo -e "       new file: ${BLU}$newfile${RST}"
    fi

    #Copy it
    MVTO="${MVTO//'{YEAR}'/$year}"
    if [ -d "$MVTO" ]; then
      cp -v "$newfile" "$MVTO"
    fi
done
```

## Python Code (v2)

```python
#!/usr/bin/env python3
"""Organize PDF protected password files, using rules defined in yaml format."""
from __future__ import print_function
import os
import re
import base64
import pprint
import argparse
import tempfile
import subprocess
import yaml
from shutil import copyfile
from colorama import Fore

IS_VERBOSE = False
IS_DRY = False
# TODO: calendar.month_name[11] current locale
MONTHS = dict(
    enero = 1,
    febrero = 2,
    marzo = 3,
    abril = 4,
    mayo = 5,
    junio = 6,
    julio = 7,
    agosto = 8,
    septiembre = 9,
    octubre = 10,
    noviembre = 11,
    diciembre = 12
)

class InlineClass(object):
    """Wrapper to have an object like dictionary"""
    def __init__(self, dict):
        self.__dict__ = dict
    def has_key(self, key):
        return key in self.__dict__.keys()

def get_month_num(num):
    # Not implemented yet
    import locale
    locale.setlocale(locale.LC_ALL, 'es_MX')
    import calendar
    calendar.month_name[num]

class Document(object):
    """Handles the PDF detected by the rules, and makes transformations"""
    def __init__(self, file, account, **kwargs):
        self._file = file
        self._act = account
        self._extra = ''
        self._has_xml = False
        self._verbose = kwargs['verbose']
        verbose = self._verbose
        if verbose:
            print(Fore.CYAN + account.name, '==================' + Fore.RESET)

        self._pwd = base64.b64decode(self._act.pwd) if self._act.pwd else ''
        if type(self._pwd) is bytes:
            self._pwd = self._pwd.decode()

        if not os.path.exists(self._file):
            raise IOError("I can't find the PDF")

        # Check if additional XML file exists
        self._xml_file = os.path.splitext(self._file)[0]+'.xml'
        if os.path.exists(self._xml_file):
            self._has_xml = True

        self._tmp = tempfile.mktemp(suffix=".pdf")
        if verbose:
            print(Fore.CYAN + '  --> ' + self._tmp + ' temporal file assigned.' + Fore.RESET)

        cmd1 = "qpdf --password='{}' --decrypt --stream-data=uncompress '{}' '{}'" \
                .format(self._pwd, self._file, self._tmp)
        subprocess.call(cmd1, shell=True)

        cmd2 = "pdftotext -enc UTF-8 '{}' -".format(self._tmp)

        p = subprocess.Popen(cmd2, stdout=subprocess.PIPE, shell=True)
        self._text, _err = p.communicate()
        if type(self._text) is bytes:
            self._text = self._text.decode(encoding="utf-8", errors="replace")
        if verbose:
            print(Fore.CYAN + self._text + Fore.RESET)

        match = re.search(self._act.re_date, self._text, re.MULTILINE)
        if not match:
            print(Fore.RED, 'Err, date was not extracted with regex provided: ' + Fore.LIGHTRED_EX +
                  self._act.re_date + Fore.RESET)
            exit(1)
        if verbose:
            print(Fore.CYAN, '==== Regex Groups:', match.groups(), Fore.RESET)
        try:
            self._month = match.group('m')
            self._year = match.group('y')
        except IndexError:
            self._month, self._year = match.groups()

        if len(match.groups()) > 2:
            self._extra = match.group(3)

        self._month = self._month.lower()
        if verbose:
            print(Fore.CYAN, '==== Assigned:', (self._month, self._year, self._extra),
                  '==( Month, Year, Extra )================' + Fore.RESET)

        if self._act.has_key('types'):
            for t in self._act.types:
                name = t['name']
                if re.search(name, self._text, re.IGNORECASE):
                    self.type = name
                    self.offset = t.get('month_offset', 0)
        else:
            self.type = None
            self.offset = 0

        if verbose:
            print(Fore.CYAN, 'Offset settings, Type:', self.type, '/ Month:', self.offset, Fore.RESET)
        #Used if the month offset results in change in year.
        self._year_offset = 0
        if verbose:
            print(Fore.CYAN, 'END INIT ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~' + Fore.RESET)

    def __repr__(self):
        type_str = self.type if self.type else 'N/A'
        format_string = 'Name     : {}\nType     : {}\nPeriod   : {}\nFile Path: {}\n'+\
                        'File Name: {}\nNew Name : {}\nStorePath: {}\nFullPath : {}'
        return format_string.format(
            self.name, type_str, self.period, self._file,
            self.filename_only, self.new_name, self.store_path, self.full_path)

    def write_pdf(self):
        dir_path = os.path.dirname(self.full_path)
        if not os.path.exists(dir_path):
            raise IOError("I can't find the store_path")

        cmd = "qpdf --password='{}' --decrypt '{}' '{}'" \
              .format(self._pwd, self._file, self.full_path)
        subprocess.call(cmd, shell=True)

        if os.path.exists(self.full_path):
            bkp = self._file + '_'
            os.rename(self._file, bkp)
            # Copy XML File if exists
            if self._has_xml:
                xml_new_path = os.path.splitext(self.full_path)[0]+'.xml'
                copyfile(self._xml_file, xml_new_path)
                xml_bkp = self._xml_file + '_'
                os.rename(self._xml_file, xml_bkp)
                if self._verbose:
                    print(Fore.CYAN, 'XML Written: ', xml_new_path, Fore.RESET)
        else:
            raise IOError("The file was not created.")

    @property
    def name(self): return self._act.name
    @property
    def filename_only(self):
        dir, file = os.path.split(self._file)
        filename, ext = os.path.splitext(file)
        return filename
    @property
    def text(self): return self._text
    @property
    def month(self):
        try:
            month_num = int(self._month)
        except:
            if len(self._month) == 3:
                for month in MONTHS:
                    if month[0:3] == self._month:
                        month_num = MONTHS[month]
            else:
                month_num = MONTHS[self._month]


        if self.offset:
            tmp = month_num + self.offset
            if tmp == 0:
                tmp = 12
                self._year_offset = -1
            elif tmp == 13:
                tmp = 1
                self._year_offset = 1
        else:
            tmp = month_num
        return str(tmp).zfill(2)
    @property
    def year(self):
        if len(self._year) == 2:
            tmp = '20' + self._year
        else:
            tmp = self._year
        year = int(tmp) + self._year_offset

        return str(year)
    @property
    def period(self): return "{}-{}".format(self.year, self.month)
    @property
    def new_name(self):
        if self._act.has_key('name_template'):
            template = self._act.name_template
        else:
            template = '{original}'

        type = self.type if self.type else 'NA'
        new = template \
                .replace('{original}', self.filename_only) \
                .replace('{period}', self.period) \
                .replace('{type}', type) \
                .replace('{extra}', self._extra)
        return new + '.pdf'
    @property
    def store_path(self):
        tmp = self._act.store_path.replace('{YEAR}', self.year)
        return tmp
    @property
    def full_path(self):
        tmp = self.store_path
        tmp = tmp if tmp[0] != '/' else tmp[1:]
        base = os.path.expanduser(self._act.base_path)
        base = os.path.abspath(base)
        return os.path.join(base, tmp, self.new_name)

class Settings(object):
    """Open the rules YAML file"""
    def __init__(self):
        name = os.path.basename(__file__).replace('py', 'yml')
        dir_oder = []
        dir_oder.append(os.path.dirname(__file__))
        dir_oder.append(os.path.expanduser('~'))

        paths = map(lambda x: os.path.join(x, name), dir_oder)

        for path in paths:
            if os.path.isfile(path):
                conf_path = path
                break

        if 'conf_path' not in locals():
            print('{}Error, no configuration file was found: {}{}{}'
                  .format(Fore.RED, Fore.MAGENTA, ', '.join(paths), Fore.RESET))
            exit(1)

        fsettings = open(conf_path, 'r')
        if IS_VERBOSE:
            print("Loaded configuration file: {}{}{}"
                  .format(Fore.GREEN, conf_path, Fore.RESET))
        self.__dict__ = yaml.load(fsettings)

    def print(self):
        pp = pprint.PrettyPrinter(indent=2)
        pp.pprint(self.__dict__)

    def getAccount(self, file_name):
        for act in self.accounts:
            srch = re.search(act['re_file'], file_name)
            if srch != None:
                act['base_path'] = self.base_path
                return InlineClass(act)

    def getScrapeDirectories(self):
        max_length = len(max(self.scrape_dirs, key=len))

        if IS_VERBOSE:
            print('Processing directories:')
            for directory in self.scrape_dirs:
                path = os.path.expanduser(directory)
                path = os.path.abspath(path)
                print_ident(directory, path, color=Fore.BLUE, field_width=max_length)
            print()

        for directory in self.scrape_dirs:
            path = os.path.expanduser(directory)
            path = os.path.abspath(path)
            yield path

def get_files(directory=None):
    """Analyze current directory for PDF files"""
    path = os.path.dirname(os.path.abspath(__file__)) if directory == None else directory
    for pdffile in os.listdir(path):
        if pdffile.endswith(".pdf"):
            yield os.path.join(path, pdffile)

def print_ident(field, value, **kwargs):
    """Print value with the color specified and correct indentation.

    Args:
        field (int): The value name
        value (str): The value to print
        color (AnsiFore): The color to use
        field_width (int): The indentation length of fields

    Returns:
        None: No value is returned.
    """
    color = kwargs['color'] if 'color' in kwargs else Fore.GREEN
    field_width = kwargs['field_width'] if 'field_width' in kwargs else 7
    string_format = '    {:>'+str(field_width)+'}: {}{}{}'
    print(string_format.format(field, color, value, Fore.RESET))

def print_separator(title, color=Fore.LIGHTYELLOW_EX):
    _rows, cols = os.popen('stty size', 'r').read().split()
    sep = '\n' + color
    sep += '-' * 40 + ' ' + title + ' '
    remaining_cols = int(cols) - len(sep)
    if remaining_cols > 0:
        sep += '-' * remaining_cols
    sep += Fore.RESET
    print(sep)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("-d", "--dry",
                        action="store_true",
                        help="Dry run, does not write new pdf")
    parser.add_argument("-v", "--verbose",
                        action="store_true",
                        help="Show more output, useful for debug")
    args = parser.parse_args()

    if args.dry:
        global IS_DRY
        IS_DRY = True
        print(Fore.CYAN + "Running in dry mode..." + Fore.RESET)
    if args.verbose:
        global IS_VERBOSE
        IS_VERBOSE = True
        print(Fore.CYAN + "Running in verbose mode..." + Fore.RESET)

    settings = Settings()
    #settings.getScrapeDirectories()
    #sys.exit(1)

    for work_directory in settings.getScrapeDirectories():
        print_separator(work_directory)
        ignored_files = []
        for pdffile in get_files(work_directory):
            try:
                base = os.path.basename(pdffile)
                act = settings.getAccount(pdffile)
                if not act:
                    raise ValueError('no account was matched.')
                print('Working on' + Fore.LIGHTGREEN_EX, base, Fore.RESET)
                print_ident(' Cuenta', act.name, color=Fore.LIGHTBLUE_EX)
                doc = Document(pdffile, act, verbose=IS_VERBOSE)
                #print(edocta) # Debug ----
                print_ident('Periodo', doc.period)
                if IS_VERBOSE:
                    print(Fore.CYAN, doc, Fore.RESET)
                if not IS_DRY:
                    doc.write_pdf()
                    print_ident('NewFile', doc.full_path)
            except ValueError as e:
                #print(e)
                ignored_files.append(base)
                #print(Fore.LIGHTRED_EX + '    Error!', e, Fore.RESET)
            except IOError as e:
                print('Error, the filepath {} does not exists.'.format(doc.full_path))

        print('\nNo account was matched for these PDF files:')
        for num, path in enumerate(ignored_files, start=1):
            print_ident(num, path, color=Fore.RED, field_width=3)


if __name__ == '__main__': main()

```
