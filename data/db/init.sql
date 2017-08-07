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
-- Ran on startup by Services/database/database.vala
--      to apply any changes required to keep the database up-to-date.
-- Only ever append to this file, whilst incrementing the
--      the user_version pragma on the last line.
{% if v < 1 %}
  CREATE TABLE window(
    window_id PRIMARY KEY AUTOINCREMENT,
    x, y, width, height, state,
    focused_index
  );
  CREATE TABLE tab(
    tab_id PRIMARY KEY AUTOINCREMENT,
    window_id REFERENCES window ON UPDATE DELETE,
    order_, pinned,
    history /* JSON */
  );
{% endif %}
PRAGMA user_version = 1;
