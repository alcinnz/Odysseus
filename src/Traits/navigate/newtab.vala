/**
* This file is part of Odysseus Web Browser (Copyright Adrian Cochrane 2018).
*
* Odysseus is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* Odysseus is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.

* You should have received a copy of the GNU General Public License
* along with Odysseus.  If not, see <http://www.gnu.org/licenses/>.
*/

/** Handles certain modifiers to mean the link should be opened in a new tab. */
namespace Odysseus.Traits {
    public void setup_newtab_shortcuts(WebKit.WebView web) {
        web.decide_policy.connect((decision, type) => {
            if (type != WebKit.PolicyDecisionType.NAVIGATION_ACTION) return false;

            var nav = (decision as WebKit.NavigationPolicyDecision).navigation_action;
            var use_new = (Gdk.ModifierType.CONTROL_MASK & nav.get_modifiers()) != 0
                    || nav.get_mouse_button() == 3;
            if (!use_new) return false;

            decision.ignore();
            web.create(nav);
            return true;
        });
    }
}
