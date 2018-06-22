There are a handful of considerations that apply to any change that is made to Odysseus. And to help new contributors feel more confident that their changes will be accepted I will document these considerations here.

## UI Design

* If your change extends Odysseus's chrome it will be subject to rigurous discussion. Adding further UI complexity to it should be avoided.
* On the otherhand adding new gestures, autocompleters, or internal pages will likely be accepted quickly. Adding new menuitems will involve some discussion, but will probably also be accepted fairly quickly.
* If a new feature involves sending information over the Internet, the privacy implications of it must be considered.
* New features should avoid directly integrating specific websites.
* UI designs will be judged according to the [elementary HIG](https://elementary.io/docs/human-interface-guidelines), and any internal pages should have a brutalist/minimalist/typographic design.
* For any UI component websites can integrate into, designs that allow multiple sites to integrate into it should be preferred. This is an attempt to minimize the push towards central services.
* Thought should be given to how not to require maintainance effort from the user.

## System Design

* Each file should contain a header comment describing why it's there and what it does.
* The copyright notice in each file should state who has changed a file in the past and between which years has it been changed. This same information is available from Git, but I find it appropriate to summarise it there.
* We have a reuse, extend, invent philosophy. Reuse existing functions and stylings wherever possible, extend if needed, and only invent new if absolutely necessary.
* Odysseus should be understandable as a bunch of simple components layered ontop of it's core UI, somewhat resembling the [UZBL browser](https://www.uzbl.org/) but hardcoded. This helps the core UI code avoid being overly complex.
* Odysseus's code should adhear to any relevant standards (W3C, FreeDesktop.Org, etc) when interacting with any out-of-process code. Failing that a proposed standard should be drafted in a separate repository.
* Odysseus incorporates a templating language ("Prosody") used to define it's internal pages, and that templating language has a testsuite. No code should be submitted that breaks those tests.

---

If anyone has any suggestions for how to improve or extend these list, feel free to contribute.
