#! /usr/bin/python3
"""
Takes messages from a base file and merges in translations from another.
"""
from parsing import parse_messages
from sys import argv
from os.path import isdir

def indent(text):
    return "\t" + "\n\t".join(text.split("\n"))

if len(argv) <= 1:
    print("USAGE: bin/merge-messages.py language-file [base-file [output-file]]")
    print("If you run this from the root of Odysseus's repository,")
    print("the filepaths are relative to data/page-l10n/ .")
    print()
    print("For language-file, just use your ISO language code.")
    print("base-file falls back to 'Odysseus.messages'.")
    print("output-file falls back to the same value as base-file.")
    exit(1)

catalogue = {}

base_path = "data/page-l10n/" if isdir(".git") else "./"
merge_file = base_path + argv[1]
base_file = base_path + (argv[2] if len(argv) > 2 else "Odysseus.messages")
output_file = base_path + argv[3] if len(argv) > 3 else merge_file

for english, tag, translation in parse_messages(base_file):
    catalogue[english] = (tag, translation)

for english, _, translation in parse_messages(merge_file):
    if not translation: continue
    if english not in catalogue:
        print("Removed translation:")
        print(indent(translation))
        print("For:")
        print(indent(english))
        print("Please look for a similar message")

        continue

    tag, old_translation = catalogue[english]
    catalogue[english] = (tag, translation)

    if old_translation:
        print("Replaced translation:")
        print(indent(old_translation))
        print("For:")
        print(indent(english))
        print("With:")
        print(indent(translation))

with open(output_file, "w") as f:
    for english, (tag, translation) in catalogue.items():
        print(tag, file=f)
        print(english, file=f)
        print("{% trans %}", file=f)
        print(translation, file=f)
        print("{% endmsg %}", file=f)
