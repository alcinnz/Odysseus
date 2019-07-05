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
/** Extracts unvisited links from webpages in order to recommended them later. */
namespace Odysseus.Traits {
    public void setup_recommendations_harvester(WebTab tab) {
        var qCheckLinks = Database.parse("SELECT rowid FROM unvisited_links WHERE uri = ?;");
        var qCheckHistory = Database.parse("SELECT * FROM page_visit WHERE uri = ?;");
        var qUpdateLink = Database.parse("UPDATE unvisited_links SET endorsements = endorsements + ? WHERE uri = ?;");
        var qInsertLink = Database.parse("INSERT INTO unvisited_links(endorsements, uri) VALUES (?, ?);");
        var qCheckSources = Database.parse("SELECT * FROM link_sources WHERE link = ? AND domain = ?;");
        var qInsertSource = Database.parse("INSERT INTO link_sources(link, domain) VALUES (?, ?);");

        tab.links_parsed.connect((links, _) => {
            foreach (var link in links) {
                if (link.rel == "" || link.rel == null || link.href.has_prefix("odysseus:")) continue;
                qCheckHistory.bind_text(1, link.href);
                if (!testQuery(qCheckHistory)) continue;

                // Now we know we want to save this link.
                var domain = new Soup.URI(tab.url).host;

                // Save the link itself.
                qCheckLinks.bind_text(1, link.href);
                var isUpdating = testQuery(qCheckLinks);
                unowned Sqlite.Statement query = isUpdating ? qUpdateLink : qInsertLink;

                query.reset();
                // Ofcourse sites recommend themselves, it means more when they recommend others.
                query.bind_int(1, domain == new Soup.URI(link.href).host ? 1 : 10);
                query.bind_text(2, link.href);
                if (query.step() != Sqlite.OK) continue;
                var linkid = isUpdating ?
                        qCheckLinks.column_int64(0) : Database.get_database().last_insert_rowid();

                // Save an attribution
                qCheckSources.bind_int64(1, linkid);
                qCheckSources.bind_text(2, domain);
                if (!testQuery(qCheckSources)) {
                    qInsertSource.reset();
                    qInsertSource.bind_int64(1, linkid);
                    qInsertSource.bind_text(2, domain);
                    qInsertSource.step();
                }
            }
        });
    }

    private bool testQuery(Sqlite.Statement query) {
        query.reset();
        return query.step() == Sqlite.ROW;
    } 
}
