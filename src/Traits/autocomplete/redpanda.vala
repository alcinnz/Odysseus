/**
* This file is part of Odysseus Web Browser (Copyright Adrian Cochrane 2020).
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
/** Easter egg to test the tokenized entry. */
namespace Odysseus.Traits {
    public class RedPanda : Tokenized.CompleterDelegate {
        static string[] heros = {
            "Red Panda", "Flying Squirrel", "Stranger",
            "Tom Tomorrow, Man Of The Future",
            "Brian McSweeny, Man Of A Thousand Faces",
            "Red Squirrel", "Captain Tom Sunlight", "Red Ensen",
            "Justice Union", "Lady Luck", "Danger Dame", "Ogre",
            "Home Team", "Doc Rocket", "Molecule Max",
            "Danger Federation", "Eagle Smith", "Jenny Swift", "Titanic Man",
                "Blue Bomber", "Doctor Improbable", "Mystic", "White Knight",
                "Star Lass", "Grey Fox", "Mr Amazing",
            "Black Eagle"
        };

        public override void autocomplete(string query, Tokenized.Completer c) {
            var builder = new StringBuilder();
            int index = 0;
            unichar ch;
            bool capitalize = true;

            while (query.get_next_char(ref index, out ch)) {
                if (capitalize) {
                    ch = ch.totitle();
                    capitalize = false;
                } else {
                    ch = ch.tolower();
                    capitalize = ch.isspace();
                }
                builder.append_unichar(ch);
            }

            if (builder.str in heros) c.token(builder.str, "The Red Panda demands it!");
        }
    }
}
