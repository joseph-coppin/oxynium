![example workflow](https://github.com/revers3ntropy/oxynium/actions/workflows/tests.yml/badge.svg)

# Oxynium Compiler in Rust

Linux/MacOS x86-64 support only so far.

## Requirements

- nasm
- gcc

# Installation

`curl -sSL https://oxynium.org/scripts/install | bash`

### Unstable

*Can also install from development branch, which will include the latest features*

`curl -sSL https://oxynium.org/scripts/install | bash -s -- "latest"`

## Dev Requirements

- cargo
- rustc

#### For running full testing suite:

- python3
- Docker (and cli)

## Examples

See `test/spec/*` for more examples

```shell
$ oxy -e 'print("Hello, World!")' && ./oxy-out
Hello, World!
```

```shell
$ more hello_world.oxy
print("Hello, World!")
$ oxy hello_world.oxy && ./oxy-out
Hello, World!
```

## Usage

```shell
$ oxy [input_file?] [options]
```

### Options

| Command              | Type   | Description                                              | Default        |
|----------------------|--------|----------------------------------------------------------|----------------|
| `-o`, `--out`        | Str    | Output executable path (`.asm`/`.o` use it as a prefix) | `'oxy-out'`    |
| `-e`, `--eval`       | Str    | Pass the program source on the CLI                       |                |
| `-k`, `--keep`       | Flag   | Keep outputted `.asm` and `.o` files                     | off            |
| `-t`, `--target`     | String | Compilation target ('x86_64-linux' or 'macos')           | current system |
| `-O`, `--optimise`   | Int    | Optimisation level (0 or 1)                              | `1`            |
| `-E`, `--enable`     | String | Enable an optimisation                                   |                |
| `-D`, `--disable`    | String | Disable an optimisation                                  |                |
| `-v`, `--version`    | Flag   | Print the compiler version                               | off            |
| `--stop_after_asm`   | Flag   | Stop after emitting assembly                             | off            |
| `-d`, `--comp_debug` | Flag   | For debugging the compiler                               | off            |

#### Note for --eval

The value is a whole program, not an expression to print — use `print` to see a result.
Quote the input to escape shell expansion,
e.g. `oxy -e "print(((1+1)*2).Str())"` instead of `oxy -e print(((1+1)*2).Str())`