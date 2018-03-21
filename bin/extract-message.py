#!/usr/bin/python3
"""Parses {% trans %} Prosody tags to extract strings,
which it then writes out into data/page-l10n/Oddysseus and
merges into the other catalogue files in that directory. """
import re
from collections import defaultdict

# Utilities
tag_re = re.compile("({%x%}|{{x}}|{#x#})".replace("x",
        """([^'"]|'([^\\']|\\\\.)*?'|"([^\\"]|\\\\.)*?")*?"""))
def tags(filename):
    with open(filename) as f:
        line_no = 0
        for bit in tag_re.split(f.read()):
            if not bit: continue
            yield bit, line_no
            line_no += bit.count("\n")

def is_tag(token, tagnames):
    if not token.startswith("{%"): return False
    token = token[2:-2].strip().split()
    return token[0] in tagnames.split()

def next(template, tagnames):
    for token, line_no in template:
        if is_tag(token, tagnames):
            return line_no
    return None

def block(template, tagnames):
    block = ""
    for token, line_no in template:
        if is_tag(token, tagnames): return block.strip(), token
        else: block += token
    raise ValueError("Failed to find endtag out of '{}'".format(tagnames))

def walk(top):
    import os
    for path, dirnames, filenames in os.walk(top):
        for filename in filenames:
            # ignore certain specially interpreted file extensions
            if filename.endswith(".mime"): continue
            if filename.endswith(".link"): continue
            if filename.endswith(".icon"): continue
            if filename.endswith("~"): continue
            if filename in ("README", "README.md"): continue
            if filename.endswith(".gresource.xml"): continue
            filepath = os.path.join(path, filename)

            # Final check: does the optional .mime specify it's a template?
            try:
                with open(filepath + ".mime") as f:
                    if f.read(1) != "+": continue
            except:
                "Implicit MIMEType is an HTML template"

            yield filepath, filepath[len(top):]

# Parsers
def parse_templates(repo_root = "."):
    from os import path
    for filename, subpath in walk(path.join(repo_root, "data", "pages")):
        print("Parsing template", subpath)
        template = tags(filename)
        while next(template, "trans"):
            message, endtag = block(template, "endtrans")
            yield message.strip()

if __name__ == "__main__":
    from sys import argv
    import os
    repo_root = argv[1] if len(argv) > 1 else "."
    l10n_root = os.path.join(repo_root, "data", "page-l10n")

    with open(os.path.join(l10n_root, "Odysseus.messages"), 'w') as out:
        for msg in set(parse_templates(repo_root)):
            print("{% msg %}", msg, "{% trans %}{% endmsg %}", file=out)

    print("All messages have been extracted to:",
            os.path.join(l10n_root, "Odysseus.messages"))
    print("You may now manually merge them with other message files,")
    print("we do not yet have any tools to help you with this.")
    print("But even if we did, this would require manual review.")
