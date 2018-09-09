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
/** Implies additional fallback languages from the environment-specified locale.
    This is necessary for the localization of:
    * Recommendations from https://alcinnz.github.io/Odysseus-recommendations
    * XML and potentially other formats
    * Templates */
namespace Odysseus.I18n {
    public string[] get_locales() {
        var locales = Intl.get_language_names();
        var ret = new Gee.ArrayList<string>.wrap(locales);
        var added = new Gee.HashSet<string>();

        for (var i = locales.length - 1; i >= 0; i--) {
            var sep = locales[i].index_of_char('_');
            if (sep == -1) {added.add(locales[i]); continue;}

            var fallback = locales[i][0:sep];
            if (fallback in added) continue;

            added.add(fallback);
            ret.insert(i, fallback);
        }
        return ret.to_array();
    }
}
