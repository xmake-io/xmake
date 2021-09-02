library foo;

function SubStr(CString: PChar;FromPos,ToPos: Longint): PChar; cdecl;

var
  Length: Integer;

begin
  Length := StrLen(CString);
  SubStr := CString + Length;
  if (FromPos > 0) and (ToPos >= FromPos) then
  begin
    if Length >= FromPos then
      SubStr := CString + FromPos;
    if Length > ToPos then
    CString[ToPos+1] := #0;
  end;
end;

exports
  SubStr;

end.
