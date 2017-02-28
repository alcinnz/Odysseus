/**
* This file is part of Odysseus Web Browser (Copyright Adrian Cochrane 2017).
*
* Oddysseus is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* Oddysseus is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.

* You should have received a copy of the GNU General Public License
* along with Oddysseus.  If not, see <http://www.gnu.org/licenses/>.
*/

/* Adaptor and text processing functions used to improve
		the performance of templates.

	Specifically they allow the implementation to use GLib.Bytes,
		in place of strings. In doing so it allocates and
		copies around significantly less data for the performance win. */
namespace Oddysseus.Templating.ByteUtils {
	public bool re_match(Regex re, Bytes text, out MatchInfo matches)
	        throws RegexError {
	    return re.match_full((string) text.get_data(), text.length,
	                                0, 0, out matches);
	}

	public Bytes? re_fetch(MatchInfo matches, Bytes text) {
	    int start;
	    int end;
	    if (matches.fetch_pos(0, out start, out end))
	        return text.slice(start, end);
        return null;
    }

	private StringBuilder? to_string__builder = null;
	public unowned string to_string(Bytes? text) {
	    if (text == null) return "";

	    if (to_string__builder == null) to_string__builder = new StringBuilder();
	    to_string__builder.erase();
	    to_string__builder.append_len((string) text.get_data(), text.length);
	    return to_string__builder.str;
	}

	// Parses a string literal to a Vala string
	public string parse_string(Bytes text) {
	    return to_string(text.slice(1, text.length - 1)).compress();
	}
	
	public Bytes from_string(string text) {
	    return new Bytes(text.data);
	}

    // TODO remove...
	public int count(Bytes text, char split, out int last_offset = null) {
	    var count = 0;
	    last_offset = 0;
	    for (var index = 0; index < text.length; index++) {
	        if (text[index] == split) {
	            count++;
	            last_offset = index;
	        }
	    }
	    return count;
	}
	
	public Bytes[] split(Bytes? text, char split) {
        if (text == null) return new Bytes[0];

	    var count = 1;
	    for (var index = 0; index < text.length; index++) {
	        if (text[index] == split) count++;
	    }
	    
	    var ret = new Bytes[count];
	    var ret_ix = 0;
	    var last_split = 0;
	    for (var index = 0; index <= text.length; index++) {
	        // the former condition ensures we collect the last item. 
	        if (index == text.length || text[index] == split) {
	            assert(ret_ix < count);
	            ret[ret_ix++] = text.slice(last_split, index);
	            last_split = index + 1;
	        }
	    }
	    
	    return ret;
	}

	private uint hash_bytes(Bytes b) {return b.hash();}
	private bool bytes_equal(Bytes a, Bytes b) {return a.compare(b) == 0;}

	public Gee.Map<Bytes, V> create_map<V>(
	        owned Gee.EqualDataFunc<V>? value_equal_func = null) {
	    return new Gee.HashMap<Bytes, V>(hash_bytes, bytes_equal,
	            (owned) value_equal_func);
	}

	uint8 find_next(Bytes text, uint8[] needles, ref int index) {
		for (; index < text.length; index++) {
			if (text[index] in needles) return text[index];
		}
		return 0;
	}

	async void write_escaped(Bytes? text, Gee.Map<uint8,string>? subs,
	        Writer output) {
	    if (text == null) return;
	    if (subs == null) {
	        yield output.write(text);
            return;
        }

		var needles = subs.keys.to_array();
		subs['\0'] = "\0"; // Behaviour for end of string.

		int index = 0;
		int last_index = 0;
		while (index < text.length) {
			var substitute = subs[find_next(text, needles, ref index)];
			if (index > last_index) // Ensure valid slices.
				yield output.write(text.slice(last_index, index));
			yield output.writes(substitute);
			last_index = ++index;
		}
	}

	async void write_escaped_html(Bytes text, Writer output) {
		var mappings = new Gee.HashMap<char, string>();
		mappings['<'] = "&lt;";
		mappings['>'] = "&gt;";
		mappings['&'] = "&amp;";

		yield write_escaped(text, mappings, output);
	}

	bool equals_str(Bytes? bytes, string chars) {
		return bytes != null && bytes.compare(from_string(chars)) == 0;
	}
}
