# Oxynium Documentation Plan

Each section below is a specification for one documentation page. The goal is that a writer with
no access to the compiler source can produce accurate, complete documentation solely from this
plan. Every page should open with a one-paragraph definition, use the examples shown verbatim,
and call out every error condition by its exact error type name.

---

## Proposed file structure

```
docs/
  getting-started.md
  language/
    comments.md
    variables.md
    types.md
    operators.md
    control-flow.md
    functions.md
    classes.md
    generics.md
    typeof.md
    program-structure.md
  std/
    overview.md
    int.md
    bool.md
    char.md
    str.md
    list.md
    option.md
    result.md
    range.md
    utf8str.md
    ptr.md
    io.md
  advanced/
    inline-assembly.md
    unchecked-cast.md
    extern.md
  examples/
    euler.md
    patterns.md
```

---

## Page specifications

---

### `getting-started.md` — Getting Started

**Purpose:** First contact. A reader with no prior knowledge of Oxynium should be able to compile
and run a program by the end of this page.

#### What Oxynium is

Oxynium is a statically-typed, compiled language. It compiles directly to x86-64 NASM assembly,
which is then assembled and linked by GCC to produce a native binary. It targets Linux x86-64
and macOS x86-64.

The compilation pipeline is:

```
source.oxy
  → Lexer (tokens)
  → Parser (AST)
  → Type Checker
  → Code Generator (NASM assembly)
  → Post-processor
  → NASM assembler
  → GCC linker
  → native binary
```

#### Compiling and running

Show the compiler invocation. When installed, the compiler binary is `oxy` (building from
source with Cargo produces `target/release/oxynium`, which is the same program). Basic usage:

```
oxy hello.oxy
./oxy-out
```

This produces an executable named `oxy-out` in the current directory. The page should document
the flags the compiler accepts: `-o`/`--out` (output executable path, default `oxy-out`),
`-e`/`--eval` (pass the program source on the command line), `-k`/`--keep` (keep the generated
`<out>.asm` and `<out>.o` files), `-t`/`--target` (`x86_64-linux` or `macos`, default: the current
system), `-O`/`--optimise` (`0` or `1`, default `1`), `-E`/`--enable` and `-D`/`--disable`
(toggle individual optimisations), `-v`/`--version`, and `--stop_after_asm`.

Note that `print` writes strings in Oxynium's internal UTF-64 representation, so every
character on stdout is padded with NUL bytes (seven of them after each ASCII character). A
terminal hides them, but they are visible when output is piped to a file or another program.

#### Hello, World

The simplest possible program — a single top-level statement:

```
print("Hello, world!")
```

Output:
```
Hello, world!
```

With a `main` function (used when the program grows beyond a single file's top-level):

```
def main() {
    print("Hello, world!")
}
```

Explain that when `main` is defined, no executable statements may appear outside of it. This is
covered fully in `program-structure.md`.

#### Accepting command-line arguments

```
def main(args: List<Utf8Str>) {
    print(args.len().Str())
    for arg in args {
        print(arg.Str())
    }
}
```

`args` includes the binary name as the first element, so a program run with no user arguments
has `args.len()` equal to `1`. `Utf8Str` is the raw OS string type; call `.Str()` to convert it
to the standard `Str` type before string operations.

#### Error types

The compiler emits one of the following error kinds. The documentation should explain each
briefly so users know what to expect when they make mistakes:

| Error kind        | When it occurs |
|-------------------|----------------|
| `SyntaxError`     | The source text cannot be parsed |
| `TypeError`       | A type rule is violated |
| `UnknownSymbol`   | A name is used that has not been declared |
| `IoError`         | Assembling or linking fails, e.g. a called `extern def` has no definition |
| `NumericOverflow` | An integer literal exceeds the 64-bit signed range |

---

### `language/comments.md` — Comments

**Purpose:** Reference for comment syntax.

#### Single-line comments

A comment begins with `//` and runs to the end of the line. Everything after `//` is ignored by
the compiler.

```
// This entire line is a comment.
print("hi")  // This is an inline comment.
```

#### No block comments

There is no multi-line or block comment syntax. Use multiple `//` lines.

#### Doc comments

The standard library uses `///` for documentation annotations. In user code, `///` behaves
identically to `//` — it is a comment with no special compiler treatment.

```
/// Returns the square of n.
def square(n: Int) Int -> n * n
```

---

### `language/variables.md` — Variables and Constants

**Purpose:** Complete reference for declaring, annotating, initialising, mutating, and scoping
values.

#### Global constants (`const`)

Declared at the top level of a file (not inside any function). Always require an initial value,
which must be a single non-negative integer literal or a string literal — any other value
(`-1`, `true`, `BASE * 5`, a function call) is a `SyntaxError`. Type is inferred from the value.
Cannot be mutated.

```
const MAX = 100
const GREETING = "Hello"
const PI_APPROX = 314
```

Attempting to redeclare a constant with the same name is a `TypeError`.

```
const a = 1
const a = 2    // TypeError: duplicate declaration
```

Constants may not be declared inside a function — this is a `SyntaxError`.

```
def f() {
    const x = 1    // SyntaxError
}
```

Constants cannot be computed from expressions, including expressions involving other constants:

```
const BASE = 10
const LIMIT = BASE * 5   // SyntaxError: can only have integers or strings as global constants
const NEG = -1           // SyntaxError
const FLAG = true        // SyntaxError
```

#### Local variables (`let`)

Declared inside a function body. Immutable by default — the variable cannot be reassigned after
its initial binding.

```
def main() {
    let x = 42
    let name = "Alice"
    let greeting = "Hello, " + name
}
```

Type annotation is optional. When provided it must match the inferred type:

```
def main() {
    let x: Int = 42      // valid
    let y: Int = ""      // TypeError: mismatched types
}
```

Variables cannot be declared without an initial value unless they are `mut` (see below):

```
def f() {
    let a;        // SyntaxError: missing value
    let a: Int;   // SyntaxError: non-mut declaration without value
}
```

Redeclaring the same name in the same function is a `TypeError`. There is no shadowing:

```
def f() {
    let a = 1
    let a = 2    // TypeError: duplicate declaration
}
```

Declaring a `let` at the top level (outside a function) is a `SyntaxError`, **even in script
mode** (a file with no `main`). Use `const` for top-level values, or put the code in a function:

```
let a = 1    // SyntaxError: local variable at top level
```

#### Mutable local variables (`let mut`)

Allows reassignment after initial binding. The type is fixed at declaration and cannot change.

```
def main() {
    let mut count = 0
    count = count + 1
    count = 99
}
```

Assigning a different type is a `TypeError`:

```
def main() {
    let mut a = 1
    a = ""    // TypeError: cannot assign Str to Int
}
```

#### Empty `let mut` declarations

`let mut` may be declared with a type annotation but no value. The variable must be assigned
before it is read — reading an uninitialised variable is a `TypeError`.

> **Known issue:** a variable declared this way currently reads back incorrectly when it is
> passed as a function argument or used as a method receiver (e.g. `print(a.Str())` prints a
> garbage number such as `4224464` instead of `4`). Reading it with `return a` or in arithmetic
> (`a + 0`) works. Until this is fixed, prefer giving the variable an initial value
> (`let mut a = 0`).

```
def f(condition: Bool) Int {
    let mut result: Int
    if condition {
        result = 1
    } else {
        result = 2
    }
    return result    // valid: both branches assign
}
```

```
def f() Int {
    let mut a: Int
    return a    // TypeError: used before assignment
}
```

An immutable `let` cannot use the empty declaration form — a value is always required:

```
def f() {
    let a: Int    // SyntaxError: immutable let requires initial value
}
```

#### Compound assignment operators

These are shorthand for `variable = variable OP value`. The variable must be `mut`.

| Operator | Example      | Equivalent      |
|----------|--------------|-----------------|
| `+=`     | `a += 3`     | `a = a + 3`     |
| `-=`     | `a -= 3`     | `a = a - 3`     |
| `*=`     | `a *= 3`     | `a = a * 3`     |
| `/=`     | `a /= 3`     | `a = a / 3`     |
| `%=`     | `a %= 3`     | `a = a % 3`     |

```
def main() {
    let mut a = 1
    a += 1    // 2
    a -= 1    // 1
    a *= 4    // 4
    a /= 2    // 2
    a += 1
    a %= 2    // 1
    print(a.Str())
}
```

Compound assignment on an immutable variable is a `TypeError`. Compound assignment with a
mismatched type is also a `TypeError`:

```
def main() {
    let mut a = 1
    a += ""    // TypeError: cannot add Str to Int
}
```

`+=` also works on `Str` variables (string concatenation):

```
def main() {
    let mut s = "hello"
    s += " world"
    print(s)    // hello world
}
```

Applying `-=` or other arithmetic operators to a `Str` variable is a `TypeError`.

#### Scoping rules

Oxynium does **not** have block-level scoping for variables. A variable declared inside an `if`,
`while`, or `for` block is accessible in the enclosing function after that block. However, a
variable from an outer scope cannot be redeclared inside an inner block — this is a `TypeError`:

```
def main() {
    let a = 1
    if true {
        let a = 2    // TypeError: duplicate declaration
    }
}
```

Empty `mut` declarations work fine with block assignments:

```
def main() {
    let mut a: Int
    if true {
        a = 2
    } else {
        a = 3
    }
    a = 4    // valid
}
```

For-loop variables persist after the loop ends. The element variable holds the last element,
but the index variable holds the number of iterations (one past the last index):

```
def main() {
    for c, i in "abc" {}
    // c = 'c', i = 3
    print(i.Str() + c.Str())    // 3c
}
```

Because loop variables live in the enclosing function's scope, the same loop variable name
cannot be used by two `for` loops in one function — the second loop is a `TypeError`
(`symbol 'i' is already declared`):

```
def main() {
    for i in range(2) {}
    for i in range(2) {}    // TypeError
}
```

#### Invalid variable names

The following are always `SyntaxError`:
- Names starting with a digit: `1a`
- Names containing `_$_`: `_$_foo`
- Reserved keywords used as names: `let`, `mut`, `def`, `const`, `class`, `while`, `for`,
  `if`, `else`, `return`, `break`, `continue`, `true`, `false`, `new`, `extern`,
  `typeof`, `primitive`

(`fn` is not reserved as a variable name: `let fn = 1` compiles.)

#### Immutability of non-`mut` variables vs. field mutation

The `let` / `let mut` distinction controls whether the *variable binding itself* can be
reassigned. Fields on a class instance can be mutated through a non-`mut` variable:

```
class Point { x: Int, y: Int }

def main() {
    let p = new Point { x: 0, y: 0 }
    p.x = 5    // valid: mutating a field, not reassigning p
}
```

---

### `language/types.md` — The Type System

**Purpose:** Explain every built-in type, type annotations, type inference, generic types, the
optional shorthand, and function types.

#### Built-in primitive types

`Int`, `Bool` and `Char` are implemented as `primitive` classes in the standard library; `Str`
is an ordinary `class` whose methods operate on its raw representation, and `Void` is built in.

| Type   | Description                      | Default value (`new T`) | Size    |
|--------|----------------------------------|-------------------------|---------|
| `Int`  | 64-bit signed integer            | `0`                     | 8 bytes |
| `Bool` | Boolean                          | `false`                 | 8 bytes |
| `Char` | Single Unicode character         | null char (code 0)      | 8 bytes |
| `Str`  | Immutable character string       | `""` (empty)            | pointer |
| `Void` | Unit / no value                  | —                       | —       |

`Void` is the return type of functions that produce no value. It cannot be meaningfully operated
on. `new Void` is a valid expression (used in low-level code) but has no useful value.

#### Literals

```
42          // Int
-7          // unary minus applied to Int 7
true        // Bool
false       // Bool
'a'         // Char
'\n'        // Char — newline
"hello"     // Str
""          // Str — empty string
```

#### Type annotations

Annotations appear after the identifier, separated by `:`.

```
def f(a: Int, b: Bool) Str {
    let x: Int = 5
    let s: Str = "hello"
    return s
}
```

#### Type inference

The compiler infers types when they can be determined from context. Parameter types are **never**
inferred — they must always be explicit. Return types can be inferred for single-expression
(`->`) functions.

```
def square(n: Int) -> n * n   // return type inferred: Int

def main() {
    let x = 42               // inferred: Int
    let s = "hi"             // inferred: Str
}
```

Variables on the left side of an assignment inherit the type of the right side. Once fixed, the
type cannot change.

#### Using a variable before it is declared is a TypeError

```
def f() Int {
    let b = a    // TypeError: a not yet declared
    let a = 5
    return b
}
```

#### Redeclaring a built-in type name is a TypeError

```
class Str;    // TypeError: Str is a built-in type
class Int;    // TypeError
primitive Str; // TypeError
```

#### Generic types

Parameterised with angle brackets. The standard library provides `List<T>`, `Option<T>`,
`Result<T, E>`, `Ptr<T>`, and `Range`.

```
List<Int>
Option<Str>
Result<Int, Str>
Ptr<Bool>
```

Nesting is allowed:

```
List<Option<Int>>
Option<List<Str>>
Result<Option<Int>, Str>
```

#### Optional shorthand

`T?` is syntactic sugar for `Option<T>`. Multiple `?` can be chained:

```
def main() {
    let mut a: Int?        // Option<Int>
    let mut b: Int??       // Option<Option<Int>>
    let mut c: Str?        // Option<Str>
}
```

(Declarations without a value need `let mut`; `let a: Int?` alone is a `SyntaxError`.)

`Option` is a standard library class, so a user-defined top-level class named `Option` is a
`TypeError` (redeclaration).

#### Function types

Written as `Fn(Param1, Param2, ...) ReturnType`. Used as parameter or variable types.

```
def apply(f: Fn(Int) Int) Int { return f(5) }
def run(f: Fn() Void) { f() }
def combine(f: Fn(Int, Str) Bool) { ... }
```

Generic function types are **not** permitted in type positions — `Fn<T>(T) T` is a `SyntaxError`.

#### The `typeof` operator

`typeof expr` evaluates to a `Str` naming the compile-time type of the expression. See the
dedicated `typeof.md` page.

---

### `language/operators.md` — Operators

**Purpose:** Complete reference for every operator, its types, its precedence, and the rules for
operator overloading.

#### Arithmetic operators

All arithmetic operators work on `Int` operands and return `Int`. Mixing types (e.g. `Int + Str`)
is a `TypeError`.

| Operator | Description          | Example             | Result |
|----------|----------------------|---------------------|--------|
| `+`      | Addition             | `3 + 4`             | `7`    |
| `-`      | Subtraction          | `10 - 3`            | `7`    |
| `*`      | Multiplication       | `3 * 4`             | `12`   |
| `/`      | Integer division     | `7 / 2`             | `3`    |
| `%`      | Modulo               | `7 % 2`             | `1`    |

Integer division truncates toward zero. Division by the integer literal `0` is a compile-time
`TypeError`. Modulo by the literal `0` is **not** caught at compile time. Division or modulo by
zero at runtime crashes the program with a floating-point exception (SIGFPE).

```
print((7 / 2).Str())    // 3  (not 3.5)
print((7 % 2).Str())    // 1
print((1 / 0).Str())    // TypeError at compile time
print((1 % 0).Str())    // compiles; crashes at runtime
```

Operator precedence follows standard mathematical convention:
- `*`, `/`, `%` bind tighter than `+`, `-`
- Left-to-right associativity within the same precedence level

```
print((1 + 2 * 3 + 4 * 5).Str())      // 27  (= 1 + 6 + 20)
print((1 + 2 * 3 - 4 * 5 / 2).Str())  // -3
```

#### Unary operators

| Operator | Description     | Example    | Result  |
|----------|-----------------|------------|---------|
| `-`      | Arithmetic negation | `-5`   | `-5`    |
| `!`      | Logical NOT     | `!true`    | `false` |

Unary `-` applies only to `Int`. `!` applies only to `Bool`. Applying `!` to an `Int` is a
`TypeError`:

```
!8      // TypeError
!0      // TypeError
```

#### Comparison operators

All comparison operators take two operands of the same type and return `Bool`. `Int` supports
all six. `Str` and `Char` support `==` and `!=` only. `Bool` supports **none** of them —
`true == true` is a `TypeError` (compare with `&&`/`||`/`!` instead). Custom types may overload
any comparison.

| Operator | Description           |
|----------|-----------------------|
| `==`     | Equal                 |
| `!=`     | Not equal             |
| `<`      | Less than             |
| `>`      | Greater than          |
| `<=`     | Less than or equal    |
| `>=`     | Greater than or equal |

Comparison operators are **not chainable**. `1 < 2 < 3` is a `TypeError` because `Bool < Int`
is not defined.

```
1 > 2       // false
2 > 1       // true
1 > 1       // false
true > 2    // TypeError: Bool has no > operator with Int
1 < 2 < 3   // TypeError: result of (1 < 2) is Bool; Bool < Int is undefined
2 == ""     // TypeError: Int == Str is not defined
```

#### Logical operators

| Operator | Description  | Operand types | Return type |
|----------|--------------|---------------|-------------|
| `&&`     | Logical AND  | `Bool, Bool`  | `Bool`      |
| `\|\|`   | Logical OR   | `Bool, Bool`  | `Bool`      |
| `!`      | Logical NOT  | `Bool`        | `Bool`      |

`&&` and `||` do **not** short-circuit — both sides are always evaluated, and the right-hand
operand is evaluated *before* the left-hand one (`f() && g()` calls `g` first).

```
true && false    // false
true || false    // true
!true            // false
0 && 1           // TypeError: && requires Bool operands
```

#### String concatenation

`+` on two `Str` values returns a new `Str`. This is the `+` operator overload defined on `Str`.

```
"Hello, " + "world!"    // "Hello, world!"
"" + "abc"              // "abc"
"abc" + ""              // "abc"
```

#### None-coalescing operator (`??`)

The `??` operator unwraps an `Option<T>` value. If the option is `some`, it returns the contained
value. If the option is `none`, it returns the right-hand default.

```
def main() {
    let x: Int? = Option.none!<Int>()
    let v = x ?? 42     // v = 42

    let y: Int? = Option.some!<Int>(7)
    let w = y ?? 42     // w = 7
}
```

`??` can also be defined as an operator method on user-defined classes.

#### Compound assignment

`+=`, `-=`, `*=`, `/=`, `%=` — see `variables.md`. These are not overloadable.

#### Full operator precedence table (high to low)

| Level | Operators                           | Associativity |
|-------|-------------------------------------|---------------|
| 1     | unary `-`, `!`                      | right         |
| 2     | `*`, `/`, `%`                       | left          |
| 3     | `+`, `-`                            | left          |
| 4     | `<`, `>`, `<=`, `>=`               | left          |
| 5     | `==`, `!=`                          | left          |
| 6     | `&&`                                | left          |
| 7     | `\|\|`                              | left          |
| 8     | `??`                                | left          |
| 9     | `=`, `+=`, `-=`, `*=`, `/=`, `%=`  | right         |

Parentheses override precedence in the usual way.

`typeof` is not in this table: it applies to the entire expression that follows it, so
`typeof 1 + 2` is `typeof (1 + 2)` and evaluates to `"Int"`.

#### Operator overloading

Classes may define methods named after binary operator symbols. Only binary operators may be
overloaded; unary operators (`!`) may not.

Valid overloadable operators: `+`, `-`, `*`, `/`, `%`, `==`, `!=`, `<`, `>`, `<=`, `>=`,
`&&`, `||`, `??`.

Rules:
- The method must take exactly one parameter in addition to `self`.
- That parameter must not have a default value.
- Operator methods cannot be defined at the top level — only inside a `class`.
- Compound assignment operators (`+=` etc.) cannot be overloaded.
- The method name is the operator symbol exactly: `def + (self, other: MyType) MyType { ... }`

```
class Vec2 {
    x: Int,
    y: Int,
    def + (self, other: Vec2) Vec2 ->
        new Vec2 { x: self.x + other.x, y: self.y + other.y },
    def == (self, other: Vec2) Bool ->
        self.x == other.x && self.y == other.y
}

def main() {
    let a = new Vec2 { x: 1, y: 2 }
    let b = new Vec2 { x: 3, y: 4 }
    let c = a + b
    print(c.x.Str())    // 4
    print(c.y.Str())    // 6
    print((a == b).Str())    // false
}
```

Invalid overload forms that cause errors:

```
class C {
    def ! (self) C { ... }             // SyntaxError: ! is not overloadable
    def += (self, other: C) C { ... }  // SyntaxError: compound assignment not overloadable
    def + (self) C { ... }             // TypeError: must take exactly one non-self parameter
    def + (self, a: C, b: C) C { ... } // TypeError: too many parameters
    def + (self, a: C = new C) C { ... } // TypeError: operator parameter cannot have default
}
def + (a: C, b: C) C { ... }          // SyntaxError: top-level operator definition
```

---

### `language/control-flow.md` — Control Flow

**Purpose:** Full reference and guide for `if`, `while`, `for`, `break`, `continue`, and
`return`.

#### `if` statements

```
if condition {
    // body
}

if condition {
    // then
} else {
    // else
}

if condition {
    // branch 1
} else if other_condition {
    // branch 2
} else {
    // branch 3
}
```

The condition must have type `Bool`. Using an `Int`, `Str`, or class instance as a condition is
a `TypeError`:

```
if 0 { }      // TypeError: condition must be Bool
if "" { }     // TypeError
if -100 { }   // TypeError
```

Parentheses around the condition are not required. They are permitted, because a parenthesised
expression is still an expression — `if (condition) { }` is valid. The condition must be followed
by either `{` or `->`:

```
if (true) { print("x") }   // valid
if (false) print("x")      // SyntaxError: expected `{` (or `->`) after the condition
if {}                      // SyntaxError: no condition
```

Multiple `else` blocks are a `SyntaxError`:

```
if true { } else { } else { }    // SyntaxError
```

#### Arrow syntax for single statements

`->` replaces `{ }` when the body is a single statement.

```
if x > 0 -> print("positive")
if x > 0 -> print("positive") else print("not positive")
if x > 0 -> print("positive") else -> print("not positive")
```

The `else` branch does not require `->`:

```
if false -> print("3")
else print("4")           // valid

if true -> print("5") else -> print("6")    // both with -> also valid
```

#### `while` loops

Three forms:

**Conditional while** — runs while the condition is `Bool` true:

```
def main() {
    let mut i = 0
    while i < 5 {
        print(i.Str())
        i += 1
    }
}
// prints 0, 1, 2, 3, 4 (each on its own line)
```

**Infinite loop** — no condition; must use `break` to exit:

```
while {
    print("once")
    break
}
```

**Arrow form** — single-statement body:

```
def main() {
    let mut i = 0
    while i == 0 -> i = 1
    print("hi")    // prints hi
}
```

The condition (when present) must be `Bool`. `while 1 {}` and `while "" {}` are `TypeError`.

`break` exits the innermost loop. `continue` skips to the next iteration. Both are valid inside
`while` and `for` loops.

```
def main() {
    let mut i = 0
    while {
        i += 1
        if i < 5 -> continue
        print(i.Str())    // prints 5
        break
    }
}
```

`return` is also valid inside a loop body — it exits the enclosing function:

```
def f() {
    let mut i = 0
    while {
        i += 1
        if i > 2 -> return
        print(i.Str())
    }
}
f()    // prints 1 and 2 on separate lines
```

#### `for` loops

Iterates over any value that has `len()` and `at_raw()` methods. The built-in iterable types
are `List<T>`, `Str`, and `Range`.

A `for` loop declares local variables (including a hidden loop counter), so — like `let` — it
is only allowed inside a function body. A `for` loop at the top level is a `SyntaxError`, even
in script mode. Each loop variable name may only be used by one `for` loop per function (see
`variables.md`).

**Basic form:**

```
for item in collection {
    // body
}
```

**With index:**

```
for item, index in collection {
    // body; index is 0-based
}
```

**Arrow form:**

```
for item in collection -> print(item.Str())
```

The examples below print with a custom `line_end` (second argument to `print`) so that output
stays on one line; plain `print(x)` adds a newline after each value.

**Iterating a `List<T>`** yields values of type `T`:

```
def main() {
    let arr = List.empty!<Int>()
    arr.push(1)
    arr.push(2)
    arr.push(3)
    for n in arr {
        print(n.Str(), ",")
    }
    // prints 1,2,3,
}
```

**Iterating a `Str`** yields `Char` values:

```
def main() {
    for c in "abc" {
        print(c.Str(), " ")
    }
    // prints a b c
}
```

With index:

```
def main() {
    for c, i in "abc" {
        print(i.Str() + c.Str(), " ")
    }
    // prints 0a 1b 2c
}
```

**Iterating a `Range`** yields `Int` values:

```
def main() {
    for i in range(5) {
        print(i.Str(), "")    // 01234
    }
}
```

Iterating over a type that is not iterable (e.g. `Int`, `Bool`) is a `TypeError`:

```
def main() {
    for i in 1 {}      // TypeError: class 'Int' does not have method 'at_raw'
    for j in true {}   // TypeError
}
```

**Loop variables persist after the loop ends.** The element variable holds the last element;
the index variable holds the number of iterations:

```
def main() {
    for c, i in "abc" {}
    print(i.Str() + c.Str())    // 3c
}
```

**Nested loops:**

```
def main() {
    let arr = List.empty!<Int>()
    arr.push(1)
    arr.push(2)
    for n in arr {
        for m in "ab" {
            print(m.Str() + n.Str(), " ")
        }
    }
    // prints a1 b1 a2 b2
}
```

**`break` and `continue` in `for` loops:**

```
def main() {
    for i in range(5) {
        if i >= 3 -> break
        print(i.Str(), ",")
    }
    // prints 0,1,2,
}
```

```
def main() {
    for i in range(5) {
        print(i.Str(), "")
        if i >= 3 -> continue
        print(",", "")
    }
    // prints 0,1,2,34
}
```

The loop variable name `_$_` and names containing `_$_` are reserved and cause a `SyntaxError`.

---

### `language/functions.md` — Functions

**Purpose:** Complete reference for all function forms, including the entry-point rules,
return-type checking, and first-class function values.

#### Named functions (`def`)

```
def name(param1: Type1, param2: Type2) ReturnType {
    // body
}
```

**Parameter types are always required.** Omitting a type annotation from a parameter is a
`TypeError`:

```
def f(a) Str {}    // TypeError: missing type for parameter a
```

The return type can be omitted when it is `Void` or when using `->` syntax (inferred).

A function with a non-`Void` return type must have a `return` statement on every execution path.
A missing `return` on any path is a `TypeError`:

```
def f() Int {
    if true {
        return 1
    }
    // TypeError: not all paths return
}

def f() Int {
    if true {
        return 1
    } else {
        return 2
    }
    // valid: both paths return
}
```

An `if` without an `else` does not count as covering all paths, even when the condition is
`true` — the compiler performs a structural check, not value analysis.

A `while { ... }` with no condition is treated as always returning (an infinite loop):

```
def f() Int {
    while {
        return 1
    }
    // valid: the while body always returns
}
```

A conditional `while condition { ... }` does not cover the case where the loop never runs:

```
def f(a: Bool) Int {
    while a {
        return 1
    }
    // TypeError: if a is false, no return
}

def f(a: Bool) Int {
    while a {
        return 1
    }
    return 2    // valid
}
```

Code after a `return` statement in the same block is a `SyntaxError` (unreachable code):

```
def f() {
    return
    print("hi")    // SyntaxError: unreachable
}

def f() Int {
    return 1
    return 2       // SyntaxError: unreachable
}
```

`return` is not allowed at the top level — only inside a function body:

```
return 1    // SyntaxError: return outside function
```

Returning the wrong type is a `TypeError`:

```
def f() Int {
    return ""    // TypeError: expected Int, got Str
}

def f() Void {
    return 1    // TypeError: cannot return value from Void function
}

def f() Int {
    print("hi")    // TypeError: Int function body must end with a return
}
```

A `Void` function may return early with a bare `return`:

```
def f() Void {
    return    // valid early exit
}
```

#### Arrow syntax

Single-expression body with implicit return. The return type can be omitted (inferred) or written
explicitly before the `->`:

```
def add(a: Int, b: Int) Int -> a + b
def square(n: Int) -> n * n          // return type inferred as Int
def greet(name: Str) -> print("Hello, " + name)   // inferred as Void
```

#### Return type inference

Return type can be inferred for `->` functions. However, if two functions call each other
(mutual recursion) and neither has an explicit return type, the compiler cannot resolve the
cycle and produces an `UnknownSymbol` error. At least one function in a mutually recursive group
must have an explicit return type:

```
def foo() -> bar()    // UnknownSymbol: can't infer return type
def bar() -> foo()

// Fix: annotate at least one:
def foo() Int -> bar()
def bar() -> foo()    // valid: infers Int from foo's return type
```

#### Default parameters

Parameters may have default values. Parameters with defaults must appear **after** all
parameters without defaults — violating this is a `TypeError`.

```
def f(a: Int, b: Int = 2, c: Int = 3) {
    print(a.Str() + b.Str() + c.Str())
}
f(1)       // prints 123
f(1, 9)    // prints 193

def f(a: Int = 1, b: Int) {}   // TypeError: non-default after default
```

Default values may reference global constants and expressions, but not other parameters.

> **Known issue:** referencing another parameter (`def f(a: Int, b: Int = a)`) is not reported as
> an error — the declaration compiles, and calling `f` makes the compiler crash with an internal
> error (`entered unreachable code`). Do not rely on this.

```
const U = 1
def f(a: Int, b: Int = 5 - U) {
    print(a.Str() + b.Str())
}
f(4)    // prints 44
```

The default value's type must match the parameter's type:

```
def f(a: Int = "") {}    // TypeError: Str default for Int parameter
```

Trailing commas in parameter lists are allowed.

#### Duplicate parameter names

Declaring two parameters with the same name is a `TypeError`:

```
def g(a: Int, a: Str) {}    // TypeError: duplicate parameter a
```

#### Nested function declarations are forbidden

Defining a function inside another function or inside a method body is a `TypeError`:

```
def g() {
    def f() {}    // TypeError: nested function definition
}

class C {
    def outer(self) {
        def inner() {}    // TypeError: nested function definition
    }
}
```

#### Recursive functions

Functions can call themselves:

```
def fib(n: Int) Int {
    if n <= 1 -> return n
    return fib(n - 1) + fib(n - 2)
}
print(fib(10).Str())    // 55
```

With a default parameter for the initial call:

```
def count_down(i = 0) {
    if i > 9 -> return
    print(i.Str())
    count_down(i + 1)
}
count_down()    // prints 0 to 9, one per line
```

#### Anonymous functions (`fn`)

First-class function values. Can be stored in variables, passed as arguments, or returned.

```
def main() {
    let double = fn (x: Int) Int { return x * 2 }
    let triple = fn (x: Int) Int -> x * 3
    let add = fn (a: Int, b: Int) -> a + b
    let nothing = fn () {}
    let greet = fn () -> print("hi")
}
```

The return type can be inferred with `->`. An explicit return type is written before `->`:

```
def main() {
    let f = fn () Int -> 1     // explicit return type
    let g = fn () -> 1         // inferred return type
}
```

Anonymous functions **cannot be immediately invoked**:

```
(fn () { print("hi") })()    // SyntaxError
```

**Closure restriction:** anonymous functions can only access global constants and top-level
definitions. They cannot close over local variables from the enclosing function:

```
def main() {
    let x = 5
    let f = fn () Int { return x }    // UnknownSymbol: x is not accessible
}
```

Global constants are accessible:

```
const MESSAGE = "hi"
def main() {
    let a = fn () -> print(MESSAGE)
    a()    // prints hi
}
```

Anonymous functions also cannot call each other (one cannot reference a sibling local `fn`):

```
def main() {
    let five = fn () Int { return 5 }
    let num = fn () Int { return five() }    // UnknownSymbol: five not in scope
}
```

Generic anonymous functions are not a supported feature. Note that `fn <T>(x: T) T { ... }` is
currently accepted by the compiler rather than rejected with an error; do not rely on it.

Anonymous functions passed to higher-order parameters with a mismatched signature are a
`TypeError`:

```
def apply(f: Fn(Int) Int) { ... }
apply(fn (x: Int) -> "")    // TypeError: Str returned, Int expected
```

#### First-class functions

Named functions can be stored in variables and called through them:

```
def inc(x: Int) Int -> x + 1
def add_two(x: Int) Int -> x + 2

def main() {
    let mut f = inc
    print(f(1).Str())    // 2
    f = add_two
    print(f(1).Str())    // 3
}
```

Generic functions can be used as first-class values and instantiated through the variable:

```
def f<T>(a: T) T -> a

def main() {
    let f_ = f
    print(f_!<Str>("abc"))    // abc
}
```

#### Higher-order functions

Functions accepting or returning function values:

```
def apply(f: Fn(Int) Int, x: Int) Int -> f(x)

def main() {
    print(apply(fn (n: Int) Int -> n * n, 5).Str())    // 25
}
```

```
def do_something(f: Fn(Int) Int) Int {
    return f(42)
}

def main() {
    let plus_one = fn (x: Int) Int { return x + 1 }
    print(do_something(plus_one).Str())    // 43
}
```

#### The `main` function

`main` is an optional entry point. It must return `Void`.

```
def main() {
    print("running")
}
```

Returning a value from `main` is a `TypeError`:

```
def main() -> "hi"    // TypeError: main must return Void
def main() { return 1 }    // TypeError
```

`main` must not be declared with `extern`:

```
extern def main()    // SyntaxError
```

`main` accepts an optional `List<Utf8Str>` argument for command-line arguments. Any other
parameter type is a `TypeError`:

```
def main(args: List<Utf8Str>) { ... }    // valid
def main(a: Int) { ... }               // TypeError
```

When `main` is defined, no executable statements may appear at the top level:

```
def f() {}
def main() { print("hi") }
f()    // SyntaxError: statement after main definition
```

#### External functions (`extern def`)

Declare a function whose implementation is not written in Oxynium. The compiler emits a call to
a symbol with the function's name.

```
extern def my_c_function(x: Int) Str
```

Rules:
- Bodies are forbidden: `extern def f() {}` is a `SyntaxError`. A trailing `;` is optional.
- Cannot be named `main`.
- Cannot redeclare a built-in function: `extern def print()` is a `TypeError`.
- May have default parameter values.
- Calling an external function that nothing in the program defines produces an `IoError` at
  compile time (reported by the assembler: ``symbol `f' not defined``).

```
extern def f()                // valid declaration
f()                           // IoError: symbol `f' not defined
```

See `advanced/extern.md` for the current limitations (C library functions cannot be called this
way).

---

### `language/classes.md` — Classes

**Purpose:** Complete reference for user-defined types, fields, methods, static methods,
composition, operator overloading, and primitive classes.

#### Defining a class

```
class Point {
    x: Int,
    y: Int
}
```

Fields are separated by commas. A trailing comma is allowed. Fields and method definitions
can be interleaved in any order.

Empty class (no fields, no methods):

```
class Token
class Empty;
class Nothing {}
```

Redefining a name that already exists as a class or type is a `TypeError`:

```
class A {}
class A {}    // TypeError: duplicate type name
```

Classes cannot be defined inside other classes:

```
class A {
    class B {}    // SyntaxError
}
```

Classes **can** be defined locally inside a function body. However, a locally-defined class is
not visible outside that function:

```
def main() {
    class C
    // C is usable here
}
def f(a: C)    // UnknownSymbol: C is not in scope here
```

Class names follow identifier rules — `_$_MyClass` is a `SyntaxError`.

#### Instantiation (`new`)

```
let p = new Point { x: 3, y: 4 }
```

(Like all `let` statements, this must be inside a function body.)

Every field must be provided exactly once, in any order (`new Point { y: 4, x: 3 }` is
equivalent). Missing fields, unknown fields, or wrong types are a `TypeError`:

```
class S { x: Int }

new S { }              // TypeError: missing field x
new S { y: 1 }         // TypeError: unknown field y
new S { x: "hi" }      // TypeError: Str given for Int field
new S { x: 1, y: 2 }  // TypeError: extra field y
```

**Field shorthand:** if a local variable has the same name as a field, the name alone can be used:

```
def main() {
    let a = 1
    print(new C { a }.a.Str())    // prints 1
}
class C { a: Int }
```

**Invalid `new` forms:**

```
new s       // UnknownSymbol: s is lowercase, looks like a variable
new 1       // SyntaxError
new ""      // SyntaxError
new new C   // SyntaxError
new C()     // SyntaxError: use braces, not parentheses
```

For classes with no fields, `new C{}`, `new C { }`, and `new C` (bare, with no braces) are all
valid.

**Generic instantiation** (where `Wrapper<T>` is a generic class — see `generics.md`):

```
let w = new Wrapper<Int> { data: 42 }
```

#### Field access

```
print(new Point { x: 3, y: 4 }.x.Str())    // 3
```

Accessing a field that does not exist is a `TypeError`.

#### Field assignment

Fields can be assigned through any variable (not just `mut` variables — field mutation and
variable rebinding are independent):

```
class A { a: Int }

def main() {
    let a = new A { a: 1 }
    print(a.a.Str(), " ")    // 1
    a.a = 2
    print(a.a.Str(), " ")    // 2
    print((new A { a: 1 }.a = 3).Str())    // 3
}
```

Assigning to a non-existent field is a `TypeError`.

#### Instance methods

Defined with `self` as the first parameter. `self` must not have a type annotation — providing
one is a `SyntaxError`:

```
class S {
    def log(self: S) {}    // SyntaxError
    def log(self: Int) {}  // SyntaxError
}
```

Inside a method, `self` refers to the receiver and has the type of the enclosing class.

```
class Point {
    x: Int,
    y: Int,
    def magnitude_sq(self) Int -> self.x * self.x + self.y * self.y
}

def main() {
    let p = new Point { x: 3, y: 4 }
    print(p.magnitude_sq().Str())    // 25
}
```

Methods with additional parameters:

```
class S {
    x: Int,
    def log(self) Void {
        print("x = ", "")
        print(self.x.Str(), "")
        print(", ", "")
    }
}
new S { x: 1 }.log()
new S { x: 2 }.log()
// prints x = 1, x = 2,
```

Calling an instance method with the wrong argument count or types is a `TypeError`.

#### Default parameters on methods

Same rules as for standalone functions:

```
class Greeter {
    def say(self, msg: Str = "Hello") {
        print(msg)
    }
}
new Greeter{}.say()        // Hello
new Greeter{}.say("Hi")   // Hi
```

#### Static methods

Methods without a `self` parameter. Called on the class name, not on an instance.

```
class Counter {
    count: Int,
    def zero() Counter -> new Counter { count: 0 }
}
print(Counter.zero().count.Str())    // 0
```

Calling a static method on an instance is a `TypeError`:

```
class C {
    def f() {}
}
(new C).f()    // TypeError: f is a static method, not an instance method
```

Calling an instance method as if it were static (without passing the instance) is a `TypeError`:

```
class C {
    def log(self) {}
}
C.log()    // TypeError: missing self argument
```

**Calling instance methods statically** by passing the instance explicitly is valid:

```
class S {
    def f(self, msg: Str) Str { return msg }
}
def main() {
    print(S.f(new S, "abc"))    // abc
}
```

This also works with default parameters:

```
class S {
    def f(self, a: Int, msg = "hello") -> msg
}
S.f(new S, 1)    // "hello"
```

Passing an instance of the wrong type is a `TypeError`.

#### Method call shorthands

`new S.method(args)` is equivalent to `(new S{}).method(args)`:

```
class S {
    def f(self, a: Int) {}
}
(new S{}).f(1)   // standard form
new S.f(1)       // shorthand
new S{}.f(1)     // also valid
```

Calling a method that does not exist on a class is a `TypeError`.

#### Static methods as first-class values

Static methods can be stored in variables and used as first-class functions:

```
class S {
    def g() -> 1
}
def main() {
    let g = S.g
    print(g().Str())    // 1
}
```

Instance methods can also be taken as first-class values through the class name. The resulting
function takes the instance as its first argument:

```
class S {
    x: Int,
    def g(self) -> self.x
}
def main() {
    let g = S.g
    print(typeof g)                    // Fn S.g(self: S) Int
    print(g(new S { x: 5 }).Str())     // 5
}
```

Accessing a method through an instance (`(new S).g`) does **not** bind the instance — it yields
the same unbound function as `S.g`.

#### Operator overloading

Covered in full in `operators.md`. Example:

```
class Foo {
    x: Int,
    def + (self, other: Foo) Foo {
        return new Foo { x: self.x + other.x }
    }
}
class Bar {
    x: Int,
    def + (self, other: Int) Bar {
        return new Bar { x: self.x + other }
    },
    def - (self, other: Foo) Bar {
        return new Bar { x: self.x - other.x }
    }
}
def main() {
    let a = new Foo { x: 1 }
    let b = new Foo { x: 2 }
    print((a + b).x.Str())                          // 3
    print((new Bar { x: 1 } + 3).x.Str())           // 4
    print((new Bar { x: 2 } - a).x.Str())           // 1
}
```

#### Class composition

```
class Inner {
    value: Int
}
class Outer {
    inner: Inner,
    tag: Str
}

def main() {
    let o = new Outer {
        inner: new Inner { value: 42 },
        tag: "hello"
    }
    print(o.inner.value.Str())    // 42
    print(o.tag)                  // hello
}
```

#### Primitive classes

`primitive` is a keyword used by the standard library to define built-in types (`Int`, `Bool`,
`Char`, `Ptr<T>`). It is intended for the standard library only. The compiler does not currently
reject it in user code — `primitive A` compiles — but there is no reason to use it in application
code.

---

### `language/generics.md` — Generics

**Purpose:** Guide and reference for generic classes and functions, instantiation syntax, and
scope rules.

#### Generic classes

Declared with one or more type parameters in angle brackets after the class name:

```
class Cell<T> {
    value: T
}

def main() {
    let b = new Cell<Int> { value: 42 }
    print(b.value.Str())    // 42
}
```

(The standard library reserves a number of common type names for future use — including `Box`,
`Vec`, `Map`, `Array`, `String`, `Iter` and `Error` — so declaring a class with one of those names
is a `TypeError`. The full list is in `std/target-any/reserved.oxy`.)

Multiple type parameters:

```
class Pair<A, B> {
    first: A,
    second: B
}

def main() {
    let p = new Pair<Int, Str> { first: 1, second: "one" }
    print(p.first.Str())     // 1
    print(p.second)          // one
}
```

A trailing comma in the type parameter list is allowed: `class Cell<T,>`.

Type parameters are in scope for all field declarations and method bodies within the class.

Providing the wrong concrete type for a generic field is a `TypeError`:

```
class C<T> { x: T }
new C<Int> { x: "Hi" }    // TypeError: Str given for T=Int
```

#### Generic methods on generic classes

Instance methods on a generic class can introduce their own additional type parameters:

```
class Wrapper<T> {
    data: T,
    def map<U>(self, f: Fn(T) U) Wrapper<U> ->
        new Wrapper<U> { data: f(self.data) }
}

def main() {
    let w = new Wrapper<Int> { data: 5 }
    let s = w.map!<Str>(fn (n: Int) Str -> n.Str())
    print(s.data)    // 5
}
```

A method-level type parameter must not duplicate the class-level parameter name:

```
class C<A> {
    def a<A>(self, v: A) A { return v }    // TypeError: A already defined at class level
}
```

Type parameters used in a static method must be the method's own parameters (not the class's,
since there is no instance to bind from):

```
class C<T> {
    def a(i: Int) {}    // valid: no T used
}
C.a(1)    // valid
```

```
class C<T> {
    def a(t: T) T { return t }    // UnknownSymbol: T not available in static context
}
```

The class's type parameter is available in instance methods, so a method that needs `T` should
take `self`:

```
class C<T> {
    def a(self, t: T) T { return t }    // valid: instance method can access T
}
print(new C<Int>.a(1).Str())            // 1
```

Such a method can still be called through the class by passing an instance explicitly:

```
print(C!<Int>.a(new C<Int>, 2).Str())  // 2
```

Attempting to call a generic instance method without the generic parameter is a `TypeError`.

#### Generic functions

```
def identity<T>(x: T) T -> x

print(identity!<Int>(42).Str())    // 42
print(identity!<Str>("hello"))     // hello
```

Multiple type parameters:

```
def apply<T, A>(t: T, f: Fn(T) A) A -> f(t)

const x = 2
print(apply!<Int, Int>(x, fn (n: Int) -> n + 1).Str())    // 3
```

Trailing commas in type parameter lists are allowed: `def f<T,>(x: T) T -> x`.

#### Instantiation syntax

Generic functions and methods are called with `!<Type>` between the name and the argument list:

```
identity!<Int>(42)
List.empty!<Int>()
list.map!<Str>(fn (n: Int, i: Int) -> n.Str())
```

Omitting the `!<Type>` on a generic function is a `TypeError`.
Providing the wrong number of type arguments is a `TypeError`.

#### Type parameters are not first-class

Type parameters only exist in the context of their declaration. Passing an unknown type `T` to
a function that does not declare it is an `UnknownSymbol` error:

```
def a<T>(x: T) T { return x }
a!<T>("")    // UnknownSymbol: T is not defined at the call site
```

#### Nested generics and chaining

```
class Cell<T> { value: T }

def main() {
    let nested = new Cell<Cell<Int>> {
        value: new Cell<Int> { value: 1 }
    }
    print(nested.value.value.Str())    // 1
}
```

Chained generic method calls:

```
def main() {
    let result = List.empty!<Int>()
        .map!<Str>(fn (n: Int, i: Int) -> n.Str())
        .map!<Int>(fn (s: Str, i: Int) -> s.len())
}
```

The `typeof` operator reflects the instantiated type at each step:

```
print(typeof List.empty!<Int>(), " ")
// List<Int>
print(typeof List.empty!<Int>().map!<Str>(fn (a: Int, b: Int) -> " "), " ")
// List<Str>
```

---

### `language/typeof.md` — The `typeof` Operator

**Purpose:** Reference for the `typeof` keyword, which returns a `Str` naming the compile-time
type of any expression.

#### Syntax

```
typeof expr
typeof(expr)    // parentheses are optional
```

The keyword must be followed by exactly one expression. `typeof` alone, or `typeof 1 2`, is a
`SyntaxError`. `typeof` applies to the whole expression after it: `typeof 1 + 2` means
`typeof (1 + 2)`.

#### Return type

`typeof` always returns a `Str`. Since its result is a `Str`, `typeof typeof x` is valid and
returns `"Str"`.

#### Examples

```
print(typeof "abc")         // Str
print(typeof "abc", " ")    // Str — " " is the second arg to print (its line_end), not to typeof
print(typeof 2)             // Int
print(typeof new Void)      // Void
print(typeof Void)          // Void
print(typeof Int)           // Int
print(typeof Str)           // Str
print(typeof true)          // Bool
print(typeof typeof Bool)   // Str
print(typeof typeof typeof new Void)  // Str
```

#### On classes and instances

```
class C
print(typeof C)       // C
print(typeof new C)   // C
```

#### On functions and calls

```
def a() {}
print(typeof a)      // Fn a() Void
print(typeof a())    // Void
```

Anonymous functions get a generated name:

```
print(typeof fn () {})    // Fn fn14@inoxy() Void   (name includes a generated id)
```

Declaring a function with `typeof` of its definition returns the function type:

```
print(typeof def a() {})    // Fn a() Void
```

#### Inside generic functions

`typeof` reflects the concrete type at the call site:

```
def show<T>(a: T) T {
    print(typeof a, ",")
    print(typeof T, ",")
    return a
}
def main() {
    let int = show!<Int>(1)
    print(typeof int, ",")
    print(typeof show!<Str>("Hi"))
}
// prints T,T,Int,Str
```

(Within the generic function body, `typeof T` and `typeof a` both print the type parameter
name as a string, not the concrete type. At the call site, the concrete type is used.)

#### Restrictions

The following are `SyntaxError`:
- `typeof` alone with nothing after it
- `typeof 1 2` (two expressions)
- `typeof ()` (empty parentheses)
- `typeof (1, 2)` (tuple — not a valid Oxynium expression)
- `typeof {}` (block)
- `typeof new` (incomplete new expression)
- `typeof typeof` (nested without inner expression)
- `typeof while {}` (control-flow as argument)
- `typeof if true {}` (control-flow as argument)
- `typeof []` (array literal — not valid syntax)

Using an undeclared name: `typeof Type` → `UnknownSymbol`.

---

### `language/program-structure.md` — Program Structure

**Purpose:** Explain how top-level declarations, script mode, main mode, semicolons, and
declaration ordering interact.

#### Two modes of execution

**Script mode:** no `main` function. Top-level statements execute in the order they appear.
Statements that declare local variables — `let`, `let mut` and `for` loops — are still not
allowed at the top level (`SyntaxError`); put them in a function, or use `const`.

```
const MSG = "Hello"
print(MSG)          // runs immediately
print("World")      // runs immediately
```

**Main mode:** a `main` function is defined. Only `main`, `const`, `class`, `def`, and
`extern def` may appear at the top level. Executable statements outside `main` are a
`SyntaxError`:

```
def f() {}
def main() {
    print("hi")
}
f()           // SyntaxError: executable statement after main definition
```

```
f()           // SyntaxError: statement before main definition also forbidden
def f() {}
def main() { ... }
```

In main mode, `const`, `class`, and `def` declarations are allowed anywhere in the file.

#### What can appear at the top level

In script mode: `const`, `class`, `def`, `extern def`, and any executable statement except `let`
and `for`.
In main mode: `const`, `class`, `def`, `extern def` only.

```
const VALUE = 16
def main() {
    print(VALUE.Str())    // 16
}
```

#### Semicolons and automatic insertion

Semicolons are optional. The compiler performs automatic end-of-statement insertion. Both styles
compile identically:

```
print("a"); print("b")
print("a")
print("b")
```

Statements can span multiple lines freely when the line break occurs at a point where the
statement is clearly incomplete (after an operator, inside parentheses, etc.):

```
print(
    (
    1
    +
    2
    )
    .
    Str
    (
    )
)    // prints 3
```

An `if` condition can span multiple lines:

```
def main() {
    let a = 2
    let b = 1
    if
        a
        >
        b
    {}
}
```

#### Declaration order

The compiler performs a setup pass before type checking. This means functions and classes can
be used before their definition in the source file. All names are visible throughout the entire
file regardless of declaration order.

```
def f(a: A) A { return a }
class A;    // A is used above its definition — valid
```

However, a local variable cannot be used before its `let` or `let mut` declaration in the same
function body — this is a `TypeError`.

#### Defining classes locally

Classes can be defined inside function bodies and are scoped to that function:

```
def main() {
    class C
    // C is usable here
}
```

A locally-defined class is not accessible to any function that does not enclose its definition:

```
def main() {
    class C
}
def f(a: C)    // UnknownSymbol: C is out of scope
```

---

### `std/overview.md` — Standard Library Overview

**Purpose:** Index page. All standard library types are automatically available — no import
needed.

The standard library is split into target-independent code (available on all platforms) and
target-specific code (macOS or Linux). The types documented in this section are all
target-independent.

| Type / Function       | Description |
|-----------------------|-------------|
| `Int`                 | 64-bit signed integer |
| `Bool`                | Boolean value |
| `Char`                | Single Unicode character |
| `Str`                 | Immutable string with rich methods |
| `Utf8Str`             | Raw UTF-8 string for OS interop |
| `List<T>`             | Dynamic resizable array |
| `Option<T>`           | Optional / nullable value |
| `Result<T, E>`        | Success-or-error value |
| `Range`               | Lazy integer sequence |
| `Ptr<T>`              | Unsafe heap pointer |
| `File`                | Open, read, write and close files (`File.open`, `File.read`) |
| `Time`                | Wall-clock timestamps (`Time.now()`, `Time.epoch()`, `+`, `-`) |
| `range()`             | Constructor for `Range` values |
| `print()`             | Print to stdout |
| `input()`             | Read a line from stdin |
| `panic()`             | Abort with an error message |
| `exit()`              | Terminate with an exit code |

---

### `std/int.md` — `Int`

**Purpose:** Complete reference for the 64-bit integer type.

#### Definition

`primitive Int` — 64-bit signed integer. Range: `−9 223 372 036 854 775 808` to
`9 223 372 036 854 775 807` (−2⁶³ to 2⁶³−1).

#### Literals

Bare decimal integers: `0`, `42`, `-7`. Negative values are the unary `-` operator applied to
a positive literal. Integer literals exceeding 2⁶³−1 produce a `NumericOverflow` error at
compile time:

```
9223372036854775807     // valid: max Int
9223372036854775808     // NumericOverflow: too large
-9223372036854775808    // NumericOverflow: the literal is parsed before negation
```

To obtain the minimum `Int`, use `0.min()` or `-9223372036854775807 - 1`.

Runtime overflow wraps around silently (two's complement):

```
print((9223372036854775807 + 1).Str())    // -9223372036854775808
```

`new Int` produces `0`.

#### Arithmetic

All five arithmetic operators work on pairs of `Int` values and return `Int`. Division truncates
toward zero. Division by the literal `0` is a compile-time `TypeError`:

```
print((1 / 0).Str())    // TypeError at compile time
print((0 / 0).Str())    // TypeError at compile time
```

Operator precedence: `*`, `/`, `%` before `+`, `-`. Left-to-right within same level.

```
print((1 + 2 * 3 + 4 * 5).Str())    // 27
```

#### Logical operators do not apply to `Int`

`&&`, `||`, and `!` are not defined for `Int`. Using them is a `TypeError`:

```
0 && 1    // TypeError
0 || 1    // TypeError
!8        // TypeError
```

Use `.Bool()` to convert first if needed.

#### Comparison operators

`==`, `!=`, `<`, `>`, `<=`, `>=` — all return `Bool`. Not chainable.

#### Methods

| Method     | Signature                       | Description |
|------------|---------------------------------|-------------|
| `Str`      | `(self) Str`                    | Convert to decimal string representation |
| `Bool`     | `(self) Bool`                   | `0` → `false`, any other value → `true` |
| `max`      | `(self, other=9223372036854775807) Int` | Return the larger of the two values |
| `min`      | `(self, other=-9223372036854775808) Int` | Return the smaller of the two values |
| `abs`      | `(self) Int`                    | Absolute value |
| `compare`  | `(self, other: Int) Int`        | Returns `-1`, `0`, or `1` |

`max()` and `min()` with no argument use the respective extreme values as defaults:

```
print(1.max().Str())     // 9223372036854775807 (max Int wins)
print((-1).min().Str())  // -9223372036854775808 (min Int wins)
```

`compare` returns `-1` if `self < other`, `0` if equal, `1` if `self > other`. It can be called
as an instance method or as a static method:

```
print(Int.compare(1, 2).Str())    // -1
print(Int.compare(2, 1).Str())    // 1
print(Int.compare(1, 1).Str())    // 0
print(2.compare(5).Str())         // -1
print(7.compare(7).Str())         // 0
print(9.compare(3).Str())         // 1
```

Full examples:

```
print((-5).abs().Str())      // 5
print(3.max(7).Str())        // 7
print(10.min(4).Str())       // 4
print(0.Bool().Str())        // false
print((-1).Bool().Str())     // true
```

---

### `std/bool.md` — `Bool`

**Purpose:** Reference for the boolean type.

#### Literals

`true` and `false`. `new Bool` produces `false`.

#### Operators

`&&` (AND), `||` (OR), `!` (NOT). All require `Bool` operands. Neither `&&` nor `||`
short-circuits — both operands are always evaluated.

```
print((true && false).Str())    // false
print((true || false).Str())    // true
print((!false).Str())           // true
```

#### Methods

| Method | Signature    | Description              |
|--------|--------------|--------------------------|
| `Str`  | `(self) Str` | `"true"` or `"false"` |

```
print(true.Str())     // true
print(false.Str())    // false
```

#### Conversion from `Int`

`n.Bool()` — `0` is `false`, any other integer is `true`:

```
print(0.Bool().Str())    // false
print(1.Bool().Str())    // true
print((-1).Bool().Str()) // true
```

---

### `std/char.md` — `Char`

**Purpose:** Reference for the character type and its classification and conversion methods.

#### Literals

Single-quoted: `'a'`, `'Z'`, `'0'`, `'💖'`. Escape sequences:

| Escape | Character |
|--------|-----------|
| `'\n'` | newline (10) |
| `'\t'` | tab (9) |
| `'\r'` | carriage return (13) |
| `'\\'` | backslash |
| `'\''` | single quote |

A double quote needs no escape in a `Char` literal: write `'"'`. (`'\"'` is a `SyntaxError`.)

`new Char` produces the null character (code point 0), which prints as nothing.

#### Encoding

Internally, each `Char` is stored as a 64-bit word. Multi-byte UTF-8 characters (emoji, etc.)
are stored in their raw UTF-8 byte representation packed into the 64-bit word. This is
Oxynium's internal "UTF-64" format.

`'A'` has code point 65. `'\n'` has code point 10. These match ASCII/Unicode values for the
ASCII range.

```
print(#unchecked_cast(Int, '\n').Str())    // 10
print(#unchecked_cast(Int, 'A').Str())     // 65
```

#### Equality

```
'a' == 'a'    // true
'a' == 'b'    // false
'💖' == '💖'  // true
```

#### Methods

| Method           | Signature             | Description |
|------------------|-----------------------|-------------|
| `Str`            | `(self) Str`          | Convert to a one-character `Str` |
| `Int`            | `(self) Int`          | Raw 64-bit value as an integer — the code point for ASCII, but the packed UTF-8 bytes for other characters (`'💖'.Int()` is `2526191600`, not `128150`) |
| `from_int`       | `(i: Int) Char`       | Create `Char` from a code point (static) |
| `is_digit`       | `(self) Bool`         | True for `'0'`–`'9'` |
| `is_alphabetic`  | `(self) Bool`         | True for `'A'`–`'Z'` or `'a'`–`'z'` |
| `is_uppercase`   | `(self) Bool`         | True for `'A'`–`'Z'` |
| `is_lowercase`   | `(self) Bool`         | True for `'a'`–`'z'` |
| `is_alphanumeric`| `(self) Bool`         | True for alphabetic or digit |
| `is_ascii`       | `(self) Bool`         | True if code point < 128 |
| `is_whitespace`  | `(self) Bool`         | True for `' '`, `'\n'`, `'\t'`, `'\r'` |
| `==`, `!=`       | `(self, Char) Bool`   | Equality and inequality |

```
print('A'.is_uppercase().Str())    // true
print('a'.is_lowercase().Str())    // true
print('3'.is_digit().Str())        // true
print(' '.is_whitespace().Str())   // true
print('z'.is_ascii().Str())        // true
print('💖'.is_digit().Str())       // false
print('a'.Int().Str())             // 97
print(Char.from_int(65).Str())     // A
print(Char.from_int(48).Str())     // 0
```

Note: `Char.from_int` for values above 127 is currently undefined behaviour.

---

### `std/str.md` — `Str`

**Purpose:** Complete reference for the string type and all its methods.

#### Encoding note

`Str` uses Oxynium's internal "UTF-64" encoding: each Unicode character occupies exactly 8 bytes
on the heap, regardless of its UTF-8 byte length. This gives O(1) indexing by character position.
This is different from the OS-level `Utf8Str` type, which uses standard UTF-8.

`"💖".len()` returns `1` (one character). `"💖".utf8_size()` returns `4` (four UTF-8 bytes).

#### Literals

Double-quoted strings: `"hello"`, `""`.

Escape sequences in string literals:

| Escape  | Character |
|---------|-----------|
| `"\n"`  | newline |
| `"\t"`  | tab |
| `"\r"`  | carriage return |
| `"\\"` | backslash |
| `"\""` | double quote |

Null bytes (`"\0"`) and unknown escapes (`"\9"`, `"\x"`) are `SyntaxError`.

**Multi-line string continuation:** a backslash immediately before a newline continues the string
on the next line, joining the two without a newline character:

```
print("line1\
line2")
// prints line1line2
```

**Unicode support:** string literals may contain any Unicode character directly:

```
print("ݫݨݫ")
print("💖")
print("﷽")
```

`new Str` produces `""` (empty string).

#### String comparison

`==` and `!=` perform character-by-character comparison:

```
"abc" == "abc"    // true
"abc" == "ABC"    // false
"abc" != "def"    // true
```

#### Methods (complete reference)

| Method          | Signature | Description |
|-----------------|-----------|-------------|
| `len`           | `(self) Int` | Number of characters (not bytes) |
| `at`            | `(self, i: Int) Option<Char>` | Character at index; supports negative indices; returns `Option::none` if out of range |
| `at_raw`        | `(self, i: Int) Char` | Character at index; unchecked (no bounds test) |
| `+`             | `(self, other: Str) Str` | Concatenate |
| `concat`        | `(self, other: Str) Str` | Concatenate (method form of `+`) |
| `contains`      | `(self, other: Str) Bool` | True if `other` appears as a substring |
| `find`          | `(self, other: Str) Int` | Index of first occurrence of `other`, or `-1` |
| `starts_with`   | `(self, other: Str) Bool` | True if string begins with `other` |
| `ends_with`     | `(self, other: Str) Bool` | True if string ends with `other` |
| `substr`        | `(self, start=0, end=MAX_INT) Str` | Substring from `start` (inclusive) to `end` (exclusive) |
| `repeat`        | `(self, n: Int) Str` | Repeat the string `n` times; `n < 1` returns `""` |
| `reversed`      | `(self) Str` | Reversed copy of the string |
| `replace`       | `(self, search: Str, replace_with="", max=-1) Str` | Replace occurrences of `search` with `replace_with` |
| `insert`        | `(self, index: Int, other: Str) Str` | Insert `other` at character position `index` |
| `remove`        | `(self, index: Int, count=1) Str` | Remove `count` characters starting at `index` |
| `split`         | `(self, separator: Str) List<Str>` | Split into a list of substrings |
| `join`          | `(self, l: List<Str>) Str` | Join list of strings with `self` as separator |
| `List`          | `(self) List<Char>` | Convert to a list of characters |
| `List_strings`  | `(self) List<Str>` | Convert to a list of one-character strings |
| `Str`           | `(self) Str` | Identity — returns `self` |
| `Utf8Str`       | `(self) Utf8Str` | Convert to raw UTF-8 string |
| `Int`           | `(self) Result<Int, Str>` | Parse as a decimal integer |
| `utf8_size`     | `(self) Int` | Size in UTF-8 bytes (not characters) |
| `==`, `!=`      | `(self, Str) Bool` | Character-by-character equality |

#### Negative indices

`at` and `substr` support negative indices. A negative index counts from the end of the string:
`-1` is the last character, `-2` the second-to-last, and so on.

```
"abc".at(-1)    // Option<Char> containing 'c'
"abc".at(-2)    // Option<Char> containing 'b'
"abc".at(-4)    // Option<Char> containing none (out of range)
```

`substr` with negative indices:

```
def main() {
    let s = "The quick brown fox jumps over the lazy dog."
    print(s.substr(31))         // the lazy dog.
    print(s.substr(4, 19))      // quick brown fox
    print(s.substr(-4))         // dog.
    print(s.substr(-9, -5))     // lazy
}
```

`substr` behaviour:
- `start >= end` → `""`
- `start` or `end` past the string length → clamped to the string bounds
- Empty string always returns `""`

#### `find` return value

Returns the 0-based character index of the first match, or `-1` if not found. Searching for an
empty string always returns `0`.

```
"abc".find("b")     // 1
"abc".find("d")     // -1
"abc".find("")      // 0
"".find("")         // 0
"".find("a")        // -1
```

#### `replace` semantics

- `search` is the substring to find. If empty, returns the string unchanged.
- `replace_with` defaults to `""` (deletion).
- `max` controls how many replacements to make. `-1` means unlimited. `0` means no replacements.

```
"aaa".replace("a", "b")       // bbb
"This is".replace("is", "at")       // That at
"This is".replace("is", "at", 1)    // That is
"This is".replace("is", "at", 0)    // This is (no replacements)
"abc".replace("ab")                 // c (replace with empty string)
```

#### `insert` semantics

Inserts `other` before the character at `index`. If `index >= len`, appends to the end.
Negative indices count from the end, where `-1` is the position *after* the last character
(`index` becomes `len + index + 1`), so `-1` appends and `-2` inserts before the last character.

```
"a".insert(0, "b")       // ba
"a".insert(1, "b")       // ab
"1234".insert(-1, "5")   // 12345  (appended)
"1234".insert(-2, "5")   // 12354  (before last char)
"123".insert(100, "456") // 123456 (appended)
```

#### `split` semantics

Splits on the `separator` string. If `separator` is `""`, splits into individual characters
(same as `List_strings`). A trailing empty segment is dropped. (Oxynium has no list literal
syntax; the bracketed lists below only describe the result.)

```
"1,2,3".split(",")      // ["1", "2", "3"]
"1,2,3".split(",2")     // ["1", ",3"]
"abc".split("")         // ["a", "b", "c"]
"a,b,".split(",")       // ["a", "b"]
```

#### `join` semantics

Uses `self` as the separator between elements of the list:

```
def main() {
    let l = List.empty!<Str>()
    l.push("a")
    l.push("b")
    l.push("c")
    print(",".join(l))    // a,b,c
    print("".join(l))     // abc
}
```

#### `Int` method

Parses the string as a decimal integer. Returns `Result<Int, Str>`:

```
def main() {
    let r = "42".Int()
    print(r.ok.Str())        // true
    print(r.unwrap().Str())  // 42

    let bad = "abc".Int()
    print(bad.ok.Str())          // false
    print(bad.error().unwrap())  // invalid character

    print("".Int().error().unwrap())                      // empty string
    print("99999999999999999999".Int().error().unwrap())  // overflow
    print("-5".Int().unwrap().Str())                      // -5
}
```

#### `utf8_size` vs `len`

`len` counts Unicode characters (as stored in UTF-64). `utf8_size` counts UTF-8 bytes, which is
what the OS and most external systems use.

```
"".utf8_size()      // 0
"a".utf8_size()     // 1
"💖".utf8_size()    // 4  (4 UTF-8 bytes for this emoji)
"﷽".utf8_size()    // 3  (3 UTF-8 bytes)
"abc".len()         // 3
"💖".len()          // 1
```

---

### `std/list.md` — `List<T>`

**Purpose:** Full reference for the dynamic array type.

#### Definition

`class List<T>` — a heap-allocated, resizable array. Fields: `head: Ptr<T>` (pointer to first
element), `length: Int` (number of elements), `capacity: Int` (allocated size in bytes, as used
by `push` to decide when to grow). User code should not access these fields directly.

#### Creating lists

```
def main() {
    let l = List.empty!<Int>()             // empty list, no pre-allocation
    let l2 = List.with_capacity!<Int>(10)  // see note below
}
```

> **Known issue:** `with_capacity(n)` allocates memory for `n` elements but records `n` as the
> capacity in *bytes*, so the list only treats `n / 8` elements as pre-allocated and reallocates
> early (with `with_capacity(10)`, the second `push` already triggers a reallocation). It is
> still correct, just not as efficient as intended.

Lists can also be constructed manually for low-level use (not recommended):

```
new List<Int> {
    head: Ptr.make!<Int>(7),
    length: 1,
    capacity: 8
}
```

#### Iteration

`List<T>` is iterable. A `for` loop yields elements of type `T`:

```
for item in list { ... }
for item, index in list { ... }
```

#### Methods

| Method          | Signature | Description |
|-----------------|-----------|-------------|
| `empty`         | `static <E>() List<E>` | Create an empty list |
| `with_capacity` | `static <E>(capacity: Int) List<E>` | Pre-allocate space for `capacity` elements |
| `len`           | `(self) Int` | Number of elements |
| `push`          | `(self, value: T) Void` | Append an element; grows automatically |
| `pop`           | `(self) Option<T>` | Remove and return the last element; `none` if empty |
| `at`            | `(self, i: Int) Option<T>` | Element at index (safe; supports negative indices) |
| `at_raw`        | `(self, i: Int) T` | Element at index (unchecked; no bounds test) |
| `set_at`        | `(self, idx: Int, val: T) Result<Void, Str>` | Set element at index (safe) |
| `set_at_unchecked` | `(self, idx: Int, val: T) Void` | Set element at index (unchecked) |
| `remove_at`     | `(self, idx: Int) Option<T>` | Remove and return element at index; `none` if out of range |
| `map`           | `<To>(self, f: Fn(T, Int) To) List<To>` | Transform every element; callback receives `(element, index)` |
| `filter`        | `(self, f: Fn(T) Bool) List<T>` | Retain elements matching predicate |
| `sort`          | `(self, f: Fn(T, T) Int) List<T>` | Sort using quicksort; comparator returns negative/0/positive |
| `clone`         | `(self) List<T>` | Shallow copy |
| `concat`        | `(self, other: List<T>) List<T>` | Return a new list with all elements of both |
| `index_of`      | `(self, item: T, cmp?=...) Option<Int>` | First index where item matches; uses pointer equality by default |
| `contains`      | `(self, item: T, cmp?=...) Bool` | True if any element matches |
| `Str`           | `(self) Str` | Returns `"List[n]"` where `n` is the length |

#### Negative indices

`at`, `set_at`, and `remove_at` support negative indices counting from the end:
`-1` is the last element, `-2` the second-to-last. An index more negative than `-length`
returns `none`.

```
list.at(0)     // first element
list.at(-1)    // last element
list.at(-2)    // second-to-last
```

#### `map` callback signature

The `map` callback receives two arguments: the element and its index:

```
def main() {
    let nums = List.empty!<Int>()
    nums.push(10)
    nums.push(20)
    nums.push(30)

    let doubled = nums.map!<Int>(fn (n: Int, i: Int) -> n * 2)
    // doubled = [20, 40, 60]

    let with_index = nums.map!<Str>(fn (n: Int, i: Int) -> i.Str() + ":" + n.Str())
    // with_index = ["0:10", "1:20", "2:30"]
}
```

#### `sort` comparator

Returns negative if first argument should come before second, zero if equal, positive otherwise.
`Int.compare` is a convenient comparator:

```
def sorted_both_ways(nums: List<Int>) {
    let sorted = nums.sort(fn (a: Int, b: Int) -> a.compare(b))    // ascending
    let desc = nums.sort(fn (a: Int, b: Int) -> b.compare(a))      // descending
}
```

`sort` returns a new list and leaves the original unchanged.

#### `index_of` and `contains` custom comparator

By default these use pointer equality (`#unchecked_cast(Int, a) == #unchecked_cast(Int, b)`),
which works for `Int`, `Bool`, and `Char`. For `Str` or class instances you must provide a
comparator:

```
def main() {
    let strs = List.empty!<Str>()
    strs.push("hello")
    strs.push("world")

    let idx = strs.index_of("hello", fn (a: Str, b: Str) Bool -> a == b)
    print(idx.unwrap().Str())    // 0
}
```

#### Capacity growth

When `push` exceeds capacity, the list reallocates with double the current capacity. The initial
default capacity when growing from zero is 64 bytes (8 elements).

#### Full example

```
def main() {
    let nums = List.empty!<Int>()
    nums.push(10)
    nums.push(20)
    nums.push(30)

    print(nums.len().Str())                   // 3
    print(nums.at(0).unwrap().Str())          // 10
    print(nums.at(-1).unwrap().Str())         // 30
    print(nums.at(5).or(-1).Str())            // -1

    let doubled = nums.map!<Int>(fn (n: Int, i: Int) -> n * 2)

    let big = nums.filter(fn (n: Int) -> n > 15)
    print(big.len().Str())                    // 2

    let sorted = nums.sort(fn (a: Int, b: Int) -> a.compare(b))

    let combined = nums.concat(doubled)
    print(combined.len().Str())               // 6

    nums.remove_at(0)
    print(nums.len().Str())                   // 2
}
```

---

### `std/option.md` — `Option<T>`

**Purpose:** Reference for optional values and patterns for safe null handling.

#### Definition

`class Option<T>` — wraps either a value of type `T` (`some`) or nothing (`none`). The field
`is_some: Bool` distinguishes the two states.

The `T?` shorthand is exactly equivalent to `Option<T>`.

#### Creating values

```
def main() {
    let present = Option.some!<Int>(42)
    let absent  = Option.none!<Int>()

    // Using the shorthand type
    let a: Int? = Option.some!<Int>(5)
}
```

The type argument to `some` must match the declared type:

```
Option.some!<Str>(1)    // TypeError: Int given for Str
Option.some(1)          // TypeError: must provide type argument
```

#### Methods

| Method        | Signature | Description |
|---------------|-----------|-------------|
| `some`        | `static <From>(value: From) Option<From>` | Wrap a value |
| `none`        | `static <From>() Option<From>` | Create an empty option |
| `is_some`     | `Bool` field | `true` if this holds a value |
| `unwrap`      | `(self, err_message="Unwrapping None Option") T` | Get the value, or `panic` with the given message |
| `or`          | `(self, default_value: T) T` | Get the value, or return the default |
| `map`         | `<U>(self, f: Fn(T) U) Option<U>` | Transform the value if present; propagates `none` |
| `is_some_and` | `(self, f: Fn(T) Bool) Bool` | `true` if present and predicate holds; `false` for `none` |
| `??`          | `(self, value: T) T` | None-coalescing: same as `or` |

#### The none-coalescing operator

`x ?? default` is equivalent to `x.or(default)`:

```
def main() {
    let a: Int? = Option.none!<Int>()
    let b: Int? = Option.some!<Int>(1)
    let c = Option.some!<Int>(0)

    print((a ?? 5).Str())    // 5  (none → default)
    print((b ?? 5).Str())    // 1  (some(1) → 1)
    print((c ?? 5).Str())    // 0  (some(0) → 0, not 5!)
}
```

#### Chaining multiple `?`

Multiple `?` annotations produce nested options:

```
def main() {
    let mut op_op: Result<Int?, Str>???
    // type: Option<Option<Option<Result<Option<Int>, Str>>>>
}
```

#### Full example

```
def main() {
    let x: Int? = Option.some!<Int>(5)
    print(x.is_some.Str())            // true
    print(x.unwrap().Str())           // 5
    print(x.or(0).Str())              // 5
    print((x ?? 99).Str())            // 5

    let y: Int? = Option.none!<Int>()
    print(y.is_some.Str())            // false
    print(y.or(0).Str())              // 0
    print((y ?? 99).Str())            // 99

    // map: transform if some
    let doubled = x.map!<Int>(fn (n: Int) -> n * 2)
    print(doubled.unwrap().Str())     // 10

    let none_doubled = y.map!<Int>(fn (n: Int) -> n * 2)
    print(none_doubled.is_some.Str()) // false

    // is_some_and
    print(x.is_some_and(fn (n: Int) -> n > 3).Str())    // true
    print(y.is_some_and(fn (n: Int) -> n > 3).Str())    // false

    // From List.at
    let list = List.empty!<Int>()
    list.push(7)
    print(list.at(0).unwrap().Str())    // 7
    print(list.at(5).or(-1).Str())      // -1
}
```

#### `typeof` returns

```
typeof Option.some!<Str>("hello")    // Option<Str>
typeof Option.none!<Str>()          // Option<Str>
```

The `?` shorthand produces the same type name:

```
def some() Str? { return Option.some!<Str>("hello") }
print(typeof some())    // Option<Str>
```

---

### `std/result.md` — `Result<T, E>`

**Purpose:** Reference for the success-or-error type.

#### Definition

`class Result<T, E>` — holds either a success value of type `T` or an error value of type `E`.
The `ok: Bool` field distinguishes the two cases.

#### Creating values

```
def main() {
    let success = Result.ok!<Int, Str>(42)
    let failure = Result.err!<Int, Str>("something went wrong")
}
```

`Result` has no `or` method; to get a value-or-default, convert first: `r.Option().or(0)`.

Note: the static constructor is `Result.ok!<T, E>(val)` — the name `ok` is shared with the
boolean field `result.ok`. These are distinct: the constructor is called on the class, the
field is accessed on an instance.

#### Methods

| Method   | Signature | Description |
|----------|-----------|-------------|
| `ok`     | `static <Val, Err>(val: Val) Result<Val, Err>` | Wrap a success value |
| `err`    | `static <Val, Err>(err: Err) Result<Val, Err>` | Wrap an error value |
| `ok`     | `Bool` field | `true` if success |
| `unwrap` | `(self) T` | Return the success value, or `panic` if error |
| `Option` | `(self) Option<T>` | Convert to `Option<T>` (discards the error) |
| `error`  | `(self) Option<E>` | Return the error as `Option<E>`, or `none` if success |

#### Full example

```
def main() {
    let r = Result.ok!<Int, Str>(42)
    print(r.ok.Str())         // true
    print(r.unwrap().Str())   // 42
    print(r.Option().unwrap().Str())    // 42

    let bad = Result.err!<Int, Str>("oops")
    print(bad.ok.Str())              // false
    print(bad.error().unwrap())      // oops
    print(bad.Option().is_some.Str()) // false
}
```

#### Parsing an integer (real usage)

```
def main() {
    let r = "42".Int()
    if r.ok {
        print(r.unwrap().Str())       // 42
    } else {
        print(r.error().unwrap())
    }

    let bad = "abc".Int()
    print(bad.ok.Str())              // false
    print(bad.error().unwrap())      // invalid character
}
```

---

### `std/range.md` — `Range` and `range()`

**Purpose:** Reference for integer ranges.

#### The `range()` function

Three forms:

| Form | Meaning |
|------|---------|
| `range(n)` | integers from `0` to `n` (exclusive), step `1` |
| `range(start, end)` | integers from `start` to `end` (exclusive), step `1` |
| `range(start, end, step)` | integers from `start` to `end` (exclusive), step `step` |

Step must not be `0`. Calling `range(a, b, 0)` panics with `Range.step cannot be 0` — **except**
when the call appears directly as the iterable of a `for` loop (`for i in range(1, 5, 0)`), which
the compiler lowers to a specialised loop that does not check the step; that loop never
terminates (known issue).

```
range(5)        // 0, 1, 2, 3, 4
range(2, 8)     // 2, 3, 4, 5, 6, 7
range(2, 8, 2)  // 2, 4, 6
range(3, 9, 2)  // 3, 5, 7
```

#### Empty ranges

`range(n)` with `n <= 0` produces no iterations, as does `range(start, end)` when `end <= 0`
and `start >= end`.

> **Known issue:** when `start >= end` but `end > 0` (for example `range(5, 1)`), the range
> currently yields exactly one value, `start`, instead of none. `range(5, 1).len()` returns `1`.
> The same happens for a negative step pointing away from `end` (`range(0, 10, -1)` yields `0`).

```
def main() {
    for i in range(-10) { print(i.Str()) }   // prints nothing
    for j in range(5, 1) { print(j.Str()) }  // prints 5 (see known issue above)
}
```

Negative steps count downwards when `start > end`:

```
def main() {
    for i in range(10, 0, -2) { print(i.Str(), ",") }    // prints 10,8,6,4,2,
}
```

#### The `Range` class

The `range()` function returns a `Range` value with fields `start`, `end`, and `step`.

`Range` is iterable — a `for` loop over a `Range` yields `Int` values.

```
def main() {
    for i in range(5) {
        print(i.Str(), ",")
    }
}
// prints 0,1,2,3,4,
```

With a step:

```
def main() {
    for i in range(3, 9, 2) {
        print(i.Str(), ",")
    }
}
// prints 3,5,7,
```

Using expressions as arguments:

```
def main() {
    for i in range(1 + 2) { print(i.Str(), "") }          // 012
    let n = 4
    for j in range(3 - 1, n + 1) { print(j.Str(), "") }  // 234
}
```

#### `Range` methods

| Method   | Signature         | Description |
|----------|-------------------|-------------|
| `len`    | `(self) Int`      | Number of elements in the range |
| `at_raw` | `(self, i: Int) Int` | Value at position `i` (0-based) |
| `List`   | `(self) List<Int>` | Materialise as a `List<Int>` |
| `Str`    | `(self) Str`      | `"Range(start, end, step)"` |

```
def main() {
    let r = range(3, 9, 2)
    print(r.len().Str())       // 3
    print(r.at_raw(0).Str())   // 3
    print(r.at_raw(1).Str())   // 5
    print(r.Str())             // Range(3, 9, 2)
    let l = range(3).List()    // List<Int> [0, 1, 2]
}
```

---

### `std/utf8str.md` — `Utf8Str`

**Purpose:** Explain the raw UTF-8 string type and when to use it versus `Str`.

#### Distinction from `Str`

`Str` stores each character as a 64-bit word for O(1) indexing. `Utf8Str` is a standard
null-terminated C-compatible UTF-8 byte string. It is used at OS boundaries.

The two types are not interchangeable — attempting to pass a `Utf8Str` where a `Str` is expected
is a type error, and vice versa.

#### When you encounter `Utf8Str`

Command-line arguments arrive as `List<Utf8Str>`:

```
def main(args: List<Utf8Str>) {
    for arg in args {
        print(arg.Str())    // convert before string operations
    }
}
```

The standard library converts to `Utf8Str` internally when calling into the OS (for example
inside `File.open`), so most programs only meet `Utf8Str` through `main`'s arguments.

#### Converting between the two types

- `Utf8Str` → `Str`: call `.Str()` on the `Utf8Str` value.
- `Str` → `Utf8Str`: call `.Utf8Str()` on the `Str` value.

```
def main(args: List<Utf8Str>) {
    let utf8_arg: Utf8Str = args.at_raw(0)
    let s: Str = utf8_arg.Str()
    let back: Utf8Str = s.Utf8Str()
}
```

#### When to use each

Use `Str` for all string operations inside your program. Convert to `Utf8Str` only when
interacting with the OS (passing to system calls, writing to files, passing to external C
functions).

`Str.utf8_size()` reports how many bytes the `Utf8Str` conversion will produce, which is
useful for buffer sizing.

---

### `std/ptr.md` — `Ptr<T>`

**Purpose:** Reference for the unsafe heap pointer type. Intended for advanced and low-level use.

#### Definition

`primitive Ptr<T>` — an unmanaged pointer to a heap-allocated value of type `T`. There is no
garbage collection or reference counting. The programmer is responsible for memory.

#### Creating a pointer

```
def main() {
    let p = Ptr.make!<Int>(42)
}
```

This allocates 8 bytes on the heap, stores `42`, and returns a pointer to that memory.

#### Methods

| Method    | Signature             | Description |
|-----------|-----------------------|-------------|
| `make`    | `static <From>(val: From) Ptr<From>` | Allocate and store a value |
| `unwrap`  | `(self) T`            | Dereference the pointer; no null check |
| `is_null` | `(self) Bool`         | True if the address is 0 (null pointer) |
| `Str`     | `(self) Str`          | `"Ptr(<address as decimal>)"` |

```
def main() {
    let p = Ptr.make!<Int>(42)
    print(p.is_null().Str())    // false
    print(p.unwrap().Str())     // 42
    print(p.Str())              // Ptr(4227744) — the address varies
}
```

A null pointer:

```
def main() {
    let null_ptr = #unchecked_cast(Ptr<Int>, 0)
    print(null_ptr.is_null().Str())    // true
    // calling null_ptr.unwrap() causes undefined behaviour
}
```

#### Safety

`Ptr<T>` bypasses the type system entirely. Dereferencing a null or invalid pointer is undefined
behaviour. Prefer `Option<T>` or `Result<T, E>` for safe optional/fallible values. Use `Ptr<T>`
only when interfacing directly with memory, system calls, or external C functions.

---

### `std/io.md` — I/O Functions

**Purpose:** Reference for `print`, `input`, `panic`, and `exit`.

#### `print`

```
def print(msg="", line_end="\n")
```

Writes `msg` to stdout, followed by `line_end`. Both parameters are `Str`.

With the default `line_end="\n"`, each call adds a newline:

```
print("Hello")      // Hello\n
print("World")      // World\n
```

To suppress the newline, pass an empty string as `line_end`:

```
print("Hello", "")    // Hello  (no newline)
print("World")        // World\n
```

To use a custom ending:

```
print("item", ", ")    // item, 
```

Precisely: if `line_end` is the empty string `""`, nothing beyond `msg` is printed (no
newline). If `line_end` is non-empty, it is appended after `msg`. The default `"\n"` appends a
newline.

`print` writes the string's internal UTF-64 bytes directly, so each character is followed by NUL
padding bytes (seven after each ASCII character). Terminals do not display them, but programs
reading the output (files, pipes, `grep`, test harnesses) will see them.

The `msg` argument defaults to `""`, so `print()` with no arguments prints an empty string
followed by the line_end.

#### `input`

```
def input(prompt="", buffer_size=1000) Str
```

Optionally prints `prompt` to stdout (without a newline), then reads a line from stdin up to
`buffer_size` bytes. The trailing newline is stripped. Returns the line as a `Str`.

```
def main() {
    let name = input("Enter your name: ")
    print("Hello, " + name + "!")
}
```

If the user types nothing and presses Enter, `input` returns `""`.

#### `panic`

```
def panic(msg="explicit panic")
```

Prints `"PANIC: " + msg` to stdout and exits with code `1`. Used for unrecoverable errors.

```
def divide(a: Int, b: Int) Int {
    if b == 0 -> panic("division by zero")
    return a / b
}
```

#### `exit`

```
def exit(code=0)
```

Terminates the program immediately with the given exit code. `0` conventionally means success.

```
exit(0)    // success
exit(1)    // failure
```

---

### `advanced/inline-assembly.md` — Inline Assembly (`#asm`)

**Purpose:** Reference for embedding raw x86-64 NASM assembly directly in Oxynium functions.

#### Syntax

```
#asm ReturnType "assembly string"
```

Or equivalently with parentheses grouping both arguments:

```
#asm (ReturnType, "assembly string")
```

The assembly string must be a compile-time string literal — not a variable or expression.

#### How it works

The assembly string is embedded verbatim into the generated NASM output. The result type tells
the compiler what type to treat the result as. For non-`Void` return types, the assembly must
push the result onto the stack before control returns to the surrounding Oxynium code.

#### Accessing function parameters

Parameters are available on the stack relative to `rbp`:

| Parameter position | Address       |
|--------------------|---------------|
| 1st parameter      | `[rbp + 16]`  |
| 2nd parameter      | `[rbp + 24]`  |
| 3rd parameter      | `[rbp + 32]`  |
| nth parameter      | `[rbp + (8 + n*8)]` |

For instance methods, `self` is the first parameter at `[rbp + 16]`.

#### Examples

Returning a function argument:

```
def asm(arg: Str) Str {
    return #asm Str "
        push qword [rbp + 16]
    "
}
print(asm("hi"))    // hi
```

`typeof #asm Void ""` is `Void`.
`typeof #asm Int ""` is `Int`.
`typeof #asm List<Int> ""` is `List<Int>`.

#### Restrictions

- `#asm` is meant to be used inside a function body, where `[rbp + …]` refers to that function's
  parameters. (The compiler does not currently reject it at the top level.)
- The assembly string must be a literal, not a runtime variable:
  ```
  def main() {
      let s = ""
      #asm Void s    // TypeError: assembly must be a string literal
  }
  ```
- The type argument must be a valid Oxynium type, not a numeric literal or expression:
  ```
  #asm 1          // SyntaxError
  #asm (1)        // SyntaxError
  #asm ()         // SyntaxError
  ```
  Use either `#asm Type "..."` or `#asm (Type, "...")`. A comma without parentheses
  (`#asm Void, ""`) is not a supported form, although it is not currently rejected.
- For `Void` return type, nothing needs to be pushed to the stack.
- For any other return type, exactly one value must be pushed.

#### Platform note

Generated assembly targets x86-64 NASM syntax for Linux and macOS. Using `#asm` makes your code
non-portable to other architectures.

---

### `advanced/unchecked-cast.md` — Unsafe Type Casting (`#unchecked_cast`)

**Purpose:** Reference for reinterpreting a value as a different type without any runtime
conversion or check.

#### Syntax

```
#unchecked_cast(TargetType, expression)
```

#### Semantics

The bits of `expression` are reinterpreted directly as `TargetType`. No conversion occurs. This
is equivalent to a C-style `(TargetType)value` cast or Rust's `transmute`.

#### Common uses

Converting between pointer and integer types (used throughout the standard library):

```
#unchecked_cast(Ptr<Int>, 0)    // create a null pointer
#unchecked_cast(Int, my_ptr)    // pointer address as integer
```

Type-erasing a value for storage inside `Option` or `Result`:

```
// from Option's implementation:
value: #unchecked_cast(Int, value)    // store any T as Int
```

Casting `Char` to `Int`:

```
#unchecked_cast(Int, 'A')    // 65
```

#### Safety

Completely unsafe. There are no runtime checks. Misuse causes undefined behaviour:
- Reinterpreting a pointer as a value type can crash.
- Reinterpreting an invalid bit pattern as a structured type will produce garbage.

Use only when interfacing with low-level system code, inline assembly, or the foreign function
interface. Prefer `Int.Bool()`, `Char.Int()`, and other safe conversion methods where possible.

---

### `advanced/extern.md` — External Functions

**Purpose:** Guide for declaring and calling functions implemented outside Oxynium.

#### Declaration syntax

```
extern def function_name(param1: Type1, param2: Type2) ReturnType;
```

The trailing `;` is optional. A body is forbidden:

```
extern def f() {}    // SyntaxError: extern declarations cannot have a body
```

#### Rules and restrictions

- Cannot be named `main` — `extern def main()` is a `SyntaxError`.
- Cannot redeclare a built-in function — `extern def print()` is a `TypeError`.
- May have default parameter values (same syntax as regular functions).
- Duplicate parameter names are a `TypeError`.
- Calling an external function that is not defined in the generated assembly causes an
  `IoError` at compile time. The error comes from the assembler (NASM), before linking.

```
extern def f()            // valid declaration
f()                       // IoError: symbol `f' not defined
```

#### Valid declarations

```
extern def f()
extern def g(p: Int, a: Str = "hi") Str
```

#### Limitation: no C interop yet

The compiler does not emit an assembler `extern` directive for `extern def` declarations, so
calling any symbol that is not defined in the program's own assembly — including C library
functions such as `strlen` — fails with an `IoError` (``symbol `strlen' not defined``) before
linking. Providing an extra object file or library does not help.

Note also that `Str` values use the UTF-64 representation, so C functions expecting a `char *`
must be given a `Utf8Str` (`s.Utf8Str()`) rather than a `Str`.

The standard library reaches libc through inline assembly instead (see `_LibC` in
`std/target-linux/_libc.oxy`).

---

### `examples/euler.md` — Example Programs: Project Euler

**Purpose:** Worked examples demonstrating idiomatic Oxynium on real problems. For each problem:
the problem statement, a complete Oxynium solution, and a brief explanation of the language
features used.

#### Problem 1: Multiples of 3 or 5

Find the sum of all multiples of 3 or 5 below 1000. Expected output: `233168`.

```
def main() {
    let mut sum = 0
    for i in range(1000) {
        if i % 3 == 0 || i % 5 == 0 {
            sum += i
        }
    }
    print(sum.Str())
}
```

Features: `for` over `range`, `%`, `||`, `+=`, `Str()` conversion.

#### Problem 2: Even Fibonacci numbers

Find the sum of even-valued Fibonacci terms not exceeding four million.

```
def main() {
    let mut a = 1
    let mut b = 2
    let mut sum = 0
    while b <= 4000000 {
        if b % 2 == 0 -> sum += b
        let next = a + b
        a = b
        b = next
    }
    print(sum.Str())
}
```

Features: multiple `mut` variables, `while` with condition, arrow `if`.

#### Problems 3–8

Outline the solution approach and which Oxynium features each exercise:
- Problem 3 (largest prime factor): recursive helper functions, `while` with early `return`.
- Problem 4 (largest palindrome product): nested `for` loops, `Str` reversal with `.reversed()`,
  string equality.
- Problem 5 (smallest multiple): `%` for divisibility checks, loops.
- Problem 6 (sum square difference): `range`, arithmetic.
- Problem 7 (10001st prime): `List<Int>` for storing primes, helper function, `contains`.
- Problem 8 (largest product in a series): iterating over a `Str` to get `Char` values,
  `.is_digit()`, `.Int()` on `Char`.

---

### `examples/patterns.md` — Common Patterns

**Purpose:** Short, idiomatic recipes for common tasks.

#### Parsing user input

```
def main() {
    let line = input("Enter a number: ")
    let r = line.Int()
    if !r.ok -> panic("Not a number: " + line)
    print((r.unwrap() * 2).Str())
}
```

#### Building a string by joining a list

```
def main() {
    let words = List.empty!<Str>()
    words.push("Hello")
    words.push("world")
    print(" ".join(words))    // Hello world
}
```

#### Counting matching elements

```
def count_evens(nums: List<Int>) Int {
    let evens = nums.filter(fn (n: Int) -> n % 2 == 0)
    return evens.len()
}
```

#### Finding an element by value

For `Str` lists, provide a comparator to `index_of`:

```
def report(list: List<Str>) {
    let idx = list.index_of("target", fn (a: Str, b: Str) -> a == b)
    if idx.is_some {
        print("Found at " + idx.unwrap().Str())
    } else {
        print("Not found")
    }
}
```

#### Map then filter

`Result` has no `or` method, so convert the parse result to an `Option` first:

```
def positive_numbers(raw_strings: List<Str>) List<Int> {
    return raw_strings
        .map!<Int>(fn (s: Str, i: Int) -> s.Int().Option().or(0))
        .filter(fn (n: Int) -> n > 0)
}
```

#### Sorting with a custom comparator

`Str` does not support `<` or `>`, so a string comparator has to compare characters itself.
For example, ordering strings by length:

```
def by_length(words: List<Str>) List<Str> {
    return words.sort(fn (a: Str, b: Str) -> a.len().compare(b.len()))
}
```

Using `Int.compare` for integers:

```
def ascending(nums: List<Int>) List<Int> {
    return nums.sort(fn (a: Int, b: Int) -> a.compare(b))
}
```

#### Using `Result` for safe parsing

```
def parse_positive(s: Str) Result<Int, Str> {
    let r = s.Int()
    if !r.ok -> return Result.err!<Int, Str>("Not a number")
    let n = r.unwrap()
    if n <= 0 -> return Result.err!<Int, Str>("Must be positive")
    return Result.ok!<Int, Str>(n)
}

def main() {
    let r = parse_positive("42")
    if r.ok {
        print(r.unwrap().Str())    // 42
    } else {
        print(r.error().unwrap())
    }
}
```

#### Accumulating with a mutable variable

```
def sum_list(list: List<Int>) Int {
    let mut total = 0
    for n in list {
        total += n
    }
    return total
}
```

#### Recursive data processing

```
def sum(list: List<Int>, i: Int) Int {
    if i >= list.len() -> return 0
    return list.at_raw(i) + sum(list, i + 1)
}
```

#### Higher-order function pipeline

```
def apply<T>(t: T, f: Fn(T) T) T -> f(t)

def main() {
    let result = apply!<Int>(5, fn (n: Int) -> n * n)
    print(result.Str())    // 25
}
```

#### Splitting and processing a string

```
def main() {
    let parts = "a,b,c,d".split(",")
    for part in parts {
        print(part, " ")
    }
    // prints a b c d
}
```

#### Iterating over characters with index

```
def main() {
    for c, i in "hello" {
        if c == 'l' {
            print("l at " + i.Str())
        }
    }
    // l at 2
    // l at 3
}
```

---

## Cross-cutting writing guidance

Every page should follow these rules:

1. **Open with a definition paragraph** — one to two sentences saying precisely what the feature
   is and what problem it solves.

2. **Strict reference first, guide second** — start with the syntax rule or type signature, then
   give examples. Never give examples without also giving the rule.

3. **Every error condition must be named** — always state the exact error kind (`SyntaxError`,
   `TypeError`, `UnknownSymbol`, `IoError`, `NumericOverflow`) alongside the description of
   what triggers it. Do not write "this will fail" without saying how it fails.

4. **Show output on examples** — after every code block that prints something, show the output
   in a comment or directly below.

5. **Type restrictions must be explicit** — whenever an operator or function only works on
   specific types, say so, and say what happens when the wrong type is used.

6. **Immutability distinctions matter** — be precise about whether a restriction applies to
   `let` (binding), `let mut` (binding), or field assignment (separate from binding). These
   are different in Oxynium.

7. **The `advanced/` pages must carry a safety warning** — each page in `advanced/` should open
   with a short warning that the feature bypasses type-safety guarantees and should only be used
   when necessary.

8. **Iterable types should be identified** — on every type's page, state clearly whether it
   can be used in a `for` loop, and what element type the loop variable will have.

9. **Keep method tables consistent** — all method tables should show: method name, full
   signature including `self` and default values, one-line description.

10. **Do not introduce non-Oxynium concepts** — avoid explaining how a feature "works internally"
    unless the internal behaviour is directly observable (e.g. integer overflow, UTF-64 encoding,
    capacity growth).
