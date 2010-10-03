unit ExtractorError;

interface

// TODO: Richtige Ordnerliste mit Icons anzeigen?

uses
  Forms, StdCtrls, ExtCtrls, Controls, Graphics, Classes, Dialogs,
  ZipMstr19, SysUtils;

type
  TErrorForm = class(TForm)
    ErrorList: TListBox;
    ErrorImg: TImage;
    ErrorLabel: TLabel;
    OKBtn: TButton;
    SaveBtn: TButton;
    SaveDialog: TSaveDialog;
    procedure FormResize(Sender: TObject);
    procedure SaveBtnClick(Sender: TObject);
  public
    function ErrorsAvailable: boolean;
    procedure NewError(Filename: string; SkipType: TZMSkipTypes);
  end;

var
  ErrorForm: TErrorForm;

implementation

{$R *.dfm}

function SkipTypeToStr(SkipType: TZMSkipTypes): string;
begin
  case SkipType of
    stOnFreshen:           result := 'stOnFreshen';
    stNoOverwrite:         result := 'stNoOverwrite';
    stFileExists:          result := 'stFileExists';
    stBadPassword:         result := 'stBadPassword';
    stBadName:             result := 'stBadName';
    stCompressionUnknown:  result := 'stCompressionUnknown';
    stUnknownZipHost:      result := 'stUnknownZipHost';
    stZipFileFormatWrong:  result := 'stZipFileFormatWrong';
    stGeneralExtractError: result := 'stGeneralExtractError';
    stUser:                result := 'stUser';
    stCannotDo:            result := 'stCannotDo';
    stNotFound:            result := 'stNotFound';
    stNoShare:             result := 'stNoShare';
    stNoAccess:            result := 'stNoAccess';
    stNoOpen:              result := 'stNoOpen';
    stDupName:             result := 'stDupName';
    stReadError:           result := 'stReadError';
    stSizeChange:          result := 'stSizeChange';
  end;
end;

function TErrorForm.ErrorsAvailable: boolean;
begin
  result := ErrorList.Items.Count > 0;
end;

procedure TErrorForm.FormResize(Sender: TObject);
begin
  ErrorList.Width := ClientWidth - ErrorList.Left - ErrorImg.Left;
  ErrorList.Height := ClientHeight - ErrorList.Top - (2 * ErrorImg.Left + OkBtn.Height);
  OkBtn.Top := ErrorList.Top + ErrorList.Height + ErrorImg.Left;
  OkBtn.Left := ErrorList.Left + ErrorList.Width - OkBtn.Width;
  SaveBtn.Top := OkBtn.Top;
end;

procedure TErrorForm.NewError(Filename: string; SkipType: TZMSkipTypes);
resourcestring
  Lng_Err_Entry = '%s (Grund: %s)';
begin
  // In future: Also add reason into list?
  ErrorList.Items.Add(Format(Lng_Err_Entry, [Filename, SkipTypeToStr(SkipType)]));
end;

procedure TErrorForm.SaveBtnClick(Sender: TObject);
begin
  if SaveDialog.Execute then
  begin
    ErrorList.Items.SaveToFile(SaveDialog.FileName);
  end;
end;

end.
