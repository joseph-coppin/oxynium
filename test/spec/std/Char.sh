describe 'primitive Char'

expect 'Char Char' "
print(typeof new Char, \" \")
print(typeof 'a')
"

describe 'def Char.Str'

expect '' 'print(new Char.Str())'
expect 'a' "print('a'.Str())"
expect 'ab' "print('a'.Str() + 'b'.Str())"
expect '💖' "print('💖'.Str())"
expect '10' "print(#unchecked_cast(Int, '\n').Str())"
expect '65' "print(#unchecked_cast(Int, 'A').Str())"
expect $'\'' "print('\\''.Str())"
expect '"' "print('\"'.Str())"

describe 'def Char.is_digit'

expect 'true,true,true,false,false,false,false' "
    print('0'.is_digit().Str());
    print(','.Str());
    print('4'.is_digit().Str());
    print(','.Str());
    print('9'.is_digit().Str());
    print(','.Str());
    print(' '.is_digit().Str());
    print(','.Str());
    print('a'.is_digit().Str());
    print(','.Str());
    print('Z'.is_digit().Str());
    print(','.Str());
    print('💖'.is_digit().Str());
"


describe 'def Char.=='

expect 'true,false,true,false,false' $'
    print((\'a\' == \'a\').Str(), ",")
    print((\'a\' == \'b\').Str(), ",")
    print((\'💖\' == \'💖\').Str(), ",")
    print(("🇨🇦".at_raw(0) == "🇦".at_raw(0)).Str(), ",")
    print((\'é\' == \'x\').Str())
'


describe 'def Char.!='

expect 'false,true,false,true,true' $'
    print((\'a\' != \'a\').Str(), ",")
    print((\'a\' != \'b\').Str(), ",")
    print((\'💖\' != \'💖\').Str(), ",")
    print(("🇨🇦".at_raw(0) != "🇦".at_raw(0)).Str(), ",")
    print((\'é\' != \'x\').Str())
'


describe 'def Char.from_int'

expect_expr_int '' 'Char.from_int(0)'
expect_expr_int 'a' 'Char.from_int(97)'
expect_expr_int 'A' 'Char.from_int(65)'
expect_expr_int '0' 'Char.from_int(48)'
expect_expr_int ' ' 'Char.from_int(32)'
expect_expr_int 'é' 'Char.from_int(233)'
expect_expr_int '€' 'Char.from_int(8364)'
expect_expr_int '💖' 'Char.from_int(128150)'
expect_expr_bool 'true' $'Char.from_int(233) == \'é\''
expect_expr_bool 'true' $'Char.from_int(128150) == \'💖\''


describe 'def Char.Int'

expect_expr_int '0' 'new Char.Int()'
expect_expr_int '97' $'\'a\'.Int()'
expect_expr_int '233' $'\'é\'.Int()'
expect_expr_int '8364' $'\'€\'.Int()'
expect_expr_int '128150' $'\'💖\'.Int()'
# round trips at the boundaries between UTF-8 lengths
expect '127,128,2047,2048,65535,65536,1114111' '
    print(Char.from_int(127).Int().Str(), ",")
    print(Char.from_int(128).Int().Str(), ",")
    print(Char.from_int(2047).Int().Str(), ",")
    print(Char.from_int(2048).Int().Str(), ",")
    print(Char.from_int(65535).Int().Str(), ",")
    print(Char.from_int(65536).Int().Str(), ",")
    print(Char.from_int(1114111).Int().Str())
'