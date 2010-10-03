unit ExtractorError;

interface

uses
  Forms, StdCtrls, ExtCtrls, Controls, Graphics, Classes, Dialogs;

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
    procedure NewError(Filename: string);
  end;

var
  ErrorForm: TErrorForm;

implementation

{$R *.dfm}

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

procedure TErrorForm.NewError(Filename: string);
begin
  // In future: Also add reason into list?
  ErrorList.Items.Add(Filename);
end;

procedure TErrorForm.SaveBtnClick(Sender: TObject);
begin
  if SaveDialog.Execute then
  begin
    ErrorList.Items.SaveToFile(SaveDialog.FileName);
  end;
end;

end.
