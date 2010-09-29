unit ExtractorError;

interface

// TODO: Dialog sizeable

uses
  Forms, StdCtrls, ExtCtrls, Controls, Graphics, Classes;

type
  TErrorForm = class(TForm)
    ErrorList: TListBox;
    ErrorImg: TImage;
    ErrorLabel: TLabel;
    OKBtn: TButton;
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

procedure TErrorForm.NewError(Filename: string);
begin
  // In future: Also add reason into list?
  ErrorList.Items.Add(Filename);
end;

end.
