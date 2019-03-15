# Nani!?

A toy language with way to many features. Highlights:

 - Full dependent types
 - Row types and row polymorphism
 - Minimal syntax
 - REPL

## Examples

### Hello world

```nani
io.printLn "Hello World!"
```

### Fibonacci

```nani
ctl.fix \fib n .
  if (n < 2)
     n
     (fib (n - 1) + fib (n - 2))
```

### Guessing game

```nani
\secret . let rec {
  guess : IO Int = do {
    io.printLn "Enter your guess:"
    str <- io.getLn
    (case (str :parse Int)
      :none do { io.printLn "Please enter a valid integer"; guess }
      :some done
    )
  }

  attempt : Int -> IO Int = \i . do {
    g <- guess i
    (case (g :compare secret)
      <  do { io.printLn "Too low!"; attempt (i+1) }
      == do { io.printLn "You win after #{i} attempts!"; done i }
      >  do { io.printLn "Too high!"; attempt (i+1)}
    )
  }
} in round 1
```

## Syntax

### Comments

Line comments begin with `//` (note the space!). Block comments
begin with `//(` and end with `)//`.

### Expressions

The basic syntactic unit of nani!? is an expression. Expressions
always evaluate to a value. For example, `1 + 2` is an expression
which evaluates to the integer `3`; `\x . x` evaluates to a function
which takes an input and returns it unchanged.

Nani!? is a typed language; every expression has a type which constrains
possible values. Types can be given explicitly using type annotations,
written using `:`. Examples: `3 : Int`, `(\x . x) : ∀a. a -> a`.

More rigorously, here is an exhaustive list of possible expressions,
their meanings and typing rules:

 - `foo`, where `foo` is a valid identifier (see below). It evaluates to
   - denotes the value of the variable `foo`; if no such variable is in scope, the program
     will be rejected.
 - `e : t` type annotation where `e` and `t` are valid expressions.
    - denotes the same as `e`
    - `t : Type`, and
    - `e : t'` such that `t'` can unify with `t`.
 - `f x` function application, where `f` and `x` are valid expressions.
    - denotes the result of applying `f` to `x`
    - `f : t1 -> t2`
    - `x : t1`
    - => `f x : t2`
 - `\i . e` lambda abstraction.
    - `e : t` given `i : t'`
    - => `(\i . e) : t' -> t`
 - `let mod in e`: local bindings / imports. It evaluates to `e` with the scope augmented
   by the key-value pairs in `mod`.
    - `mod : Rec kvs`
    - `e : t` given bindings from `mod`
    - `let mod in e : t`
 - `rec mod`: knot-tying / recursion. In combination with `let` and record literals,
   this recovers the `let rec` syntax that may be familiar from other languages.
    - `mod : Rec kvs` given types from `kvs`
    - => `rec mod : Rec kvs`
 - `f @` visibility override: allow specifying a normally-implicit function argument
   (including a type)
    - `f : ∀(a : k). t`
    - => `f @ : (a : k) -> t`
 - `_` infer: tell the nani!? compiler to infer a value/type. The program will be rejected
   if the type of `_` is anything other than `Type` or `Constraint`, or if the value cannot
   be inferred.
 - `t -> t'` the type of functions taking a `t` argument and returning `t'`.
   - `t : Type`
   - `t' : Type`
   - => `t -> t' : Type`
 - `∀v. t` a forall-type
 - `c => t` a constrained type, e.g. `Show a => a`.
   - `c : Constraint`
   - `t : Type`
   - => `c => t : Type`
 - Literals come in several forms:
    - Integers: Several consecutive digits, denoting an integer. Hexadecimal,
      octal and binary are also supported. Underscores can be used to group numbers for
      legibility.
      - `123 : ∀a . FromInt a => a`. Note: if `123` cannot be converted to `a`, the program
        will be rejected.
    - Fractional numbers: The usual floating-point notation. As with integers, hexadecimal,
      octal, binary, and underscores for spacing are also supported. Additionally, fractions
      are supported, which take the form `x/y` where `x` and `y` are integers.
      - `2.5 : ∀a . FromFrac a => a`. Note: if `2.5` cannot be converted to `a`, the program
        will be rejected.
      - `2/3 : ∀a . FromFrac a => a`. Note: if `2/3` cannot be converted to `a`, the program
        will be rejected.
    - Characters: a single character or escape sequence enclosed in single quotes.
      - `'a' : Char`
    - Strings: a sequence of characters or escape sequences, enclosed in double quotes. Supports
      interpolation using `#{expr}`, where `expr` is a valid expression that can be converted to
      a string.
      - `e : t`
      - => `"hello #{e}" : ToString t => String`
    - Labels: a leading `:` followed by any number of non-whitespace characters other than `()`.
      The leading `:` may be omitted if the atom consists solely of punctuation and does not
      clash with built-in syntax. Their value is reflected in their type.
      - `:foo : Label :foo`
    - Arrays: any number of values, enclosed in `[` brackets `]` and separated by
      whitespace. The values must all have the same type.
      - `x_i : t` for all i
      - => `[x_1 ... x_n] : Arr t`
    - Tuples: any number of values, enclosed in `[!` `]` and separated by whitespace.
      The values may have different types.
      - `x_i : t_i` for all i
      - => `[! x_1 ... x_n] : HArr [t_1 ... t_n]`
    - Ordered maps: any number of key-value pairs, enclosed in `[:` `]` and separated by whitespace.
      The keys must be labels, the values may have different types.

      Alternatively, ordered maps may be written enclosed in `[` brackets `]` and using
      `key = value` syntax.
      - `k_i : Label k_i` for all i
      - `v_i : t_i` for all i
      - => `[: k_1 v_1 ... k_n v_n] : Map [: k_1 t_1 ... k_n v_n ]`
    - Homogenous sets: any number of values, enclosed in `{` braces `}` and separated by whitespace.
      Repeats are allowed, but only the first occurence will be kept. Elements must all have the
      same type and must be comparable
      for equality; if they are not, the program is rejected.
      - `x_i : t` for all i
      - => `{ x_1 ... x_n } : Eq t => Set t`
    - Heterogenous sets: any number of values, enclosed in `{!` `}` and sepatated by whitespace.
      Elements may have distinct types; if two elements have the same type, only the first is kept.
      - `x_i : t_i` for all i
      - => `{! x_1 ... x_n } : HSet { t_1 ... t_n }`
    - Records (aka "modules"): any number of key-value pairs, enclosed in `{:` `}` and separated by
      whitespace. The keys must be labels, and if any two are the same only the first is kept.

      Alternatively, records may be written enclosed in `{` braces `}` and using `key = value`
      syntax.
      - `k_i : Label k_i` for all i
      - `v_i : t_i` for all i
      - => `{: k_1 v_1 ... k_n v_n } : Rec {: k_1 t_1 ... k_n v_n }`