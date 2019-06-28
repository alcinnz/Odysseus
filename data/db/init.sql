/**
* This file is part of Odysseus Web Browser (Copyright Adrian Cochrane 2017-2018).
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
-- Please note the piping into SQLite requires the SQL statements to be
--      unbroken by Prosody templating tags/variables.
BEGIN TRANSACTION;
{% if v < 1 %}
  CREATE TABLE window(
    x, y, width, height, state,
    focused_index,
    delete_batch DEFAULT 0
  );
  CREATE TABLE tab(
    window_id,
    order_, pinned,
    history /* JSON */
  );
{% endif %}

{% if v < 2 %}
  CREATE TABLE page_visit(
    tab,
    uri,
    title,
    favicon,
    visited_at,
    referrer
  );

  CREATE TABLE screenshot(uri, image);

  -- Used to allocate colours for odysseus:history. 
  -- Note: The default is very naive, but normal browsing should fix it over time.
  ALTER TABLE tab ADD COLUMN historical_id DEFAULT 0;
{% endif %}

{% if v < 3 %}
  CREATE VIRTUAL TABLE history_fts USING fts5(uri, title,
    tokenize = 'porter unicode61', content = 'page_visit',
    columnsize = 0); -- We don't need ranking
{% endif %}

{% if v < 4 %}
  -- And now, build a new screenshots table that is properly unique
  CREATE TABLE screenshot_v2(uri PRIMARY KEY ON CONFLICT IGNORE, image);
  INSERT OR IGNORE INTO screenshot_v2(uri, image) SELECT uri, image FROM screenshot;
  -- Unfortunately can't drop screenshot table now, SQLite errors out
    -- saying the table is locked.
  -- Add indices so the SQLite's AI can speed things up.
  CREATE INDEX historical_chronology ON page_visit(visited_at);
  CREATE INDEX historical_locations ON page_visit(uri);

  -- Now the real meat!
  CREATE TABLE topsites_whitelist(uri PRIMARY KEY, order_);
  CREATE INDEX topsites_by_order ON topsites_whitelist(order_);
  CREATE TABLE topsites_blacklist(uri PRIMARY KEY);
{% endif %}

{% if v < 5 %}
  -- Create a table to cache recommendations from https://alcinnz.github.io/Odysseus-recommendations/db/
  CREATE TABLE recommendations(uri PRIMARY KEY, weight);
  DELETE FROM screenshot; -- Clean up this unused data, should've done so earlier.
{% endif %}

{% if v < 6 %}
  -- Prepare a table to make odysseus:home fast
  CREATE TABLE visit_counts(url PRIMARY KEY, count);
  CREATE INDEX url_by_count ON visit_counts(count, url);
{% endif %}

PRAGMA user_version = 6;
END TRANSACTION;
