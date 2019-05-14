#! /usr/bin/python3
"""
Guides localizers in how to edit the translation files.
"""
from parsing import parse_messages, tag_re
from sys import argv
from os.path import isdir

basepath = "data/page-l10n/" if isdir(".git") else "./"

def indent(text):
    return "\t" + "\n\t".join(text.split("\n"))

def input_lines(prompt=""):
    print(prompt, "[Enter a blank line to end]")
    lines = []
    line = input()
    while line:
        lines.append(line)
        line = input()
    return "\n".join(lines).strip()

def prompt_locale():
    from os import listdir
    print(
            "Please select a locale to translate",
            listdir(basepath) if isdir(".git") else "",
            end=":\t"
    )
    return input()

filename = argv[1] if len(argv) > 1 else prompt_locale()
show_all = len(argv) > 2 and argv[2] == "all"
if not show_all:
    print("To review all translations, pass the desired ISO language code and the text 'all' as commandline arguments.")

catalogue = parse_messages(basepath + filename)

translations = []
print("To exit, press Ctrl-C")
for english, open_tag, translation in catalogue:
    if show_all or not translation:
        print(indent(english))

        if translation:
            print("Currently translated to:")
            print(indent(translation))
            print("Enter a blank line to keep")

        tags = [tag for tag in tag_re.split(english) if tag and tag[0] == "{"]
        if tags:
            print("Substitution instructions:")
            for tag in tags:
                print(indent(tag))
                if tag[1] == "#": print("\t\t* Note to you, feel free to drop it")
            print("Please copy these into your translation verbatim")

        if "<" in english and ">" in english:
            print("Text between '<' and '>' are formatting instructions.")
            print("If you don't know web development, please keep them as-is.")
            if "title=" in english:
                print("Though please do translate the quoted text after 'title='.")

        new_translation = input_lines()
        if new_translation: translation = new_translation

    translations.append((english, open_tag, translation))
print(translations)

with open(basepath + filename, "w") as f:
    for english, tag, translation in catalogue:
        print(tag, file=f)
        print(english, file=f)
        print("{% trans %}", file=f)
        print(translation, file=f)
        print("{% endmsg %}", file=f)
