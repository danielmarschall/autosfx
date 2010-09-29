program RemoveSignature;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  Windows,
  ImageHlp;

resourcestring
  LNG_NOTFOUND = 'File not found';
  LNG_REMOVE = 'Remove certificate from "%s".';
  LNG_ERROR = 'Error while removing certificate. Error code: %s';
  LNG_OPEN_ERROR = 'Error while opening file. Error code: %s.';
  LNG_OK = 'OK';

var
  fil, err: String;
  x: Cardinal;
  i: integer;

begin
  WriteLn('ViaThinkSoft RemoveSignature');
  WriteLn('');
  WriteLn('Usage:');
  WriteLn('RemoveSignature.exe [File1 [File2 ...]]');
  WriteLn('');
  
  for i := 1 to ParamCount do
  begin
    fil := ParamStr(i);

    WriteLn(Format(LNG_REMOVE, [fil]));
    Write(#9);

    if not FileExists(fil) then
    begin
      WriteLn(Format(LNG_NOTFOUND, [fil]));
      ExitCode := 1;
      Exit;
    end;

    x := CreateFile(PChar(fil), GENERIC_READ or GENERIC_WRITE, 0,
      nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
    try
      if x = INVALID_HANDLE_VALUE then
      begin
        ExitCode := 1;
        err := IntToHex(GetLastError, 8);
        WriteLn(Format(LNG_OPEN_ERROR, [err]));
      end
      else
      begin
        if not ImageRemoveCertificate(x, 0) then
        begin
          ExitCode := 1;
          err := IntToHex(GetLastError, 8);
          WriteLn(Format(LNG_ERROR, [err]));
        end
        else
        begin
          WriteLn(LNG_OK);
        end;
      end;
    finally
      CloseHandle(x);
    end;
  end;

  Sleep(2000);
end.
