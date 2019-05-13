"""
Python module for parsing "Prosody" template files and it's translation catalogues.
"""
import re

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
    import codecs
    unicode_escape = codecs.getdecoder('unicode_escape')
    for token, line_no in template:
        if is_tag(token, tagnames):
            return line_no, token, True
        if token.startswith("{{"):
            body = token[2:-2].strip().split("|")
            if (body[0][0] in "'\"" and body[0][-1] == body[0][0]
                    and len(body) >= 2 and body[1] == "trans"):
                return line_no, unicode_escape(body[0][1:-1])[0], False
    return None, None, None

def block(template, tagnames):
    block = ""
    for token, line_no in template:
        if is_tag(token, tagnames): return block.strip(), token
        else: block += token
    raise ValueError("Failed to find endtag out of '{}'".format(tagnames))

def parse_messages(filename):
    catalogue = tags(filename)
    line, open_tag, is_tag = next(catalogue, "msg")
    while line is not None:
        if not is_tag:
            raise ValueError("Unexpected variable token on line {}".format(line))

        english, trans_tag = block(catalogue, "trans")
        translation, end_tag = block(catalogue, "endmsg")
        yield english, open_tag, translation

        line, open_tag, is_tag = next(catalogue, "msg")
