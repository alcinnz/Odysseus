/**
* This file is part of Odysseus Web Browser (Copyright Adrian Cochrane 2017).
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
/** Persists tab history in that tab's restore_data. */
namespace Odysseus.Traits {
    public void setup_persist_tab_history(WebTab tab) {
        var web = tab.web;

        web.load_changed.connect((evt) => {
            var history = web.get_back_forward_list();
            var json = new Json.Builder();

            json.begin_object();
            json.set_member_name("current");
            json.add_string_value(history.get_current_item().get_uri());
            json.set_member_name("title");
            json.add_string_value(history.get_current_item().get_title());
            json.set_member_name("back");
            json.begin_array();
            foreach (var record in history.get_back_list()) {
                json.begin_object();
                json.set_member_name("href");
                json.add_string_value(record.get_uri());
                json.set_member_name("title");
                json.add_string_value(record.get_title());
                json.end_object();
            }
            json.end_array();
            json.set_member_name("forward");
            json.begin_array();
            foreach (var record in history.get_forward_list()) {
                json.begin_object();
                json.set_member_name("href");
                json.add_string_value(record.get_uri());
                json.set_member_name("title");
                json.add_string_value(record.get_title());
                json.end_object();
            }
            json.end_array();
            json.end_object();

            var generator = new Json.Generator();
            generator.set_root(json.get_root());
            tab.restore_data = generator.to_data(null);
        });
    }
}
