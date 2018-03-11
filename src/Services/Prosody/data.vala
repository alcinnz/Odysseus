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

/* Data model for the templating language,
        predominantly accessed via Odysseus.Templating.Variable.

    Can currently work with JSON, and Vala literals. */
namespace Odysseus.Templating.Data {
    private void indent(string text, StringBuilder builder) {
        var lines = text.split("\n");
        builder.append(lines[0]);
        foreach (var line in lines[1:lines.length]) {
            builder.append("\n\t");
            builder.append(line);
        }
    }
    public abstract class Data : Object {
        /* These methods are used in core language syntax */
        public virtual new Data get(Bytes property) {
            Data ret = new Empty();
            foreach_map((key, val) => {
                if (key.compare(property) == 0) {
                    ret = val;
                    return true;
                }
                return false;
            });
            return ret;
        }

        public virtual string to_string() {
            var builder = new StringBuilder();
            builder.append("{");
            @foreach_map((key, val) => {
                builder.append("\n\t");
                builder.append_len((string) key.get_data(), key.length);
                builder.append(" => ");
                indent(val.to_string(), builder);
                return false;
            });
            builder.append("}");
            return builder.str;
        }
        public virtual Bytes to_bytes() {
            return b(this.to_string());
        }

        /* These methods/properties are used by important tags,
            as well as filters. */
        public virtual bool exists {
            get {return to_int() != 0;}
        }

        public delegate bool ForeachMap(Bytes key, Data val);
        public virtual void foreach_map(ForeachMap cb) {
            @foreach((key) => cb(key, this[key]));
        }
        // Possibly easier way to implement foreach_map
        public delegate bool Foreach(Bytes key);
        protected virtual void @foreach(Foreach cb) {
            @foreach_map((key, val) => cb(key));
        }

        /* These methods are used by a variety of filters */
        public virtual double to_double() {return (double) to_int(); }
        public virtual int to_int(out bool is_length = null) {
            is_length = false;
            return (int) to_double();
        }
        // Exposes (through a filter) traversal-based query languages
        //        for the particular data format.
        // Defaults to using our Variable syntax.
        public virtual Data lookup(string query) {
            try {
                return new Variable(b(query)).eval(this);
            } catch (SyntaxError e) {
                warning("Invalid syntax expression: %s", e.message);
                return new Empty();
            }
        }
    }

    // Utility callback-iterator for numeric ranges
    public bool range(Data.Foreach cb, uint end, uint start = 0) {
        for (var index = start; index < end; index++) {
            var key = "$%u".printf(index);
            if (cb(b(key))) return true;
        }
        return false;
    }

    public class Empty : Data {
        public override Data get(Bytes _) {return this;}
        public override string to_string() {return "";}
        public override void foreach_map(Data.ForeachMap cb) {}
        public override int to_int(out bool is_length = null) {
            is_length = false; return 0;
        }
    }

    public class Literal : Data {
        public Value data;
        public Literal(Value v) {
            this.data = v;
        }

        public override void foreach_map(Data.ForeachMap cb) {
            var text = to_string();

            int index = 0;
            uint unichar_count = 0;
            unichar c;
            while (text.get_next_char(ref index, out c)) {
                var key = "$%u".printf(unichar_count++);
                if (cb(b(key), new Literal(c))) break;
            }
        }

        public override string to_string() {
            if (data.holds(typeof(double))) {
                // Obtain better formatter
                char[] buf = new char[double.DTOSTR_BUF_SIZE];
                return ((double) data).to_str(buf);
            } else if (data.holds(typeof(unichar))) {
                return ((unichar) data).to_string();
            } else if (data.holds(typeof(char))) {
                return ((char) data).to_string();
            }

            Value ret = Value(typeof(string));
            if (data.transform(ref ret)) return ret.dup_string();
            else return "";
        }

        public override int to_int(out bool is_length = null) {
            is_length = false;
            Value ret = Value(typeof(int));
            if (data.transform(ref ret)) return ret.get_int();
            else return 0;
        }

        public override double to_double() {
            Value ret = Value(typeof(double));
            if (data.transform(ref ret)) return (double) ret;
            else return 0.0;
        }

        public override bool exists {
            get {
                if (data.holds(typeof(string))) {
                    return ((string) data).length > 0;
                } if (data.holds(typeof(double)) || data.holds(typeof(int))) {
                    return to_double() > 0;
                } else {
                    Value ret = Value(typeof(bool));
                    if (data.transform(ref ret)) return (bool) ret;
                    else return true; // Exists simply by being there
                }
            }
        }
    }

    public class Substr : Data {
        Bytes data;
        public Substr(Bytes b) {this.data = b;}

        public override void foreach_map(Data.ForeachMap cb) {
            var text = (string) data.get_data();

            int index = 0;
            uint char_count = 0;
            unichar c;
            while (text.get_next_char(ref index, out c)) {
                if (index > data.length) {
                    warning("Unicode validation error!");
                    return;
                }
                var key = "$%u".printf(char_count++);
                if (cb(b(key), new Literal(c))) break;
            }
        }

        public override string to_string() {return ByteUtils.to_string(data);}
        public override Bytes to_bytes() {return data;}
        public override bool exists {get {return data.length > 0;}}

        public override int to_int(out bool is_length = null) {
            is_length = false;
            return int.parse(to_string());
        }

        public override double to_double() {return double.parse(to_string());}
    }

    public class Mapping : Data {
        public Gee.Map<Bytes, Data> data;
        public string? text;
        public Mapping(Gee.Map<Bytes, Data>? m = null, string? s = "") {
            if (m != null) this.data = m;
            else this.data = ByteUtils.create_map<Data>();
            this.text = s;
        }

        public override Data get(Bytes property) {
            if (data.has_key(property)) return data[property];
            else return new Empty();
        }
        public new void set(string property, Data val) {
            data[b(property)] = val;
        }
        public override void foreach_map(Data.ForeachMap cb) {
            data.map_iterator().@foreach((k, v) => !cb(k, v));
        }

        public override string to_string() {return text == null ? "" : text;}
        public override int to_int(out bool is_length = null) {
            is_length = true; return data.size;
        }
    }

    public class Stack : Data {
        Data first;
        Data last;
        public Stack(Data first, Data last) {
            this.first = first; this.last = last;
        }

        public Stack.with_map(Data fallback, Gee.Map<Bytes, Data> top) {
            this(new Mapping(top), fallback);
        }

        public override Data get(Bytes property) {
            var val = first[property];
            if (val is Empty) return last[property];
            else return val;
        }

        public override string to_string() {return "";}
        public override bool exists {get {return first.exists || last.exists;}}

        public override void foreach_map(Data.ForeachMap cb) {
            var exit = false;
            first.foreach_map((key, val) => {
                return exit = cb(key, val);
            });
            if (exit) return;
            last.foreach_map(cb);
        }

        public override int to_int(out bool is_length = null) {
            warning("Trying to convert a stack to an int. " +
                    "This may not give the results you expect.");
            is_length = true; // Won't get a better answer...
            return 0;
        }
    }

    public class Lazy : Data {
        Data ctx;
        Gee.Map<Bytes,Variable> vars;
        Gee.Map<Bytes,Data> evaluated;
        public Lazy(Gee.Map<Bytes,Variable> variables, Data context) {
            this.ctx = context;
            this.vars = variables;
            this.evaluated = ByteUtils.create_map<Data>();
        }

        public override Data get(Bytes property) {
            if (evaluated.has_key(property)) return evaluated[property];
            if (vars.has_key(property)) {
                evaluated[property] = vars[property].eval(ctx);
                return evaluated[property];
            }
            return ctx[property];
        }

        public override string to_string() {return "";}
        public override bool exists {get {return true;}}
        public override int to_int(out bool is_length = null) {
            is_length = true; // Won't get a better answer...
            return 0;
        }

        public override void @foreach(Data.Foreach cb) {
            var lazy_keys = vars.keys;
            lazy_keys.add_all(evaluated.keys);

            var exit = false;
            ctx.@foreach((key) => {
                if (key in lazy_keys) return false;
                return exit = cb(key);
            });
            if (exit) return;

            foreach (var key in lazy_keys)
                if (cb(key)) break;
        }
    }
}
