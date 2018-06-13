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

/** Topdown Operator Precedance-based parser for if-tags.
    See http://effbot.org/zone/simple-top-down-parsing.htm,
    though ofcourse I couldn't use all the same syntactic sugar.

Primarily this syntax is currently just used in the database initialization script. */
namespace Odysseus.Templating.Expression {
    /* Infrastructure/Public interface */
    public enum TypePreference {BOOL, NUMBER}
    public abstract class Expression : Object {
        public Expression left;
        public Expression right;
        // Shorthands for eval implementations.
        public Expression x {get {return left;}}
        public Expression y {get {return right;}}

        /* Parsing */
        public abstract int lbp {get;} // Left Binding Power
        public abstract string name {get;}
        public Parser parser;
        public int index;
        public virtual Expression nud() throws SyntaxError {
            throw new SyntaxError.INVALID_ARGS(
                    "[Argument #%i] Expected 'not' or some value, not '%s'.",
                    index, name);
        }

        public virtual Expression led(Expression left) throws SyntaxError {
            throw new SyntaxError.INVALID_ARGS(
                    "[Argument #%i] Expected an infix operator, not '%s'.",
                    index, name);
        }

        public virtual bool eval(Data.Data ctx) {return num(ctx) != 0.0;}
        public virtual double num(Data.Data ctx) {
            return eval(ctx) ? 1.0 : 0.0;
        }
    }

    public abstract class Infix : Expression {
        public override Expression led(Expression left) throws SyntaxError {
            this.left = left;
            this.right = parser.expression(lbp);
            return this;
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
                if (arg.length >= 1) packed |= arg[0];
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
                if (arg.length >= 5) packed = 0; // Flag for couldn't fit

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
                else if (packed == 0x3D3D || packed == 0x3D) /* "==", "=" */
                    token = new EqualTo();
                else if (packed == 0x213D) /* "!=" */
                    token = new NotEqual();
                else if (packed == 0x25) /* "%" */
                    token = new Remainder();
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

        public override bool eval(Data.Data d) {return false;}
    }

    private class Or : Infix {
        public override int lbp {get {return 10;}}
        public override string name {get {return "or";}}

        public override bool eval(Data.Data d) {return x.eval(d) || y.eval(d);}
    }

    private class And : Infix {
        public override int lbp {get {return 20;}}
        public override string name {get {return "and";}}

        public override bool eval(Data.Data d) {return x.eval(d) && y.eval(d);}
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

        public override bool eval(Data.Data d) {return !x.eval(d);}
    }

    private class LessThan : Infix {
        public override int lbp {get {return 40;}}
        public override string name {get {return "<";}}

        public override bool eval(Data.Data d) {return x.num(d) < y.num(d);}
    }

    private class GreaterThan : Infix {
        public override int lbp {get {return 40;}}
        public override string name {get {return ">";}}

        public override bool eval(Data.Data d) {return x.num(d) > y.num(d);}
    }

    private class LessEqual : Infix {
        public override int lbp {get {return 40;}}
        public override string name {get {return "<=";}}

        public override bool eval(Data.Data d) {return x.num(d) <= y.num(d);}
    }

    private class GreaterEqual : Infix {
        public override int lbp {get {return 40;}}
        public override string name {get {return ">=";}}

        public override bool eval(Data.Data d) {return x.num(d) >= y.num(d);}
    }

    private class EqualTo : Infix {
        public override int lbp {get {return 40;}}
        public override string name {get {return "==";}}

        public override bool eval(Data.Data d) {return x.num(d) == y.num(d);}
    }

    private class NotEqual : Infix {
        public override int lbp {get {return 40;}}
        public override string name {get {return "!=";}}

        public override bool eval(Data.Data d) {return x.num(d) != y.num(d);}
    }

    private class Remainder : Infix {
        public override int lbp {get {return 50;}}
        public override string name {get {return "%";}}

        public override double num(Data.Data d) {
            var a = (int) x.num(d); var b = (int) y.num(d);
            return (double) (a % b);
        }
    }

    private class Value : Expression {
        public Variable exp;
        public Value(Slice source) throws SyntaxError {
            this.exp = new Variable(source);
        }

        public override int lbp {get {return 200;}}
        public override string name {get {return "[variable]";}}
        public override Expression nud() {return this;}

        public override bool eval(Data.Data d) {return exp.eval(d).exists;}
        public override double num(Data.Data d) {return exp.eval(d).to_double();}
    }
}
