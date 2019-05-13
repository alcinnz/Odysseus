#!/usr/bin/python3
"""Parses {% trans %} Prosody tags to extract strings,
which it then writes out into data/page-l10n/Oddysseus and
merges into the other catalogue files in that directory. """
from collections import defaultdict
from parsing import *

# Utilities
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

        line, text, is_tag = next(template, "trans")
        while line:
            if is_tag:
                message, endtag = block(template, "endtrans")
                yield message.strip(), subpath, line
            else:
                for special in ("{%", "%}", "{{", "}}", "{#", "#}"):
                    if special in text:
                        print("Invalid text translation!", repr(text))
                        exit(1)
                yield text.strip(), subpath, line
            line, text, is_tag = next(template, "trans")

def consolidate(messages):
    from collections import OrderedDict
    ret = OrderedDict()
    for msg, tpl, line in messages:
        if msg not in ret: ret[msg] = []
        ret[msg].append(tpl + ":" + str(line))
    return ret.items()

from sys import argv
import os
repo_root = argv[1] if len(argv) > 1 else "."
l10n_root = os.path.join(repo_root, "data", "page-l10n")

with open(os.path.join(l10n_root, "Odysseus.messages"), 'w') as out:
    for msg, sources in consolidate(parse_templates(repo_root)):
        print("{% msg", " ".join(sources), "%}", msg, "{% trans %}{% endmsg %}", file=out)

print("All messages have been extracted to:",
        os.path.join(l10n_root, "Odysseus.messages"))
print("You may now manually merge them with other message files,")
print("we do not yet have any tools to help you with this.")
print("But even if we did, this would require manual review.")
