uses strings;

function SubStr(const CString: PChar; FromPos, ToPos: longint): PChar;
  cdecl; external 'foo';

var
  s: PChar;
  FromPos, ToPos: Integer;
begin
  s := strnew('TestMe');
  FromPos := 2;
  ToPos := 3;
  WriteLn(SubStr(s, FromPos, ToPos));
end.
