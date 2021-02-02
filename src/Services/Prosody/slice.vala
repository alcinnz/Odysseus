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
/** This is a wrapper around GLib.Bytes that works better with Vala & LibGee.

This is implemented outside of a namespace for easy access across Odysseus. */
public class Slice : Gee.Hashable<Slice>, Object {
    public Bytes _ = empty;
    private static Bytes empty = new Bytes(new uint8[0]);
    public Slice.s(string s) {this.a(s.data);}
    public Slice.a(uint8[] a) {this.b(new Bytes(a));}
    public Slice.b(Bytes? b) {_ = b == null ? empty : b;}

    public int length {get {return _.length;}}
    public new uint8 get(int i) {
        if (i >= length) return 0;
        return _[i < 0 ? length + i : i];
    }
    public Slice slice(int start_, int end_) {
        // Add some Python-style convenience
        var start = start_; if (start < 0) start += _.length;
        var end = end_; if (end < 0) end += _.length;
        if (end > _.length) end = _.length;
        if (start >= end) return new Slice(); // Gracefully handle minor errors.

        // NOTE: Using the slice method of Bytes (which is provided by the
        //      Vala bindings, not GLib) has been a performance bottleneck
        //      for Prosody as it's implemented in terms of array slice not this.
        return new Slice.b(new Bytes.from_bytes(_, start, end - start));
    }
    private static StringBuilder str_builder = new StringBuilder();
    public string to_string() {
        str_builder.erase();
        str_builder.append_len((string) _.get_data(), _.length);
        return str_builder.str;
    }

    public bool equal_to(Slice other) {return _.compare(other._) == 0;}
    public uint hash() {return _.hash();}
    // Since there isn't syntactic sugar for `==`, provide `in`
    public bool contains(string other) {return new Slice.s(other).equal_to(this);}

    public uint8[] to_array() {return _.get_data();}

    public string parse() {return @"$(this[1:-1])".compress();}
    public Slice[] split(char split) {
        if (length == 0) return new Slice[0];

        var count = 1;
        for (var i = 0; i < length; i++) if (_[i] == split) count++;

        var ret = new Slice[count]; var ret_ix = 0;
        var last_split = 0;
        for (var i = 0; i <= _.length; i++) {
            if (i != _.length && _[i] != split) continue;
            if (i == last_split) continue;

            assert(last_split < i);
            ret[ret_ix++] = this[last_split:i];
            last_split = i + 1;
        }

        return ret;
    }
    public uint8 find_next(uint8[] needles, ref int index) {
        for (; index < _.length; index++) if (_[index] in needles) return _[index];
        return 0;
    }
    public Slice strip() {
        var start = 0;
        while (start < _.length && _[start] in " \t\r\n".data) start++;

        var end = _.length - 1;
        while (end < _.length && _[end] in " \t\r\n".data) end--;

        return this[start:++end];
    }
}
