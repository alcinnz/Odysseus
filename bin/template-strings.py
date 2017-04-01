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

def concat(a, b):
    yield from a
    yield from b

# Parsers
def parse_templates(repo_root="."):
    from os import path
    messages = defaultdict(list)
    plurals = {}
    for filename, subpath in walk(path.join(repo_root, "data", "pages")):
        print("Parsing template", subpath)
        template = tags(filename)
        while True:
            line_no = next(template, "trans")
            if line_no is None: break

            message, endtag = block(template, "plural endtrans")
            if message.startswith("{#"):
                key = message[message.find("#}") + 2:].strip()
            else:
                key = message

            plural = None
            if is_tag(endtag, "plural"):
                plural = block(template, "endtrans").strip()

            messages[key].append("{}#L{}".format(subpath, line_no))
            plurals[key] = (message, plural) # Can't handle more than one
    return messages, plurals

def parse_catalogue(filename):
    template = tags(filename)
    while next(template, "msg") is not None:
        variations = []
        variant, endtag = block(template, "msg en").strip()
        while is_tag(endtag, "msg"):
            variations.append(variant)
            variant, endtag = block(template, "msg en").strip()
        key, endtag = block(template, "plural endmsg")
        if key.startswith("{#"):
            key = key[key.find("#}") + 2:].strip()

        if is_tag(endtag, "plural"): next("endmsg")
        yield key, variations

# Main
if __name__ == "__main__":
    from sys import argv
    import os
    repo_root = argv[1] if len(argv) > 1 else "."
    l10n_root = os.path.join(repo_root, "data", "page-l10n")

    catalogue_sources, catalogue = parse_templates(repo_root)
    with open(os.path.join(l10n_root, "Oddysseus"), 'w') as f:
        print("Writing reference catalogue")
        for key, message in catalogue.items():
            f.write("{% msg " + " ".join(catalogue_sources[key]) + " %}\n")
            f.write("{% en %}\n")
            f.write(message[0] + "\n")
            if message[1] is not None:
                f.write("{% plural %}\n" + message[1] + "\n")
            f.write("{% endmsg %}\n")

    for filename in os.listdir(l10n_root):
        if filename.endswith(".unused"): continue
        if filename in ("README", "Oddysseus"): continue
        print("Merging into catalogue for", filename)

        unused_entries = []
        filepath = os.path.join(l10n_root, filename)
        with open(filepath+".tmp", 'w') as f:
            for key, variations in concat(
                    parse_catalogue(filepath),
                    parse_catalogue(filepath+".unused")):
                if key in catalogue:
                    for i, variant in enumerate(variations):
                        args = ""
                        if i == 0:
                            args = " " + " ".join(catalogue_sources[key])
                        f.write("{% msg" + args + " %}\n")
                        f.write(variant + "\n")
                    f.write("{% en %}\n")
                    singular, plural = catalogue[key]
                    f.write(singular + "\n")
                    if plural is not None:
                        f.write(plural + "\n")
                    f.write("{% endmsg %}\n")
                elif variations and variations != [""]:
                    # There's a translation here,
                    # so don't through away that translator's hard work.
                    unused_entries.append(key, variations)
        os.rename(filepath+".tmp", filepath)

        with open(filepath + ".unused", 'w') as f:
            for key, variations in unused_entries:
                for variant in variations:
                    f.write("{% msg %}" + variant + "\n")
                f.write("{% en %}" + key + "{% endmsg %}")
                # No need to preserve the plural block or comment.
                # They're not used for lookup.
