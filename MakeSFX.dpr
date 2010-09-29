program MakeSFX;

{$APPTYPE CONSOLE}

{.$DEFINE BREAK_ON_CERT_FAILURE}
{$DEFINE DELAY_ON_ERROR}

uses
  SysUtils,
  Windows,
  Classes,
  ZipMstr19,
  Functions in 'Functions.pas',
  SFXBehavior in 'SFXBehavior.pas';

const
  Extractor_EXE = 'Extractor.exe';
  SIGN_BAT = 'Tools\VTSSign.bat';
  ZIP_EXE = 'Tools\zip.exe';
  RemoveSignature_EXE = 'Tools\RemoveSignature.exe';

var
  Src, Dst: string;
  i: integer;
  s1, s2: TFileStream;
  x: TZipMaster19;

resourcestring
  ImportantFileNotFound = 'Error: Important file "%s" not found!';
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
  Lng_Title = 'ViaThinkSoft AutoSFX';
  Lng_Usage1 = 'Usage:';
  Lng_Usage2 = 'MakeSFX [File1.zip [File2.zip...]]';

{$R *.res}

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

  for i := 1 to ParamCount do
  begin
    Src := ParamStr(i);

    if not FileExists(Src) then
    begin
      WriteLn(Format(SourceFileNotFound, [Src]));
      {$IFDEF DELAY_ON_ERROR}
      Sleep(2000);
      {$ENDIF}
      ExitCode := 1;
      Continue;
    end;

    Dst := ChangeFileExt(Src, '.exe');

    WriteLn(Format(Lng_In+#9+'%s', [Src]));
    WriteLn(Format(Lng_Out+#9+'%s', [Dst]));
    WriteLn('');

    if not RawFileCopy(ExtractFilePath(ParamStr(0)) + Extractor_EXE, Dst) then
    begin
      WriteLn(Format(LngErrorWhileCopy, [Extractor_EXE, Dst]));
      {$IFDEF DELAY_ON_ERROR}
      Sleep(2000);
      {$ENDIF}
      ExitCode := 1;
      Continue;
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
      Continue;
      {$ENDIF}
    end;

    WriteLn(#9 + Lng_Append);

    s1 := TFileStream.Create(Dst, fmOpenWrite);
    try
      s1.Seek(0, soEnd);

      s2 := TFileStream.Create(Src, fmOpenRead or fmShareDenyWrite);
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
      Continue;
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
      Continue;
      {$ENDIF}
    end;

    WriteLn(#9 + Lng_Finished);
    WriteLn('');
  end;

  // TODO: Es gibt bei Win2000 auﬂerhalb des debuggers eine AV...
end.
