/**
* This file is part of Odysseus Web Browser (Copyright Adrian Cochrane 2019).
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

namespace Odysseus.Traits {
    private short count = 0;
    public void maybe_spring_clean(WebKit.LoadEvent event) {
        if (event != WebKit.LoadEvent.FINISHED || count++ != 16) return;

        Templating.ErrorData errData = null;
        try {
            Templating.get_for_resource("/io/github/alcinnz/Odysseus/odysseus:/spring-clean", ref errData)
                .exec.begin(new Templating.Data.Empty(), new Templating.VoidWriter());
        } catch (Error err) {warning("Failed to run spring cleaning.");}
    }
}
