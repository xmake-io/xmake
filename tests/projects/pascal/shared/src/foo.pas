library foo;

{$mode objfpc}{$H+}

function fib(n : Int64) : Int64; cdecl;
begin
  if n > 1 then
  begin
      Result := fib(n - 1) + fib(n - 2);
  end
  else
        Result := 1;
end;

exports
 fib;
end.


