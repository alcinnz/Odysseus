#! /usr/bin/python3
"""Extracts text from the templates used to create internal pages."""
import re, sys

def walk_files(top):
    import os
    for path, dirnames, filenames in os.walk(top):
        for filename in filenames:
            yield os.path.join(path, filename)

translatable_re = """
{%\s*trans('([^']|\.)*'|"([^"]|\.)*"|.)*%}
(?P<string>.*?)
({%\s*plural\s*%}\s*(?P<plural>.*))?
{%\s*endtrans\s*%}
"""

strings = {}

for filename in walk_files("data/pages"):
    # ignore certain specially interpreted file extensions
    if filename.endswith(".mime"): continue
    if filename.endswith(".link"): continue
    if filename.endswith(".icon"): continue
    if filename.endswith("/README"): continue

    # check if the file specifies it's not a template
    try:
        with open(filename + ".mime") as f:
            if f.read()[0] != '+': continue
    except:
        "If file.mime doesn't exist, file is a template"

    # Now it's safe
    with open(filename) as fd:
        sys.stderr.write(filename + "\n")
        for match in re.finditer(translatable_re, fd.read(), re.VERBOSE):
            string = match.group('string').strip()
            # Parse out the comment
            comment = ""
            if string.startswith("{#"):
                split = string.find("#}")
                comment = string[2:split].strip()
                string = string[split+2:].strip()

            # Skip duplicates
            if string in strings: continue
            strings.add(string)

            # Output the parsed text in PO format
            print()
            if comment: print("#.", comment)
            print("msgid", string)
            plural = match.group('plural')
            if plural: print("msgid_plural", repr(plural))
            print("msgstr", repr(""))
