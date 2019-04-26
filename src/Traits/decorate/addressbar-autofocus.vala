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
/** Simplifies user interaction when opening a new tab.
        Because normally opening a new tab indicates they want to go somewhere
        specific. */
namespace Odysseus.Traits {
    public void setup_addressbar_autofocus(WebTab tab) {
        var web = tab.web;
        web.load_changed.connect((evt) => {
            if (evt != WebKit.LoadEvent.STARTED || web.uri != "odysseus:home") return;
            var win = tab.get_toplevel() as BrowserWindow;
            if (win == null) return;

            win.addressbar.entry.grab_focus();
        });
    }
}
