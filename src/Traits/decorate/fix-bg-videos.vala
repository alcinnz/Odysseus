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
/** Bandaid fix for WebKitGTK WebViews not cleaning GStreamer threads
    up after themselves.

The fix here is just to pause videos on tab close.
    Needs to be given it's own mainloop so the JS runs before
    the tab actually closes.

Unfortunately this requires events on the DynamicNotebook for proper behaviour,
    so it needs to be called in from the UI code rather than
    with the other traits. */
namespace Odysseus.Traits {
    public void pause_bg_videos(Granite.Widgets.DynamicNotebook tabs) {
        var js = "for (let media of document.querySelectorAll('video, audio')) media.pause()";
        tabs.tab_removed.connect((tab) => {
            (tab as WebTab).web.run_javascript.begin(js, null);
        });
    }
}
