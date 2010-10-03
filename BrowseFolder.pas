unit BrowseFolder platform;

{.$DEFINE USE_FILECTRL_FUNCTIONS} // not recommended!

{$DEFINE USE_FORMS} // important

interface

uses
  Windows, SysUtils, ShlObj, ActiveX
  {$IFDEF USE_FILECTRL_FUNCTIONS}, FileCtrl{$ENDIF}
  {$IFDEF USE_FORMS}, Forms{$ENDIF};

function MySelectDirectory(AMsg: string): string;

implementation

{$IFNDEF USE_FILECTRL_FUNCTIONS}

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
  MODIFIED for AutoSFX!
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
  var
    PathName: array[0..MAX_PATH] of Char;
  begin
    case uMsg of
//      BFFM_INITIALIZED: SendMessage(Wnd, BFFM_SETSELECTION, Ord(True), Integer(lpData));
      // include the following comment into your code if you want to react on the
      //event that is called when a new directory has been selected
      // binde den folgenden Kommentar in deinen Code ein, wenn du auf das Ereignis
      //reagieren willst, das aufgerufen wird, wenn ein neues Verzeichnis selektiert wurde
      BFFM_SELCHANGED:
      begin
        SHGetPathFromIDList(PItemIDList(lParam), @PathName);

        if PathName = '' then
        begin
          SendMessage(Wnd, BFFM_ENABLEOK, 0, 0);
        end;

        // the directory "PathName" has been selected
        // das Verzeichnis "PathName" wurde selektiert
      end;
    end;
    Result := 0;
  end;
var
  {$IFDEF USE_FORMS}
  WindowList: Pointer;
  {$ENDIF}
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
        IDesktopFolder.ParseDisplayName({$IFDEF USE_FORMS}Application.Handle{$ELSE}0{$ENDIF}, nil,
          POleStr(Root), Eaten, RootItemIDList, Flags);
      end;
      OleInitialize(nil);
      with BrowseInfo do
      begin
        hwndOwner := {$IFDEF USE_FORMS}Application.Handle{$ELSE}0{$ENDIF};
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
      {$IFDEF USE_FORMS}
      WindowList := DisableTaskWindows(0);
      {$ENDIF}
      try
        ItemIDList := ShBrowseForFolder(BrowseInfo);
      finally
        {$IFDEF USE_FORMS}
        EnableTaskWindows(WindowList);
        {$ENDIF}
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

{$ENDIF}

function MySelectDirectory(AMsg: string): string;
begin
  {$IFNDEF USE_FILECTRL_FUNCTIONS}
  if not AdvSelectDirectory(AMsg, '', result, False, False, True) then
  begin
    result := '';
    Exit;
  end;
  {$ELSE}
  // Nicht so gut: "Arbeitsplatz" etc nicht ausgegraut
  if not SelectDirectory(AMsg, '', result, [sdNewUi, sdNewFolder]) then
  begin
    result := '';
    Exit;
  end;
  {$ENDIF}

  // Optional
  result := IncludeTrailingPathDelimiter(result);
  result := ExpandUNCFileName(result);
end;

end.
