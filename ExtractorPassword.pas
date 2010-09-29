unit ExtractorPassword;

{$WARN UNIT_PLATFORM OFF}

interface

uses
  Forms, Controls, StdCtrls, Classes, FileCtrl, SysUtils;

type
  TPasswordDlg = class(TForm)
    PwEnterLabel: TLabel;
    Password: TEdit;
    OKBtn: TButton;
    CancelBtn: TButton;
    FileLabel: TLabel;
    CurrentFileLabel: TLabel;
    TryLabel: TLabel;
    procedure OKBtnClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  public
    function ShowModal(Filename: String; TryNo, MaxTries: Integer): Integer; reintroduce;
  end;

var
  PasswordDlg: TPasswordDlg;

implementation

{$R *.dfm}

procedure TPasswordDlg.FormShow(Sender: TObject);
begin
  Password.Text := '';
  Password.SetFocus;
end;

procedure TPasswordDlg.OKBtnClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

function TPasswordDlg.ShowModal(Filename: String; TryNo, MaxTries: Integer): Integer;
resourcestring
  Lng_Try = 'Versuch %d / %d';
begin
  CurrentFileLabel.Caption := MinimizeName(Filename, CurrentFileLabel.Canvas, CurrentFileLabel.Width);
  TryLabel.Caption := Format(Lng_Try, [TryNo, MaxTries]);
  result := inherited ShowModal;
end;

end.

