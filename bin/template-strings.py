#! /usr/bin/python3
"""Extracts text from the templates used to create internal pages."""
import re, sys

def walk_files(top):
    import os
    for path, dirnames, filenames in os.walk(top):
        for filename in filenames:
            yield os.path.join(path, filename)

def parse(text):
    # Parse manually, as regular expressions don't like handling newlines
    # NOTE I'm requiring a single space before and after the tagnames
    i = text.find("{% trans")
    while i != -1:
        # body text
        i = text.find("%}", i)
        if i == -1: raise SyntaxError("Unexpected end of file")
        start = i + 2
        end = i = text.find("{% endtrans %}", i)
        body = text[start:end].strip()

        # comment
        comment = ""
        if body.startswith("{#"):
            split = body.find("#}")
            comment = body[2:split].strip()
            body = body[split+2:].strip()

        # plural forms
        plural = body.find("{% plural %}")
        if plural != -1:
            plural = body[split + len("{% plural %}"):].strip()
            body = body[:split].strip()
        else:
            plural = ""

        yield 0, body, comment, plural
        i = text.find("{% trans", i)

def esc(text):
    """Outputs a double quoted string"""
    text = repr(text)
    if text[0] == '"': return text
    text = text.replace('"', '\\"')
    return '"' + text[1:-1] + '"'

for filename in walk_files("data/pages"):
    # ignore certain specially interpreted file extensions
    if filename.endswith(".mime"): continue
    if filename.endswith(".link"): continue
    if filename.endswith(".icon"): continue
    if filename.endswith("~"): continue
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
        for lineno, string, comment, plural in parse(fd.read()):
            # Output the parsed text in an .h file format  format
            print("#line", lineno, filename)
            if comment:
                print("/* TRANSLATORS", comment, "*/")
            if plural:
                print("char *s = NC_(" + esc(string) + ", "
                    + esc(plural) + ");")
            else:
                print("char *s = N_(" + esc(string) + ");")
