unit Functions;

interface

uses
  Windows, Classes, SysUtils, ShellAPI;

type
  TLineBreak = (lbWindows, lbLinux, lbMac);

function RawFileCopy(ASrc, ADst: string): boolean;
function ShellExecuteAndWait(FileName: string; Params: string): boolean;
function FileSize(AFilename: string): int64;
function LooksLikeDir(s: string): boolean;
function GetTempDirectory: String;
function NormalizeLineBreaks(s: string; mode: TLineBreak): string;
function ExtractFileNameWithoutExt(const fil: string): string;
function SearchNextFreeName(s: string): string;

implementation

{$IFNDEF UNICODE}
type
  TCharSet = set of AnsiChar;
{$ENDIF}

{$IFNDEF UNICODE}
function CharInSet(C: AnsiChar; const CharSet: TCharSet): Boolean;// overload;
begin
  Result := c in CharSet;
end;
{$ENDIF}

function LooksLikeDir(s: string): boolean;
begin
  result := CharInSet(s[Length(s)], ['/', '\']);
end;

function RawFileCopy(ASrc, ADst: string): boolean;
var
  SSrc, SDst: TFileStream;
begin
  DeleteFile(PChar(ADst));

  SSrc := TFileStream.Create(ASrc, fmOpenRead);
  try
    SDst := TFileStream.Create(ADst, fmCreate);
    try
      SDst.CopyFrom(SSrc, SSrc.Size);
    finally
      SDst.Free;
    end;
  finally
    SSrc.Free;
  end;

  result := true;
end;

// http://www.delphipraxis.net/32234-shellexecuteandwait-status-abfragen.html
// Modified. Now CONSOLE compatible and return false if ErrorLevel <> 0
function ShellExecuteAndWait(FileName: string; Params: string): boolean;
var
  exInfo: TShellExecuteInfo;
  Ph: DWORD;
  lExitCode: DWord;
begin
  Try
    FillChar(exInfo, SizeOf(exInfo), 0);
    with exInfo do
    begin
      cbSize := SizeOf(exInfo);
      fMask := SEE_MASK_NOCLOSEPROCESS or SEE_MASK_FLAG_DDEWAIT;
      Wnd := GetActiveWindow();
      FileName := ExpandUNCFileName(FileName);
      ExInfo.lpVerb := 'open';
      ExInfo.lpParameters := PChar(Params);
//      ExInfo.lpDirectory := PChar(ExtractFilePath(FileName));
      lpFile := PChar(FileName);
      nShow := SW_SHOWNORMAL;
    end;
    if ShellExecuteEx(@exInfo) then
    begin
      Ph := exInfo.HProcess;
    end
    else
    begin
      WriteLn(SysErrorMessage(GetLastError));
      Result := False;
      Exit;
    end;
    while WaitForSingleObject(ExInfo.hProcess, 50) <> WAIT_OBJECT_0 do ;
    (* begin
      Application.ProcessMessages;
    end; *)
    GetExitCodeProcess(Ph, lExitCode);
    Result := lExitCode = 0;
    CloseHandle(Ph);
  Except
    Result := False;
    Exit;
  End;
end;

function FileSize(AFilename: string): int64;
var
  s: TFileStream;
begin
  s := TFileStream.Create(AFilename, fmOpenRead or fmShareDenyWrite);
  try
    result := s.Size;
  finally
    s.Free;
  end;
end;

// http://www.cryer.co.uk/brian/delphi/howto_get_temp.htm
function GetTempDirectory: String;
var
  tempFolder: array[0..MAX_PATH] of Char;
begin
  GetTempPath(MAX_PATH, @tempFolder);
  result := StrPas(tempFolder);
end;

function NormalizeLineBreaks(s: string; mode: TLineBreak): string;
begin
  if mode = lbWindows then
  begin
    s := StringReplace(s, #13#10, #10, [rfReplaceAll]);
    s := StringReplace(s, #13,    #10, [rfReplaceAll]);
    s := StringReplace(s, #10, #13#10, [rfReplaceAll]);
  end
  else if mode = lbLinux then
  begin
    s := StringReplace(s, #13#10, #13, [rfReplaceAll]);
    s := StringReplace(s, #10,    #13, [rfReplaceAll]);
  end
  else if mode = lbMac then
  begin
    s := StringReplace(s, #13#10, #10, [rfReplaceAll]);
    s := StringReplace(s, #13,    #10, [rfReplaceAll]);
  end;
  result := s;
end;

// http://www.viathinksoft.de/?page=codelib&showid=70
function ExtractFileNameWithoutExt(const fil: string): string;
begin
  result := Copy(ExtractFileName(fil), 1, Length(ExtractFileName(fil))-Length(ExtractFileExt(fil)));
end;

function SearchNextFreeName(s: string): string;
var
  i: integer;
begin
  if not FileExists(s) and not DirectoryExists(s) then
  begin
    result := s;
    Exit;
  end;

  i := 2;

  if FileExists(s) then
  begin
    repeat
      result := Format('%s (%d)%s', [ExtractFileNameWithoutExt(s), i, ExtractFileExt(s)]);
      inc(i);
    until not DirectoryExists(result);
  end
  else if DirectoryExists(s) then
  begin
    s := ExcludeTrailingPathDelimiter(s);
    repeat
      result := Format('%s (%d)', [s, i]);
      inc(i);
    until not DirectoryExists(result);                  // Todo: Legt man sich hier nun auf einen ordnernamen fest???
    result := IncludeTrailingPathDelimiter(result);
  end;
end;

end.
