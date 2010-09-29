unit ExtractorComment;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TCommentForm = class(TForm)
    DescMemo: TMemo;
    OkBtn: TButton;
    CancelBtn: TButton;
    procedure FormResize(Sender: TObject);
  public
    function ShowCommentModal(Comment: string): boolean;
  end;

var
  CommentForm: TCommentForm;

implementation

uses
  SFXBehavior;

{$R *.dfm}

procedure TCommentForm.FormResize(Sender: TObject);
begin
  DescMemo.Width  := ClientWidth  - 2 * DescMemo.Left;
  DescMemo.Height := ClientHeight - 3 * DescMemo.Top - OkBtn.Height;
  CancelBtn.Top   := 2 * DescMemo.Top + DescMemo.Height;
  OkBtn.Top       := CancelBtn.Top;
  OkBtn.Left      := ClientWidth - OkBtn.Width - CancelBtn.Left;
end;

function TCommentForm.ShowCommentModal(Comment: string): boolean;
begin
  DescMemo.Text := TrimRight(StripBehavior(Comment));
  result := ShowModal() = mrOk;
end;

end.
