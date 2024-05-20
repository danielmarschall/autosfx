program MakeSFX;

{$APPTYPE CONSOLE}

{.$DEFINE BREAK_ON_CERT_FAILURE}
{$DEFINE DELAY_ON_ERROR}

uses
  SysUtils,
  Windows,
  Classes,
  ZipMstr19,
  Dialogs,
  Functions in 'Functions.pas',
  SFXBehavior in 'SFXBehavior.pas';

const
  Extractor_EXE = 'Extractor.exe';
  SIGN_BAT = 'Tools\VTSSign.bat';
  ZIP_EXE = 'Tools\zip.exe';
  RemoveSignature_EXE = 'Tools\RemoveSignature.exe';

procedure DoMakeSFX(AFilename: string);
var
  Dst: string;
  s1, s2: TFileStream;
  x: TZipMaster19;
resourcestring
  LngErrorWhileCopy = 'Error: Could not copy "%s" to "%s".';
  LngErrorWhileExecuting = 'Error while executing "%s".';
  SourceFileNotFound = 'Source file "%s" not found.';
  Lng_In = 'Input:';
  Lng_Out = 'Output:';
  Lng_RemoveSig = 'Remove signature of Extractor template...';
  Lng_Append = 'Append ZIP to Extractor template...';
  Lng_Adjust = 'Adjust the ZIP offset of the SFX...';
  Lng_ModifyZIPComment = 'Modify ZIP Comment...';
  Lng_SignSfx = 'Sign the SFX...';
  Lng_Finished = 'Finished! :-)';
begin
  if not FileExists(AFilename) then
  begin
    WriteLn(Format(SourceFileNotFound, [AFilename]));
    {$IFDEF DELAY_ON_ERROR}
    Sleep(2000);
    {$ENDIF}
    ExitCode := 1;
    Exit;
  end;

  Dst := ChangeFileExt(AFilename, '.exe');

  WriteLn(Format(Lng_In+#9+'%s', [AFilename]));
  WriteLn(Format(Lng_Out+#9+'%s', [Dst]));
  WriteLn('');

  if not RawFileCopy(ExtractFilePath(ParamStr(0)) + Extractor_EXE, Dst) then
  begin
    WriteLn(Format(LngErrorWhileCopy, [Extractor_EXE, Dst]));
    {$IFDEF DELAY_ON_ERROR}
    Sleep(2000);
    {$ENDIF}
    ExitCode := 1;
    Exit;
  end;

 // Remove the signature of Extractor first (otherwise signing will fail later)

  WriteLn(#9 + Lng_RemoveSig);

  if not ShellExecuteAndWait(ExtractFilePath(ParamStr(0)) + RemoveSignature_EXE, PChar('"' + ExpandUNCFileName(Dst) + '"')) then
  begin
    WriteLn(Format(LngErrorWhileExecuting, [RemoveSignature_EXE]));
    {$IFDEF BREAK_ON_CERT_FAILURE}
    DeleteFile(PChar(Dst));
    {$IFDEF DELAY_ON_ERROR}
    Sleep(2000);
    {$ENDIF}
    ExitCode := 1;
    Exit;
    {$ENDIF}
  end;

  WriteLn(#9 + Lng_Append);

  s1 := TFileStream.Create(Dst, fmOpenWrite);
  try
    s1.Seek(0, soEnd);

    s2 := TFileStream.Create(AFilename, fmOpenRead or fmShareDenyWrite);
    try
      s1.CopyFrom(s2, s2.Size);
    finally
      s2.Free;
    end;
  finally
    s1.Free;
  end;

  WriteLn(#9 + Lng_Adjust);

  if not ShellExecuteAndWait(ExtractFilePath(ParamStr(0)) + ZIP_EXE, PChar('-A "' + ExpandUNCFileName(Dst) + '"')) then
  begin
    DeleteFile(PChar(Dst));
    WriteLn(Format(LngErrorWhileExecuting, [ZIP_EXE]));
    {$IFDEF DELAY_ON_ERROR}
    Sleep(2000);
    {$ENDIF}
    ExitCode := 1;
    Exit;
  end;

  WriteLn(#9 + Lng_ModifyZIPComment);

  x := TZipMaster19.Create(nil);
  try
    x.ZipFileName := Dst;

    // Correct CRLFs

    x.ZipComment := NormalizeLineBreaks(x.ZipComment, lbWindows);

    // Ensure we have 2 CRLF before old comment

    x.ZipComment := TrimRight(x.ZipComment);
    if x.ZipComment <> '' then
    begin
      x.ZipComment := x.ZipComment + #13#10 + #13#10;
    end;

    // Read, strip and re-add behavior (inclusive signature)

    x.ZipComment := RelocateBehaviorStringsToEnd(x.ZipComment);
  finally
    x.Free;
  end;

  // Read filesize + zip-comment length
  // (So we can later extend the zip-comment to include the certificate
  // => The archive is then not corrupt because of 'garbage' at the end)

  WriteLn(#9 + Lng_SignSfx);

  if not ShellExecuteAndWait(ExtractFilePath(ParamStr(0)) + SIGN_BAT, PChar('"' + ExpandUNCFileName(Dst) + '"')) then
  begin
    WriteLn(Format(LngErrorWhileExecuting, [SIGN_BAT]));
    {$IFDEF BREAK_ON_CERT_FAILURE}
    DeleteFile(PChar(Dst));
    {$IFDEF DELAY_ON_ERROR}
    Sleep(2000);
    {$ENDIF}
    ExitCode := 1;
    Exit;
    {$ENDIF}
  end;

  WriteLn(#9 + Lng_Finished);
  WriteLn('');
end;

{$R *.res}

var
  i: integer;
  od: TOpenDialog;
resourcestring
  Lng_Title = 'ViaThinkSoft AutoSFX';
  Lng_Usage1 = 'Usage:';
  Lng_Usage2 = 'MakeSFX [File1.zip [File2.zip...]]';
  ImportantFileNotFound = 'Error: Important file "%s" not found!';
begin
  WriteLn(Lng_Title);
  WriteLn('');
  WriteLn(Lng_Usage1);
  WriteLn(Lng_Usage2);
  WriteLn('');

  if not FileExists(ExtractFilePath(ParamStr(0)) + Extractor_EXE) then
  begin
    WriteLn(Format(ImportantFileNotFound, [Extractor_EXE]));
    {$IFDEF DELAY_ON_ERROR}
    Sleep(2000);
    {$ENDIF}
    ExitCode := 2;
    Exit;
  end;

  if ParamCount = 0 then
  begin
    od := TOpenDialog.Create(nil);
    try
      od.DefaultExt := 'zip';
      od.Filter := 'ZIP-Archiv (*.zip)|*.zip|Alle Dateien (*.*)|*.*';
      od.Options := [ofAllowMultiSelect, ofFileMustExist, ofHideReadOnly,
        ofPathMustExist, ofEnableSizing];
      if od.Execute then
      begin
        for i := 0 to od.Files.Count - 1 do
        begin
          DoMakeSFX(od.Files.Strings[i]);
        end;
      end;
    finally
      od.Free;
    end;
  end
  else
  begin
    for i := 1 to ParamCount do
    begin
      DoMakeSFX(ParamStr(i));
    end;
  end;

  // TODO: Es gibt bei Win2000 auﬂerhalb des debuggers eine AV...
end.
