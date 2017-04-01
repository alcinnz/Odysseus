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

/** Topdown Operator Precedance-based parser for if-tags.
    See http://effbot.org/zone/simple-top-down-parsing.htm,
    though ofcourse I couldn't use all the same syntactic sugar. */
namespace Oddysseus.Templating.Expression {
    /* Infrastructure/Public interface */
    public enum TypePreference {BOOL, NUMBER}
    public abstract class Expression : Object {
        public Expression left;
        public Expression right;

        /* Parsing */
        public abstract int lbp {get;} // Left Binding Power
        public abstract string name {get;}
        public Parser parser;
        public int index;
        public virtual Expression nud() throws SyntaxError {
            throw new SyntaxError.INVALID_ARGS(
                "[Argument #%i] Expected 'not', '(', or some value, not '%s'.",
                index, name);
        }

        public virtual Expression led(Expression left) throws SyntaxError {
            throw new SyntaxError.INVALID_ARGS(
                "[Argument #%i] Expected an infix operator, not '%s'.",
                index, name);
        }

        /* Evaluation */
        public Data.Data context;
        public double x {
            get {return left.eval_type(preference, context);}
        }
        public double y {
            get {return right.eval_type(preference, context);}
        }
        public bool a {get {return x != 0;}}
        public bool b {get {return y != 0;}}
        public virtual TypePreference preference {
            get {return TypePreference.BOOL;}
        }

        // One of these two methods must be implemented.
        public virtual double eval_type(TypePreference type, Data.Data ctx) {
            context = ctx;
            return eval();
        }
        public virtual double eval() {
            return 0.0;
        }
    }

    public abstract class Infix : Expression {
        public override Expression led(Expression left) throws SyntaxError {
            this.left = left;
            this.right = parser.expression(lbp);
            return this;
        }
    }

    public abstract class NumericExpression : Infix {
        public override TypePreference preference {
            get {return TypePreference.NUMBER;}
        }
    }

    public class Parser {
        public Expression token;
        WordIter args;
        EndToken eol;
        int index;
        
        public Parser(WordIter args) throws SyntaxError {
            this.args = args;

            this.token = null;
            this.index = 0;
            this.eol = new EndToken();
            token = next();
        }

        public Expression next() throws SyntaxError {
            //var t = token;
            Expression token;
            var arg = args.next_value();
            if (arg == null) token = eol;
            else {
                // Micro-optimization on operator name comparison
                //      Ensures it's loaded into a CPU register
                //      (up to 4 ASCII chars).
                uint32 packed = 0;
                if (arg.length == 0)
                    throw new SyntaxError.INVALID_ARGS(
                            "Somehow got nil argument at index %i.", index);
                if (arg.length >= 1) {
                    packed |= arg[0];
                }
                if (arg.length >= 2) {
                    packed <<= 8;
                    packed |= arg[1];
                }
                if (arg.length >= 3) {
                    packed <<= 8;
                    packed |= arg[2];
                }
                if (arg.length >= 4) {
                    packed <<= 8;
                    packed |= arg[3];
                }
                if (arg.length >= 5) {
                    packed = 0; // Flag for couldn't fit
                }

                // Now comparisons are done by matching the ASCII hexcode.
                if (packed == 0x6F72) /* "or" */
                    token = new Or();
                else if (packed == 0x616E64) /* and */
                    token = new And();
                else if (packed == 0x6E6F74) /* "not" */
                    token = new Not();
                else if (packed == 0x3C) /* "<" */
                    token = new LessThan();
                else if (packed == 0x3E) /* ">" */
                    token = new GreaterThan();
                else if (packed == 0x3C3D) /* "<=" */
                    token = new LessEqual();
                else if (packed == 0x3E3D) /* ">=" */
                    token = new GreaterEqual();
                else if (packed == 0x3D3D) /* "==" */
                    token = new EqualTo();
                else if (packed == 0x213D) /* "!=" */
                    token = new NotEqual();
                else if (packed == 0x696E) /* "in" */
                    token = new In();
                else if (packed == 0x25) /* "%" */
                    token = new Modulo();
                else if (packed == 0x6966) /* "if" */
                    token = new Ternary();
                else if (packed == 0x656C7365) /* "else" */
                    token = new TernaryElse();
                else if (packed == 0x28) /* "(" */
                    token = new Parenthesized();
                else if (packed == 0x29) /* ")" */
                    token = new CloseParen();
                else
                    token = new Value(arg);
            }

            token.parser = this;
            token.index = index++;

            return token;
        }

        public Expression expression(int rbp = 0) throws SyntaxError {
            var t = token;
            token = next();
            var left = t.nud();
            while (rbp < token.lbp) {
                t = token;
                token = next();
                left = t.led(left);
            }
            return left;
        }

        public void advance(string expected) throws SyntaxError {
            if (token.name != expected)
                throw new SyntaxError.INVALID_ARGS("Expected '%s' at index %i", expected, token.index);
            token = next();
        }
    }

    /* Token implementation */
    public class EndToken : Expression {
        public override int lbp {get {return 0;}}
        public override string name {get {return "[EOL]";}}
    }

    private class Or : Infix {
        public override int lbp {get {return 10;}}
        public override string name {get {return "or";}}

        public override double eval() {return a || b ? 1 : 0;}
    }

    private class And : Infix {
        public override int lbp {get {return 20;}}
        public override string name {get {return "and";}}

        public override double eval() {return a && b ? 1 : 0;}
    }

    private class Not : Expression {
        public override int lbp {get {return 30;}}
        public override string name {get {return "not";}}

        public override Expression nud() throws SyntaxError {
            left = parser.expression(lbp);
            return this;
        }

        public override Expression led(Expression left) throws SyntaxError {
            var t = parser.token;
            parser.token = parser.next();
            this.left = t.led(left);
            return this;
        }

        public override double eval() {return !a ? 1 : 0;}
    }

    private class LessThan : NumericExpression {
        public override int lbp {get {return 40;}}
        public override string name {get {return "<";}}

        public override double eval() {return x < y ? 1 : 0;}
    }

    private class GreaterThan : NumericExpression {
        public override int lbp {get {return 40;}}
        public override string name {get {return ">";}}

        public override double eval() {return x > y ? 1 : 0;}
    }

    private class LessEqual : NumericExpression {
        public override int lbp {get {return 40;}}
        public override string name {get {return "<=";}}

        public override double eval() {return x <= y ? 1 : 0;}
    }

    private class GreaterEqual : NumericExpression {
        public override int lbp {get {return 40;}}
        public override string name {get {return ">=";}}

        public override double eval() {return x >= y ? 1 : 0;}
    }

    private class EqualTo : NumericExpression {
        public override int lbp {get {return 40;}}
        public override string name {get {return "==";}}

        public override double eval() {return x == y ? 1 : 0;}
    }

    private class NotEqual : NumericExpression {
        public override int lbp {get {return 40;}}
        public override string name {get {return "!=";}}

        public override double eval() {return x != y ? 1 : 0;}
    }

    private class In : Infix {
        public override int lbp {get {return 40;}}
        public override string name {get {return "in";}}

        public override double eval() {
            Data.Data haystack;
            if (right is Value)
                haystack = (right as Value).exp.eval(context);
            else return 0;
            string needle;
            if (left is Value)
                needle = (left as Value).exp.eval(context).to_string();
            else return 0;

            // For textual data:
            if (haystack.to_string() != "")
                return needle in haystack.to_string() ? 1 : 0;

            // For object data:
            var has_key = false;
            var needle_bytes = ByteUtils.from_string(needle);
            var search_indices = needle[0] == '$';
            haystack.foreach_map((key, val) => {
                if (!search_indices && key.length > 1 && key[0] == '$') {
                    // This is an array index key
                    has_key = val.to_bytes().compare(needle_bytes) == 0;
                } else has_key = key.compare(needle_bytes) == 0;
                return has_key;
            });
            return has_key ? 1 : 0;
        }
    }

    private class Value : Expression {
        public Variable exp;
        public Value(Bytes source) throws SyntaxError {
            this.exp = new Variable(source);
        }

        public override int lbp {get {return 200;}}
        public override string name {get {return "[variable]";}}

        public override Expression nud() {
            return this;
        }

        public override double eval_type(TypePreference type, Data.Data ctx) {
            var val = exp.eval(ctx);
            if (type == TypePreference.BOOL)
                return val.exists ? 1 : 0;
            else return val.to_double();
        }
    }

    // The following are largely only useful for use in plural forms, but other templates may use it
    private class Modulo : Infix {
        public override int lbp {get {return 120;}}
        public override string name {get {return "%";}}
        // Vala doesn't link to the appropriate libraries to implement fmod,
        // So implement it ourselves, hoping that GCC optimizes this to the CPU's modulo instruction where it exists.
        public override double eval() {return x - (x/y)*y;}
    }

    private class Ternary : Expression {
        public override int lbp {get {return 5;}}
        public override string name {get {return "if";}}
        public override Expression led(Expression left) throws SyntaxError {
            this.right = parser.expression(lbp);
            if (this.right.name != "else") throw new SyntaxError.INVALID_ARGS("Expected 'else' operator not found");
            this.left = this.right.left;
            this.right.left = left;
            return this;
        }

        public override double eval() {return a ? right.x : right.y;}
    }
    private class TernaryElse : Infix {
        public override int lbp {get {return 6;}}
        public override string name {get {return "else";}}
    }

    private class Parenthesized : Expression {
        public override int lbp {get {return 150;}}
        public override string name {get {return "(";}}
        public override Expression nud() throws SyntaxError {
            var expr = parser.expression();
            parser.advance(")");
            return expr;
        }
    }
    private class CloseParen : Expression {
        public override int lbp {get {return 0;}}
        public override string name {get {return ")";}}
    }
}
