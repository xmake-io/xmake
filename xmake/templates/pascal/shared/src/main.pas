program hello;

function fib(n: Int64): Int64;
  cdecl; external 'foo';

var
  Value: Integer;
begin
  Value := 5;
  WriteLn(fib(Value));
end.


