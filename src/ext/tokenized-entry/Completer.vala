namespace Tokenized {
    public abstract class CompleterDelegate : Object {
        public abstract void autocomplete(string query, Completer completer);
    }

    public class Completion : Object {
        public string val {get; set;}
        public string label {get; set;}
        public bool is_token;

        public Completion(string val, string label) {
            this.val = val;
            this.label = label;
            this.is_token = false;
        }
        public Completion.token(string val, string label) {
            this.val = val;
            this.label = label;
            this.is_token = true;
        }
    }

    public class Completer : Object {
        public ListStore model = new ListStore(typeof(Completion));
        private Gee.List<CompleterDelegate> delegates = new Gee.ArrayList<CompleterDelegate>();
        private Gee.Set<string> seen = new Gee.HashSet<string>();

        public void add_type(Type type) {
            var completer = Object.@new(type) as CompleterDelegate;
            if (completer != null) delegates.add(completer);
        }

        public void add(CompleterDelegate completer) {
            delegates.add(completer);
        }

        public delegate void YieldCallback(Completion completion);
        private YieldCallback yieldCallback;
        public void suggest(string query, owned YieldCallback cb) {
            this.yieldCallback = cb;
            seen.clear();

            foreach (var completer in delegates) {
                completer.autocomplete(query, this);
            }
        }

        public void @yield(Completion completion) {
            if (completion.val in seen) return;
            seen.add(completion.val);

            yieldCallback(completion);
        }

        public void suggestion(string val, string? label = null) {
            @yield(new Completion(val, label == null ? val : label));
        }
        public void token(string val, string? label = null) {
            @yield(new Completion.token(val, label == null ? val : label));
        }
    }

    public class CompleterFactory : Object {
        private Gee.List<Type> delegate_classes = new Gee.ArrayList<Type>();

        public void register(Type completer) {
            delegate_classes.add(completer);
        }

        public Completer build() {
            var ret = new Completer();
            foreach (var source in delegate_classes) ret.add_type(source);
            return ret;
        }
    }
}
