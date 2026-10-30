describe 'macro #asm'

expect 'Void' 'print(typeof #asm Void "")'
expect 'Void' 'print(typeof #asm Void, "")'
expect 'Void' 'print(typeof #asm (Void, ""))'
expect 'Int' 'print(typeof #asm Int "")'
expect 'List<Int>' 'print(typeof #asm List<Int> "")'
expect 'hi' '
    def asm(arg: Str) Str {
        return #asm Str "
            push qword [rbp + 16]
        "
    }
    print(asm("hi"))
'
expect '255' '
    // instructions starting with `mov` other than `mov` itself
    // must survive optimisation
    def f() Int {
        return #asm Int "
            mov rdx, 0x1FF
            movzx rax, dl
            push rax
        "
    }
    print(f().Str())
'

expect_err 'SyntaxError' '#asm 1'
expect_err 'SyntaxError' '#asm(1)'
expect_err 'SyntaxError' '#asm()'
expect_err 'SyntaxError' '#asm'
expect_err 'SyntaxError' '#asm Void, "")'
expect_err 'SyntaxError' '#asm("", 1)'
expect_err 'SyntaxError' '
    def main () {
        let s = "";
        #asm(s);
    }
'
expect_err 'TypeError' '
    def main () {
        let s = "";
        #asm Void s;
    }
'
expect_err 'SyntaxError' 'print(typeof #asm(1, ""))'
expect_err 'SyntaxError' 'print(typeof #asm("", ""))'