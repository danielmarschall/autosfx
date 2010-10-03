unit ExtractorMain;

{$DEFINE USE_DZIP_UNPACK} // recommended

interface

uses
  Windows, SysUtils, Classes, Controls, Forms, Dialogs, StdCtrls, ShellAPI,
  ExtCtrls, ComCtrls, ZipMstr19, ZMMsgStr19, ZMMsg19, ZMDelZip19,
  ZMCompat19, SFXBehavior, ShlObj;

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
    ExtractionInProcess: boolean;
    uz: TZipMaster19;
    RenamingOldPrefix: string;
    RenamingNewPrefix: string;
    zb: TZIPBehavior;
    BaseDir: string;
    AbortUnzip: boolean;
    StopAskingPassword: boolean;
    LastTriedPassword: string;
    CachedOverwriteDecision: TOverwriteDecision;
    {$IFNDEF USE_DZIP_UNPACK}
    procedure ExtractDllFromResource(ADirectory: string);
    {$ENDIF}
    procedure ExtractZipHere(AZipfile: string);
    procedure EvExtFNChange(Sender: TObject; var FileName: TZMString; const BaseDir: TZMString; var IsChanged: Boolean);
    procedure EvProgress(Sender: TObject; details: TZMProgressDetails);
    procedure EvTick(Sender: TObject);
    procedure EvCheckTerminate(Sender: TObject; var abort: Boolean);
    procedure EvConfirmOverwrite(Sender: TObject; const ForFile: TZMString;
      IsOlder: Boolean; var DoOverwrite: Boolean; DirIndex: Integer);
    procedure EvPasswordEvent(Sender: TObject; IsZipAction: Boolean;
      var NewPassword: String; const ForFile: TZMString; var RepeatCount: Longword;
      var Action: TMsgDlgBtn);
    procedure EvSkipEvent(Sender: TObject; const ForFile: TZMString;
      SkipType: TZMSkipTypes; var ExtError: Integer);
    function StripBaseDir(const s: string): string;
  end;

var
  MainForm: TMainForm;

implementation

uses
  ExtractorPassword, ExtractorError, Functions, SFXAutoRun, ExtractorComment,
  BrowseFolder;

const
  EvPasswordTries = 15;

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
  l: TStringList;
  s: string;
  ec: Integer;
  ar: TExecuteSFXAutoRunResult;
  GeneralBaseDir: string;
  ok: boolean;
const
  C_Explorer_Open_Param = '"%s"';
  C_Explorer_Select_Param = '/n,/select,"%s"';
  EXPLORER_EXE = 'explorer';
resourcestring
  Lng_Aborted = 'Der laufende Prozess wurde abgebrochen. Das extrahierten Dateien sind somit unvollständig.';
  Lng_Zip_Error = 'ZIP-Master Fehler "%s" (%d)';
  Lng_AutoRunFailed = 'SFX-AutoRun fehlgeschlagen. Die entpackten Inhalte werden nun angezeigt.';
  Lng_Unknown_Error = 'Unbekannter Fehler: Dateien sind nicht aufzufinden!';
  Lng_SelectDir = 'Bitte wählen Sie ein Verzeichnis zum Extrahieren aus. Es wird maximal 1 Datei bzw. Ordner erstellt!';
  Lng_WriteProtected = 'Das Verzeichnis ist nicht schreibbar! Bitte wählen Sie ein Anderes.';
begin
  AZipfile := ExpandUNCFileName(AZipfile);
  RenamingOldPrefix := '';
  RenamingNewPrefix := '';

  if Assigned(uz) then uz.Free; // uz ist global, damit AbortDLL aufgerufen werden kann

  uz := TZipMaster19.Create(nil);
  try
    ExtractionInProcess := true;
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

    uz.OnExtractOverwrite := EvConfirmOverwrite;
    uz.OnProgress := EvProgress;
    uz.OnTick := EvTick;
    uz.OnCheckTerminate := EvCheckTerminate;
    uz.OnPasswordError := EvPasswordEvent;
    uz.PasswordReqCount := EvPasswordTries;
    uz.OnSkipped := EvSkipEvent;
    uz.OnSetExtName := EvExtFNChange;

    // Find out base dirtory

    GeneralBaseDir := '';

    if zb.ExtractionTarget = etExtractHere then
    begin
      GeneralBaseDir := ExtractFilePath(AZipfile); // Default

      if not IsDirectoryWritable(GeneralBaseDir) or
         IsAtFlobbyDisk(GeneralBaseDir) then
      begin
        zb.ExtractionTarget := etDesktop;
      end;
    end;

    if zb.ExtractionTarget = etDesktop then
    begin
      GeneralBaseDir := GetSpecialFolderPath(CSIDL_DESKTOP);

      if not IsDirectoryWritable(GeneralBaseDir) or
         IsAtFlobbyDisk(GeneralBaseDir) then
      begin
        zb.ExtractionTarget := etAsk;
      end;
    end;

    if zb.ExtractionTarget = etAsk then
    begin
      repeat
        GeneralBaseDir := MySelectDirectory(Lng_SelectDir);
        if GeneralBaseDir = '' then Exit;

        ok := IsDirectoryWritable(GeneralBaseDir);
        if not ok then
        begin
          MessageDlg(Lng_WriteProtected, mtWarning, [mbOk], 0);
        end;
      until ok;
    end;

    GeneralBaseDir := IncludeTrailingPathDelimiter(GeneralBaseDir);

    // Semantic scanning of ZIP to determinate the final extraction directory

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
        BaseDir := GeneralBaseDir;
        s := BaseDir + l.Strings[0];

        RenamingOldPrefix := l.Strings[0]; // = StripBaseDir(S);

        if zb.ConflictBehavior = cbAvoid then
        begin
          s := SearchNextFreeName(s, LooksLikeDir(s));
        end;

        RenamingNewPrefix := StripBaseDir(s);
      end
      else
      begin
        // 2+ Objects = Extract them in a separate folder
        s := GeneralBaseDir + ExtractFileNameWithoutExt(AZipfile) + PathDelim;
        if zb.ConflictBehavior = cbAvoid then
        begin
          s := SearchNextFreeName(s, true);
          MkDir(s);
        end
        else
        begin
          if not DirectoryExists(s) then MkDir(s);
        end;
        BaseDir := s;
      end;
      BaseDir := IncludeTrailingPathDelimiter(BaseDir);

      uz.ExtrBaseDir := BaseDir;

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
        Hide;
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

          ShellExecute(0, 'open', EXPLORER_EXE,
            PChar(Format(C_Explorer_Open_Param, [s])), '', SW_NORMAL);
        end
        else if FileExists(s) then
        begin
          // If it is a file, then only select it

          // Que: Funktioniert das auch ohne "/n"?
          // Im Moment wird bei einem BESTEHENDEN Fenster
          // die Selektion nicht durchgeführt.

          ShellExecute(0, 'open', EXPLORER_EXE,
            PChar(Format(C_Explorer_Select_Param, [s])), '', SW_NORMAL);
        end
        else
        begin
          if not AbortUnzip then
          begin
            MessageDlg(Lng_Unknown_Error, mtError, [mbOk], 0);
          end;
        end;
      end;
    finally
      l.Free;
    end;
  finally
    uz.Free;
    ExtractionInProcess := false;
  end;
end;

procedure TMainForm.EvProgress(Sender: TObject; details: TZMProgressDetails);
begin
  CurrentFileLabel.Caption := details.ItemName;

  progressBar.Position := details.TotalPosition;
  progressBar.Max := details.TotalSize;

  itemBar.Position := details.ItemPosition;
  itemBar.Max := details.ItemSize;

  Application.ProcessMessages;
end;

procedure TMainForm.EvExtFNChange(Sender: TObject;
  var FileName: TZMString; const BaseDir: TZMString;
  var IsChanged: Boolean);
begin
  if RenamingOldPrefix = RenamingNewPrefix then Exit;
  FileName := RenamingNewPrefix + Copy(FileName, 1+Length(RenamingOldPrefix), Length(FileName)-Length(RenamingOldPrefix));
  IsChanged := true;
end;

procedure TMainForm.EvTick(Sender: TObject);
begin
  Application.ProcessMessages;
end;

procedure TMainForm.EvCheckTerminate(Sender: TObject; var abort: Boolean);
begin
  abort := AbortUnzip;
end;

procedure TMainForm.EvConfirmOverwrite(Sender: TObject; const ForFile: TZMString;
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

    if CachedOverwriteDecision = odUndefined then
    begin
      res := MessageDlg(Format(Lng_Overwrite, [ForFile]), mtConfirmation, [mbYes, mbNo, mbYesToAll, mbNoToAll], 0);
      DoOverwrite := (res = mrYes) or (res = mrYesToAll);
      if res = mrNoToAll then CachedOverwriteDecision := odOverwriteNothing;
      if res = mrYesToAll then CachedOverwriteDecision := odOverwriteAll;
    end
    else
    begin
      DoOverwrite := CachedOverwriteDecision = odOverwriteAll;
    end;
  end
  else if zb.ConflictBehavior = cbAvoid then
  begin
    // Nothing to do
  end;
end;

procedure TMainForm.EvPasswordEvent(Sender: TObject; IsZipAction: Boolean;
  var NewPassword: String; const ForFile: TZMString; var RepeatCount: Longword;
  var Action: TMsgDlgBtn);
var
  repc: integer;
begin
  repc := EvPasswordTries - RepeatCount + 1;

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

  if PasswordDlg.ShowModal(StripBaseDir(ForFile), repc, EvPasswordTries) = mrOk then
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
  if not ExtractionInProcess then
  begin
    Close;
    Exit;
  end;

  if MessageDlg(Lng_AbortExtract, mtConfirmation, mbYesNoCancel, 0) = mrYes then
  begin
    CancelBtn.Enabled := false;
    uz.AbortDLL;
    AbortUnzip := true;
    // Close wird durch den Timer durchgeführt
    Exit;
  end;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if not ExtractionInProcess then
  begin
    CanClose := true;
    Exit;
  end;

  if not AbortUnzip then
  begin
    CanClose := false;
    CancelBtn.Click;
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
resourcestring
  Lng_Extracting = 'Extrahiere Dateien. Bitte warten...';
begin
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
resourcestring
  Lng_NakedSFX = 'Das selbstentpackende Archiv (SFX) beschädigt oder ungültig. Wenn Sie diese Datei aus dem Internet bezogen haben, laden Sie sie bitte erneut herunter.';
  Lng_FileNotFound = 'Die durch Parameter angegebene Datei "%s" kann nicht gefunden werden!';
  Lng_TooManyArguments = 'Zu viele Argumente!';
begin
  AutoTimer.Enabled := false;

  {$IFNDEF USE_DZIP_UNPACK}
  ExtractDllFromResource(GetTempDirectory);
  {$ENDIF}

  try
    if IsExtractable(ParamStr(0)) then
    begin
      ExtractZipHere(ParamStr(0));
    end
    else
    begin
      // Der Extractor ist "nackt" oder das SFX beschädigt

      if ParamCount = 0 then
      begin
        MessageDlg(Lng_NakedSFX, mtError, [mbOk], 0);
      end
      else if ParamCount = 1 then
      begin
        // In diesem Zustand erlauben wir, fremde SFX zu entpacken (auch für Debugging-Zwecke)
        if FileExists(ParamStr(1)) then
        begin
          ExtractZipHere(ParamStr(1));
        end
        else
        begin
          MessageDlg(Lng_FileNotFound, mtError, [mbOk], 0);
        end;
      end
      else if ParamCount = 2 then
      begin
        // Future: Mehr als nur 1 Parameter erlauben?
        MessageDlg(Lng_TooManyArguments, mtError, [mbOk], 0);
      end;
    end;
  finally
    Close;
  end;
end;

function TMainForm.StripBaseDir(const s: string): string;
begin
  // Warnung: Es wird nicht überprüft, ob der String auch
  // wirklich mit dem BaseDir beginnt!
  result := Copy(s, Length(BaseDir)+1, Length(s)-Length(BaseDir));
end;

procedure TMainForm.EvSkipEvent(Sender: TObject; const ForFile: TZMString;
  SkipType: TZMSkipTypes; var ExtError: Integer);
resourcestring
  Lng_PasswordWrong = 'Das Passwort wurde zu oft falsch eingegeben. Die Datei "%s" wird nicht extrahiert.';
begin
  if (SkipType = stBadPassword) and not StopAskingPassword then
  begin
    MessageDlg(Format(Lng_PasswordWrong, [ForFile]), mtError, [mbOk], 0);
    LastTriedPassword := '';
  end;
  ErrorForm.NewError(ForFile, SkipType);
end;

end.
