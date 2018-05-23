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
/** Support for reading TSV files into Prosody data.

    This is mostly used for downloading recommendations to fill in gaps in Top Sites. */
namespace Odysseus.Templating {
    public async Data.Data readTSV(DataInputStream stream) throws IOError {
        var rows = new Gee.ArrayList<Data.Data>();
        for (var line = yield stream.read_line_async(); line != null;
                line = yield stream.read_line_async()) {
            line = line.strip();
            if (line == "" || line[0] == '#') continue;

            var row = line.split("\t");
            var prosody_row = new Data.Data[row.length];
            for (var i = 0; i < row.length; i++)
                prosody_row[i] = new Data.Literal(row[i]);
            rows.add(new Data.List.from_array(prosody_row));
        }
        return new Data.List(rows);
    }
}
