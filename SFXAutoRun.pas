unit SFXAutoRun;

interface

uses
  SysUtils, Windows, IniFiles, ShellAPI;

type
  TExecuteSFXAutoRunResult = record
    AutoRunSectionAvailable: boolean;
    ExecutionSucceed: boolean;
    HInstance: Integer;
    OpenUnzippedContent: boolean;
  end;

function ExecuteSFXAutoRun(ADirectory: string): TExecuteSFXAutoRunResult;

implementation

function StrToShowCmd(s: String): Integer;
begin
  s := UpperCase(s);
  if s = 'SW_HIDE' then
    result := SW_HIDE
  else if s = 'SW_MAXIMIZE' then
    result := SW_MAXIMIZE
  else if s = 'SW_MINIMIZE' then
    result := SW_MINIMIZE
  else if s = 'SW_RESTORE' then
    result := SW_RESTORE
  else if s = 'SW_SHOW' then
    result := SW_SHOW
  else if s = 'SW_SHOWDEFAULT' then
    result := SW_SHOWDEFAULT
  else if s = 'SW_SHOWMAXIMIZED' then
    result := SW_SHOWMAXIMIZED
  else if s = 'SW_SHOWMINIMIZED' then
    result := SW_SHOWMINIMIZED
  else if s = 'SW_SHOWMINNOACTIVE' then
    result := SW_SHOWMINNOACTIVE
  else if s = 'SW_SHOWNA' then
    result := SW_SHOWNA
  else if s = 'SW_SHOWNOACTIVATE' then
    result := SW_SHOWNOACTIVATE
  else if s = 'SW_SHOWNORMAL' then
    result := SW_SHOWNORMAL
  else
    result := -1;
end;

function ExecuteSFXAutoRun(ADirectory: string): TExecuteSFXAutoRunResult;
var
  x: TIniFile;
  Operation, FileName, Parameters, Directory, ShowCmd: string;
  XShowCmd: Integer;
  XOperation, XFileName, XParameters, XDirectory: PChar;
const
  AR = 'AutoRun.inf';
  Section = 'AutoSFX';
begin
  result.AutoRunSectionAvailable := false;
  result.ExecutionSucceed := false;
  result.HInstance := -1;
  result.OpenUnzippedContent := true;

  if not DirectoryExists(ADirectory) then Exit;
  ADirectory := IncludeTrailingPathDelimiter(ADirectory);
  if not FileExists(ADirectory + AR) then Exit;

  x := TIniFile.Create(ADirectory + AR);
  try
    if not x.SectionExists(Section) then Exit;
    result.AutoRunSectionAvailable := true;

    Operation   := x.ReadString(Section, 'Operation',  'open');
    FileName    := x.ReadString(Section, 'FileName',   '');
    if FileName = '' then Exit;
    Parameters  := x.ReadString(Section, 'Parameters', '');
    Directory   := x.ReadString(Section, 'Directory',  '');
    ShowCmd     := x.ReadString(Section, 'ShowCmd',    'SW_NORMAL');

    if UpperCase(Operation) = 'NULL' then
    begin
      XOperation := nil
    end
    else
    begin
      XOperation := PChar(Operation);
    end;
    XFileName   := PChar(FileName);
    XParameters := PChar(Parameters);
    XDirectory  := PChar(Directory);
    XShowCmd    := StrToShowCmd(ShowCmd);

    // Since our application will now terminate, I let the handle be 0.
    result.HInstance := ShellExecute(0, XOperation, XFileName, XParameters, XDirectory, XShowCmd);
    result.ExecutionSucceed := result.HInstance > 32;

    result.OpenUnzippedContent := x.ReadBool(Section, 'OpenUnzippedContent', true)
  finally
    x.Free;
  end;
end;

end.
