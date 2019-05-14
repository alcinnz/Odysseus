#! /usr/bin/python3
"""
Monitors localization progress.
"""
from parsing import parse_messages
from sys import argv
from os.path import isdir

basepath = "data/page-l10n/" if isdir(".git") else "./"

def prompt_locale():
    from os import listdir
    print(
            "Please select a locale",
            listdir(basepath) if isdir(".git") else "",
            end=":\t"
    )
    return input()

filename = argv[1] if len(argv) > 1 else prompt_locale()

translations = [translation for _, _, translation in parse_messages(basepath + filename)]
fraction = "{}/{}".format(
        sum(1 for translation in translations if translation), len(translations)
)
print(fraction, "messages translated in", filename)
