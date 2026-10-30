describe 'def print'

expect 'Hello, World!' 'print("Hello, World!")'
expect_err 'TypeError' 'print(1)'
expect_err 'TypeError' 'print(true)'
expect '' 'print("", "")'
expect_err 'TypeError' 'print("", true)'

expect '42135' '
    def g() {
        print(1.Str());
    };
    def f() {
        print(2.Str());
        g();
        print(3.Str());
    };
    print(4.Str());
    f();
    print(5.Str());
'

describe 'print writes UTF-8'

# 'a', newline
expect_stdout_hex '610a' 'print("a")'
expect_stdout_hex '' 'print("", "")'
# 'é' is c3 a9, '💖' is f0 9f 92 96
expect_stdout_hex 'c3a9f09f9296' 'print("é💖", "")'
expect_stdout_hex '612c62' 'print("a", ","); print("b", "")'
