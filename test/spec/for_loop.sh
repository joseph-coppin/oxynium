describe 'For Loop'

expect '' '
    def main (args: List<Utf8Str>) {
        for a in args {}
        for b in args -> b
    }
'
expect '1,2,3,' '
    def main () {
        let arr = List.empty!<Int>();
        arr.push(1);
        arr.push(2);
        arr.push(3);
        for n in arr {
            print(n.Str(), ",");
        }
    }
'
expect 'a1b1a2b2' '
    def main () {
        let arr = List.empty!<Int>();
        arr.push(1);
        arr.push(2);
        for n in arr {
            for m in "ab" {
                print(m.Str(), n.Str());
            }
        }
    }
'
expect 'a b c ' '
    def main () {
        for c in "abc" {
            print(c.Str(), " ");
        }
    }
'
expect '0a 1b 2c ' '
    def main () {
        for c, i in "abc" {
            print(i.Str() + c.Str(), " ");
        }
    }
'
expect '2c' '
    def main () {
        for c, i in "abc" {}
        // variables still exist after loop,
        // holding the values from the last iteration
        print(i.Str() + c.Str());
    }
'
expect '2,15/1,1/2,4/4,18' '
    def main () {
        for x in range(3) {}
        print(x.Str(), ",");
        for y, j in range(10, 20, 5) {}
        print(y.Str() + "/" + j.Str(), ",");
        for z, k in range(5, 0, -2) {}
        print(z.Str() + "/" + k.Str(), ",");
        for w, n in range(10) {
            if w == 4 -> break
        }
        print(w.Str() + "/" + n.Str(), ",");
        let l = List.empty!<Int>();
        l.push(7);
        l.push(8);
        for e, f in l {}
        print(f.Str() + e.Str());
    }
'
expect '0true,1false,' '
    def main () {
        let arr = List.empty!<Bool>();
        arr.push(true);
        arr.push(false);
        for b, i in arr {
            print(i.Str() + b.Str(), ",");
        }
    }
'
expect '' '
    def main () {
        let arr = List.empty!<Int>();
        for i in arr {
            print(i.Str(), "");
            print(",", "");
        }
    }
'
expect_err 'TypeError' '
    def main () {
        for i in 1 {}
    }
'
expect_err 'TypeError' '
    def main () {
        for i in true {}
    }
'
expect_err 'SyntaxError' '
    def main () {
        for _$_ in "" {}
    }
'
expect_err 'SyntaxError' '
    def main () {
        for i, _$_ in "" {}
    }
'
expect_err 'SyntaxError' '
    def main () {
        for _$_, _$_ in "" {}
    }
'


describe 'break and continue in for loops'

expect '0,1,2,' '
    def main () {
        for i in range(5) {
            if i >= 3 -> break
            print(i.Str(), ",");
        }
    }
'
expect '0,1,2,34' '
    def main () {
        for i in range(5) {
            print(i.Str());
            if i >= 3 {
                continue
            }
            print(",");
        }
    }
'
expect '0,1,2,3456' '
    def main () {
        for i in range(8) {
            print(i.Str());
            if i > 5 -> break
            if i >= 3 -> continue
            print(",");
        }
    }
'
expect '12' $'
    def main () {
        for c, i in "abc" {
            if c == \'a\' ->
                continue
            print(i.Str())
        }
    }
'


describe 'for _ in range'

expect '0,1,2,3,4,' '
    def main () {
        for i in range(5) {
            print(i.Str(), ",");
        }
    }
'
expect '-3-2-1012345' '
    def main () {
        for i in range(-3, 0) {
            print(i.Str());
        }
        for j in range(3) {
            print(j.Str());
        }
        for k in range(3, 6) {
            print(k.Str());
        }
    }
'
expect '3,5,7,' '
    def main () {
        for i in range(3, 9, 2) {
            print(i.Str(), ",");
        }
    }
'
expect '012234' '
    def main () {
        for i in range(1 + 2) {
            print(i.Str())
        }

        let n = 4
        for j in range(3 - 1, n + 1) {
            print(j.Str())
        }
    }
'
expect '5432' '
    def main () {
        // empty, as start > end
        for i in range(5, 1) {
            print(i.Str())
        }
        for j in range(5, 1, -1) {
            print(j.Str())
        }
        for k in range(-10) {
            print(k.Str())
        }
    }
'