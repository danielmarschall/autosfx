unit Functions;

interface

uses
  Forms, Windows, Classes, SysUtils, ShellAPI, ShlObj, ActiveX,
  ZipMstr19, ZmUtils19;

type
  TLineBreak = (lbWindows, lbLinux, lbMac);

function RawFileCopy(ASrc, ADst: string): boolean;
function ShellExecuteAndWait(FileName: string; Params: string): boolean;
function FileSize(AFilename: string): int64;
function LooksLikeDir(s: string): boolean;
function GetTempDirectory: String;
function NormalizeLineBreaks(s: string; mode: TLineBreak): string;
function ExtractFileNameWithoutExt(const fil: string): string;
function SearchNextFreeName(s: string; wantDir: boolean): string;
function AdvSelectDirectory(const Caption: string; const Root: WideString;
  var Directory: string; EditBox: Boolean = False; ShowFiles: Boolean = False;
  AllowCreateDirs: Boolean = True): Boolean;
function GetSpecialFolderPath(const Folder: integer): string;
function IsExtractable(AFilename: string): boolean;

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

function SearchNextFreeName(s: string; wantDir: boolean): string;
var
  i: integer;
begin
  if not FileExists(s) and not DirectoryExists(s) then
  begin
    result := s;
    if wantDir then result := IncludeTrailingPathDelimiter(result);
    Exit;
  end;

  i := 2;

  if wantDir then
  begin
    s := ExcludeTrailingPathDelimiter(s);
    repeat
      result := Format('%s (%d)', [s, i]);
      inc(i);
    until not DirectoryExists(result) and not FileExists(result);
    result := IncludeTrailingPathDelimiter(result);
  end
  else
  begin
    repeat
      result := Format('%s (%d)%s', [ExtractFilePath(s)+ExtractFileNameWithoutExt(s), i, ExtractFileExt(s)]);
      inc(i);
    until not DirectoryExists(result) and not FileExists(result);
  end;
end;

{
  This code shows the SelectDirectory dialog with additional expansions:
  - an edit box, where the user can type the path name,
  - also files can appear in the list,
  - a button to create new directories.


  Dieser Code zeigt den SelectDirectory-Dialog mit zusätzlichen Erweiterungen:
  - eine Edit-Box, wo der Benutzer den Verzeichnisnamen eingeben kann,
  - auch Dateien können in der Liste angezeigt werden,
  - eine Schaltfläche zum Erstellen neuer Verzeichnisse.


  Ref: http://www.swissdelphicenter.ch/de/showcode.php?id=1802
}

function AdvSelectDirectory(const Caption: string; const Root: WideString;
  var Directory: string; EditBox: Boolean = False; ShowFiles: Boolean = False;
  AllowCreateDirs: Boolean = True): Boolean;
  // callback function that is called when the dialog has been initialized
  //or a new directory has been selected

  // Callback-Funktion, die aufgerufen wird, wenn der Dialog initialisiert oder
  //ein neues Verzeichnis selektiert wurde
  function SelectDirCB(Wnd: HWND; uMsg: UINT; lParam, lpData: lParam): Integer;
    stdcall;
//  var
//    PathName: array[0..MAX_PATH] of Char;
  begin
    case uMsg of
      BFFM_INITIALIZED: SendMessage(Wnd, BFFM_SETSELECTION, Ord(True), Integer(lpData));
      // include the following comment into your code if you want to react on the
      //event that is called when a new directory has been selected
      // binde den folgenden Kommentar in deinen Code ein, wenn du auf das Ereignis
      //reagieren willst, das aufgerufen wird, wenn ein neues Verzeichnis selektiert wurde
      {BFFM_SELCHANGED:
      begin
        SHGetPathFromIDList(PItemIDList(lParam), @PathName);
        // the directory "PathName" has been selected
        // das Verzeichnis "PathName" wurde selektiert
      end;}
    end;
    Result := 0;
  end;
var
  WindowList: Pointer;
  BrowseInfo: TBrowseInfo;
  Buffer: PChar;
  RootItemIDList, ItemIDList: PItemIDList;
  ShellMalloc: IMalloc;
  IDesktopFolder: IShellFolder;
  Eaten, Flags: LongWord;
const
  // necessary for some of the additional expansions
  // notwendig für einige der zusätzlichen Erweiterungen
  BIF_USENEWUI = $0040;
  BIF_NOCREATEDIRS = $0200;
begin
  Result := False;
  if not DirectoryExists(Directory) then
    Directory := '';
  FillChar(BrowseInfo, SizeOf(BrowseInfo), 0);
  if (ShGetMalloc(ShellMalloc) = S_OK) and (ShellMalloc <> nil) then
  begin
    Buffer := ShellMalloc.Alloc(MAX_PATH);
    try
      RootItemIDList := nil;
      if Root <> '' then
      begin
        SHGetDesktopFolder(IDesktopFolder);
        IDesktopFolder.ParseDisplayName(Application.Handle, nil,
          POleStr(Root), Eaten, RootItemIDList, Flags);
      end;
      OleInitialize(nil);
      with BrowseInfo do
      begin
        hwndOwner := Application.Handle;
        pidlRoot := RootItemIDList;
        pszDisplayName := Buffer;
        lpszTitle := PChar(Caption);
        // defines how the dialog will appear:
        // legt fest, wie der Dialog erscheint:
        ulFlags := BIF_RETURNONLYFSDIRS or BIF_USENEWUI or
          BIF_EDITBOX * Ord(EditBox) or BIF_BROWSEINCLUDEFILES * Ord(ShowFiles) or
          BIF_NOCREATEDIRS * Ord(not AllowCreateDirs);
        lpfn    := @SelectDirCB;
        if Directory <> '' then
          lParam := Integer(PChar(Directory));
      end;
      WindowList := DisableTaskWindows(0);
      try
        ItemIDList := ShBrowseForFolder(BrowseInfo);
      finally
        EnableTaskWindows(WindowList);
      end;
      Result := ItemIDList <> nil;
      if Result then
      begin
        ShGetPathFromIDList(ItemIDList, Buffer);
        ShellMalloc.Free(ItemIDList);
        Directory := Buffer;
      end;
    finally
      ShellMalloc.Free(Buffer);
    end;
  end;
end;

function GetSpecialFolderPath(const Folder: integer): string;
var
  PIDL: PItemIDList;
  Path: array[0..MAX_PATH] of char;
  Malloc: IMalloc;
begin
  Path := '';
  if Succeeded((SHGetSpecialFolderLocation(0, Folder, PIDL))) then
    if (SHGetPathFromIDList(PIDL, Path)) then
      if Succeeded(ShGetMalloc(Malloc)) then
      begin
        Malloc.Free(PIDL);
        Malloc := nil;
      end;
  Result := Path;
end;

function IsExtractable(AFilename: string): boolean;
var
  q: integer;
  uz: TZipMaster19;
begin
  // TODO: Ist die Funktion gut? Fraglich, ob EOC64 ein Teil von EOC ist.
  uz := TZipMaster19.Create(nil);
  try
    q := uz.QueryZip(AFilename);
    result := true;
    if (q and zqbHasLocal) <> zqbHasLocal then result := false;
    if (q and zqbHasCentral) <> zqbHasCentral then result := false;
    if ((q and zqbHasEOC) <> zqbHasEOC) and
       ((q and zqbHasEOC64) <> zqbHasEOC) then result := false;
  finally
    uz.Free;
  end;
end;

end.
