# Contributing to Odysseus
So you have a feature you want integrated into Odysseus and are willing to put the work into, or you simply want to help out? Then this guide will help you.

To start join the [Matrix chatroom](https://riot.im/app/#/room/#odysseus-web:matrix.org), clone https://github.com/alcinnz/Odysseus.git, and optionally fork the repository on GitHub. If you do not want to sign up for GitHub you are welcome to contribute entirely via Matrix.

If you need to discuss anything, feel free to do so via either the Matrix chatroom or the [issue tracker](https://github.com/alcinnz/Odysseus/issues).

Once you feel you're code is ready to contribute upstream (and there's no failures in [the Prosody tests](odysseus:debugging/test)) open a GitHub pull request or run [`git format-patch`](https://git-scm.com/docs/git-format-patch) and submit it to the Matrix chatroom.

## Governance
Currently Odysseus is governed by a BDFL, Adrian Cochrane. Though that may adjusted as the project gets larger.

While he'll welcome any and all features into Odysseus, all contributions will be reviewed not just on a code quality basis but a usability and privacy. But as long as you keep the following concerns in mind your contribution is likely to be accepted:

* Is your new feature more useful than the complexity (in terms of both UI and performance) it adds?
* Are you sending information over the Internet? Have you gained concent? Can you minimize how much can be inferred from it?
* Are relying on any particular website? Please minimize that.
* Can you allow more than a single site/page to be integrated into Odysseus via your feature?
* Which open standards are relevant to it?

## Code Style

* Each file should contain comments declaring it to be under the GPLv3+, who has contributed to it and in which years, and a description of what that file does and why it's there.
* If your code can be implemented in Prosody, and/or as self-contained "traits" ontop of WebKitGTK and Odysseus's core UI, do so.
* Use the GNOME coding styles with 4 space indents and no spaces between method names and their parenthesese.

---

See how this documentation can be improved? Then please contribute to it!
