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

{% if v < 7 %}
  CREATE TABLE unvisited_links(uri, endorsements);
  CREATE TABLE link_sources(link, domain);
{% endif %}
-- Global because I forgot them in Odysseus 1.6
CREATE INDEX IF NOT EXISTS unvisited_link__uri ON unvisited_links(uri);
CREATE INDEX IF NOT EXISTS unvisited_link__endorsements ON unvisited_links(endorsements, uri); -- Vital.
CREATE INDEX IF NOT EXISTS link_sources__both ON link_sources(link, domain);

{% if v < 8 %}
  CREATE TABLE vocab(url UNIQUE, label UNIQUE, hue UNIQUE);
  CREATE TABLE tags(url UNIQUE, label, vocab);
  CREATE TABLE tag_labels(tag, altlabel);
  CREATE INDEX altlabels ON tag_labels(altlabel, tag);
  CREATE TABLE tag_infers(broader, narrower);
  CREATE INDEX tag_narrower ON tag_infers(narrower, broader);
  CREATE INDEX tag_broader ON tag_infers(broader, narrower);

  CREATE TABLE favs(url UNIQUE, title, desc);
  CREATE TABLE fav_tags(fav, tag);
  CREATE INDEX tag_favs_index ON fav_tags(tag, fav);
  CREATE INDEX fav_tags_index ON fav_tags(fav, tag);
{% endif %}
INSERT OR IGNORE INTO vocab VALUES ("odysseus:myvocab.ttl#", "", 1.0);
INSERT OR IGNORE INTO vocab VALUES ("odysseus:chrome.skos#", "Browser integrations", 0.5);
INSERT OR IGNORE INTO tags VALUES ("odysseus:chrome.skos#home", "homepage", (SELECT rowid FROM vocab WHERE url = "odysseus:chrome.skos#"));
INSERT OR IGNORE INTO tag_labels VALUES ((SELECT rowid FROM tags WHERE url = "odysseus:chrome.skos#home"), "home");
INSERT OR IGNORE INTO tag_labels VALUES ((SELECT rowid FROM tags WHERE url = "odysseus:chrome.skos#home"), "homepage");
INSERT OR IGNORE INTO tag_labels VALUES ((SELECT rowid FROM tags WHERE url = "odysseus:chrome.skos#home"), "startpage");
INSERT OR IGNORE INTO tag_labels VALUES ((SELECT rowid FROM tags WHERE url = "odysseus:chrome.skos#home"), "new tab page");

PRAGMA user_version = 8;
END TRANSACTION;
