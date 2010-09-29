unit ExtractorMain;

{$DEFINE DEBUG_MODE}

{$DEFINE USE_DZIP_UNPACK}

// TODO: Implement ExtractionTarget switch

interface

uses
  Windows, SysUtils, Classes, Controls, Forms, Dialogs, StdCtrls, ShellAPI,
  ExtCtrls, ComCtrls, ZipMstr19, ZMMsgStr19, ZMMsg19, ZMDelZip19,
  ZMCompat19, SFXBehavior;

type
  TOverwriteDecision = (odUndefined, odOverwriteAll, odOverwriteNothing);

  TMainForm = class(TForm)
    ProgressBar: TProgressBar;
    WaitLabel: TLabel;
    CancelBtn: TButton;
    CurrentFileLabel: TLabel;
    AutoTimer: TTimer;
    itemBar: TProgressBar;
    procedure CancelBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure AutoTimerTimer(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    RenamingOldPrefix: string;
    RenamingNewPrefix: string;
    zb: TZIPBehavior;
    BaseDir: string;
    AbortUnzip: boolean;
    StopAskingPassword: boolean;
    LastTriedPassword: string;
    OverwriteDecision: TOverwriteDecision;
    {$IFNDEF USE_DZIP_UNPACK}
    procedure ExtractDllFromResource(ADirectory: string);
    {$ENDIF}
    procedure ExtractZipHere(AZipfile: string);
    procedure ArcExtFNChange(Sender: TObject; var FileName: TZMString; const BaseDir: TZMString; var IsChanged: Boolean);
    procedure ArcProzess(Sender: TObject; details: TZMProgressDetails);
    procedure ArcTick(Sender: TObject);
    procedure ArcCheckTerminate(Sender: TObject; var abort: Boolean);
    procedure ConfirmOverwrite(Sender: TObject; const ForFile: TZMString;
      IsOlder: Boolean; var DoOverwrite: Boolean; DirIndex: Integer);
    procedure ArcPassword(Sender: TObject; IsZipAction: Boolean;
      var NewPassword: String; const ForFile: TZMString; var RepeatCount: Longword;
      var Action: TMsgDlgBtn);
    procedure SkipEvent(Sender: TObject; const ForFile: TZMString;
      SkipType: TZMSkipTypes; var ExtError: Integer);
    function StripBaseDir(const s: string): string;
  end;

var
  MainForm: TMainForm;

implementation

uses
  ExtractorPassword, ExtractorError, Functions, SFXAutoRun, ExtractorComment;

const
  MaxTries = 15;

{$R *.dfm}

{$R zmstr1900102\DLL\ResDLL-Maker\ZMRes19_dll.res}

function IsRootFile(s: string): boolean;
var
  i: integer;
begin
  if s = '' then
  begin
    result := false;
    Exit;
  end;
  if LooksLikeDir(s) then
  begin
    s := Copy(s, 1, Length(s)-1);
  end;
  for i := 1 to Length(s) do
  begin
    if s[i] = PathDelim then
    begin
      result := false;
      Exit;
    end;
  end;
  result := true;
end;

function FEListAll(theRec: TZMDirEntry; var Data): Integer;
var
  l: TStringList absolute Data;
  s: string;
begin
  Result := 0;

  s := theRec.FileName;
  l.Add(s);

  s := ExtractFilePath(s);
  if l.IndexOf(s) = -1 then l.Add(s);
end;

procedure ListRootFiles(uz: TZipMaster19; List: TStringList);
var
  s: string;
  l: TStringList;
  i: Integer;
resourcestring
  Lng_ForeachFailed = 'Dateiiteration fehlgeschlagen!';
begin
  List.Clear;

  l := TStringList.Create;
  try
    // Fill list (inclusive Directories)

    uz.FSpecArgs.Add('*');
    if uz.ForEach(FEListAll, l) <> 0 then
    begin
      MessageDlg(Lng_ForeachFailed, mtError, [mbOk], 0);
    end;

    // Now look for root files

    for i := 0 to l.Count - 1 do
    begin
      s := l.Strings[i];

      if IsRootFile(s) then
      begin
        List.Add(s);
      end;
    end;
  finally
    l.Free;
  end;
end;

procedure TMainForm.ExtractZipHere(AZipfile: string);
var
  uz: TZipMaster19;
  l: TStringList;
  s: string;
  ec: Integer;
  ar: TExecuteSFXAutoRunResult;
resourcestring
  Lng_Aborted = 'Der laufende Prozess wurde abgebrochen. Das extrahierten Dateien sind somit unvollständig.';
  Lng_Zip_Error = 'ZIP-Master Fehler "%s" (%d)';
  Lng_AutoRunFailed = 'SFX-AutoRun fehlgeschlagen. Die entpackten Inhalte werden nun angezeigt.';
  Lng_Unknown_Error = 'Unbekannter Fehler: Dateien sind nicht aufzufinden!';
begin
  AZipfile := ExpandUNCFileName(AZipfile);
  RenamingOldPrefix := '';
  RenamingNewPrefix := '';

  uz := TZipMaster19.Create(nil);
  try
    {$IFNDEF USE_DZIP_UNPACK}
    uz.DLLDirectory := GetTempDirectory + DelZipDLL_Name;
    {$ENDIF}
    uz.DLL_Load := true;

    uz.ZipFileName := AZipFile;
    uz.Active := true;
    zb := ReadBehavior(uz.ZipComment);

    uz.Unattended := true;
    uz.ExtrOptions := [ExtrDirNames, ExtrOverWrite, ExtrFreshen, ExtrUpdate,
      ExtrForceDirs, ExtrNTFS];

    if zb.ConflictBehavior <> cbAvoid then
    begin
      uz.OnExtractOverwrite := ConfirmOverwrite;
    end;
    uz.OnProgress := ArcProzess;
    uz.OnTick := ArcTick;
    uz.OnCheckTerminate := ArcCheckTerminate;
    uz.OnPasswordError := ArcPassword;
    uz.PasswordReqCount := MaxTries;
    // TODO: Mehr events?
    uz.OnSkipped := SkipEvent;
    uz.OnSetExtName := ArcExtFNChange;

    l := TStringList.Create;
    try
      // Count the root objects (files OR dirs) in the ZIP

      ListRootFiles(uz, l);

      if l.Count = 0 then
      begin
        // Empty ZIP or Extractor.exe was called without ZIP attached
        Exit;
      end
      else if l.Count = 1 then
      begin
        // 1 Object = Extract it right here!
        s := ExtractFilePath(AZipfile) + l.Strings[0];
        BaseDir := ExtractFilePath(AZipfile);
        RenamingOldPrefix := StripBaseDir(S);
        if zb.ConflictBehavior = cbAvoid then
        begin
          s := SearchNextFreeName(s);
        end;
        // TODO: helloworld.exe schlägt fehl!
        RenamingNewPrefix := StripBaseDir(S); // We need to change the name!
      end
      else
      begin
        // 2+ Objects = Extract them in a separate folder
        s := ChangeFileExt(AZipfile, '');
        if zb.ConflictBehavior = cbAvoid then
        begin
          s := SearchNextFreeName(s);
          MkDir(s);
        end
        else
        begin
          if not DirectoryExists(s) then MkDir(s);
        end;
        BaseDir := s;
      end;
      BaseDir := IncludeTrailingPathDelimiter(BaseDir);

      uz.ExtrBaseDir := BaseDir; // TODO: andere ordner erlauben

      // Pre-Extract-Dialog

      if zb.CommentPresentation = cpBeforeExtracting then
      begin
        if not CommentForm.ShowCommentModal(uz.ZipComment) then exit;
      end;

      // Extract

      ec := uz.Extract;

      if ec <> 0 then
      begin
        if ec = DS_Canceled then
        begin
          MessageDlg(Lng_Aborted, mtWarning, [mbOk], 0);
        end
        else
        begin
          MessageDlg(Format(Lng_Zip_Error, [uz.ErrMessage, ec]), mtError, [mbOk], 0);
        end;
      end;

      // Errors?

      if ErrorForm.ErrorsAvailable then
      begin
        ErrorForm.ShowModal;
      end;

      // Show After-Extracting comment?

      if zb.CommentPresentation = cpAfterExtracting then
      begin
        if not CommentForm.ShowCommentModal(uz.ZipComment) then exit;
      end;

      // Now search for an AutoRun.inf

      ar := ExecuteSFXAutoRun(BaseDir);

      if ar.AutoRunSectionAvailable and not ar.ExecutionSucceed then
      begin
        MessageDlg(Lng_AutoRunFailed, mtError, [mbOk], 0);
        ar.OpenUnzippedContent := true;
      end;

      // Now open the file for the user

      if not ar.AutoRunSectionAvailable or ar.OpenUnzippedContent then
      begin
        if DirectoryExists(s) then
        begin
          // If it is a folder, open it
          ShellExecute(0, 'open', 'explorer',
            PChar('"'+s+'"'), '', SW_NORMAL);
        end
        else if FileExists(s) then
        begin
          // If it is a file, then only select it

          // Que: Funktioniert das auch ohne "/n"?
          // Im Moment wird bei einem BESTEHENDEN Fenster
          // die Selektion nicht durchgeführt.

          ShellExecute(0, 'open', 'explorer',
            PChar('/n,/select,"'+s+'"'), '', SW_NORMAL);
        end
        else
        begin
          MessageDlg(Lng_Unknown_Error, mtError, [mbOk], 0);
        end;
      end;
    finally
      l.Free;
    end;
  finally
    uz.Free;
  end;
end;

procedure TMainForm.ArcProzess(Sender: TObject; details: TZMProgressDetails);
begin
  CurrentFileLabel.Caption := details.ItemName;

  progressBar.Position := details.TotalPosition;
  progressBar.Max := details.TotalSize;

  itemBar.Position := details.ItemPosition;
  itemBar.Max := details.ItemSize;

  Application.ProcessMessages;
end;

procedure TMainForm.ArcExtFNChange(Sender: TObject;
  var FileName: TZMString; const BaseDir: TZMString;
  var IsChanged: Boolean);
begin
  if RenamingOldPrefix = RenamingOldPrefix then Exit;

  FileName := RenamingNewPrefix + Copy(FileName, 1+Length(RenamingOldPrefix), Length(FileName)-Length(RenamingOldPrefix));
  IsChanged := true;
end;

procedure TMainForm.ArcTick(Sender: TObject);
begin
  Application.ProcessMessages;
end;

procedure TMainForm.ArcCheckTerminate(Sender: TObject; var abort: Boolean);
begin
  abort := AbortUnzip;
end;

procedure TMainForm.ConfirmOverwrite(Sender: TObject; const ForFile: TZMString;
  IsOlder: Boolean; var DoOverwrite: Boolean; DirIndex: Integer);
resourcestring
  Lng_Overwrite = 'Bestehende Datei "%s" überschreiben?';
var
  res: Integer;
begin
  if zb.ConflictBehavior = cbOverwrite then
  begin
    DoOverwrite := true;
    Exit;
  end
  else if zb.ConflictBehavior = cbNewer then
  begin
    DoOverwrite := IsOlder; // If file on DISK is older, then overwrite.
    Exit;
  end
  else if zb.ConflictBehavior = cbAsk then
  begin
    // Workaround: Verzeichnisse brauchen das nicht,
    // denn es wird bei den Dateien nochmal nachgefragt
    if LooksLikeDir(ForFile) then
    begin
      DoOverwrite := true;
      Exit;
    end;

    if OverwriteDecision = odUndefined then
    begin
      res := MessageDlg(Format(Lng_Overwrite, [ForFile]), mtConfirmation, [mbYes, mbNo, mbYesToAll, mbNoToAll], 0);
      DoOverwrite := (res = mrYes) or (res = mrYesToAll);
      if res = mrNoToAll then OverwriteDecision := odOverwriteNothing;
      if res = mrYesToAll then OverwriteDecision := odOverwriteAll;
    end
    else
    begin
      DoOverwrite := OverwriteDecision = odOverwriteAll;
    end;
  end;
end;

procedure TMainForm.ArcPassword(Sender: TObject; IsZipAction: Boolean;
  var NewPassword: String; const ForFile: TZMString; var RepeatCount: Longword;
  var Action: TMsgDlgBtn);
var
  repc: integer;
begin
  repc := MaxTries - RepeatCount + 1;

  // Eine Passworteingabe wurde abgebrochen. Frage nicht mehr nach.
  if StopAskingPassword then Exit;

  // Wurde schonmal ein Passwort eingegeben?
  if LastTriedPassword <> '' then
  begin
    // Schauen, ob das letzte Passwort auch mit dieser Datei geht.
    if repc = 1 then
    begin
      // Ja, geht
      NewPassword := LastTriedPassword;
      Exit;
    end
    else
    begin
      // Leider nein
      LastTriedPassword := '';
    end;
  end;

  if PasswordDlg.ShowModal(StripBaseDir(ForFile), repc, MaxTries) = mrOk then
  begin
    NewPassword := PasswordDlg.Password.Text;
    if NewPassword = '' then NewPassword := ' '; // Neue Eingabe erzwingen.
    LastTriedPassword := NewPassword;
  end
  else
  begin
    StopAskingPassword := true;
    Action := mbCancel;
  end;
end;

procedure TMainForm.CancelBtnClick(Sender: TObject);
resourcestring
  Lng_AbortExtract = 'Extrahieren abbrechen?';
begin
  if MessageDlg(Lng_AbortExtract, mtConfirmation, mbYesNoCancel, 0) = mrYes then
  begin
    CancelBtn.Enabled := false;
    AbortUnzip := true;
  end;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if not AbortUnzip then
  begin
    CancelBtn.Click;
    CanClose := false;
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
resourcestring
  Lng_Extracting = 'Extrahiere Dateien. Bitte warten...';
begin
  {$IFDEF DEBUG_MODE}
  Caption := Caption + ' (Debug)';
  {$ENDIF}
  WaitLabel.Caption := Lng_Extracting;
  WaitLabel.Left := progressBar.Width div 2 - WaitLabel.Width div 2;
  CurrentFileLabel.Caption := '';
end;

{$IFNDEF USE_DZIP_UNPACK}
procedure TMainForm.ExtractDllFromResource(ADirectory: string);
var
  s: TResourceStream;
  o: TFileStream;
  AOutFile: string;
begin
  AOutFile := IncludeTrailingPathDelimiter(ADirectory) + DelZipDLL_Name;
  s := TResourceStream.Create(0, DZRES_Dll, RT_RCDATA);
  try
    try
      s.Seek(SizeOf(Integer), soFromBeginning); // Ref: ZMDllLoad19.pas:427
      if FileExists(AOutFile) then
        o := TFileStream.Create(AOutFile, fmOpenWrite or fmShareDenyNone)
      else
        o := TFileStream.Create(AOutFile, fmCreate or fmShareDenyNone);
      try
        o.CopyFrom(s, s.Size-s.Position);
      finally
        o.Free;
      end;
    except
      if FileExists(AOutFile) then
      begin
        // Probably the file is write-locked (maybe some other Extractor is
        // using it right now? Even if we run into danger that the target DLL
        // is a write-protected old/incompatible version of DelZip190.dll,
        // we do count this as success, since the file exists.
      end
      else
      begin
        raise;
      end;
    end;
  finally
    s.Free;
  end;
end;
{$ENDIF}

procedure TMainForm.AutoTimerTimer(Sender: TObject);
begin
  AutoTimer.Enabled := false;

  {$IFNDEF USE_DZIP_UNPACK}
  ExtractDllFromResource(GetTempDirectory);
  {$ENDIF}

  try
    {$IFDEF DEBUG_MODE}
    if FileExists(ParamStr(1)) then
    begin
      ExtractZipHere(ParamStr(1));
    end
    else
    begin
    {$ENDIF}

    ExtractZipHere(ParamStr(0));

    {$IFDEF DEBUG_MODE}
    end;
    {$ENDIF}
  finally
    AbortUnzip := true; // Damit es zu keiner Abfrage kommt
    Close;
  end;
end;

function TMainForm.StripBaseDir(const s: string): string;
begin
  // Warnung: Es wird nicht überprüft, ob der String auch
  // wirklich mit dem BaseDir beginnt!
  result := Copy(s, Length(BaseDir)+1, Length(s)-Length(BaseDir));
end;

procedure TMainForm.SkipEvent(Sender: TObject; const ForFile: TZMString;
  SkipType: TZMSkipTypes; var ExtError: Integer);
resourcestring
  Lng_PasswordWrong = 'Das Passwort wurde zu oft falsch eingegeben. Die Datei "%s" wird nicht extrahiert.';
begin
  if (SkipType = stBadPassword) and not StopAskingPassword then
  begin
    MessageDlg(Format(Lng_PasswordWrong, [ForFile]), mtError, [mbOk], 0);
    LastTriedPassword := '';
  end;
  ErrorForm.NewError(StripBaseDir(ForFile));
end;

end.
