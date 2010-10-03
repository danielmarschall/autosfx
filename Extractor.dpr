program Extractor;

{
  Warning: Extractor must be small, otherwise WinRAR
  will not recognize the ZIP which is appended to this file.
  So we MUST use UPX in PostBuild!
}

uses
  Forms,
  ExtractorMain in 'ExtractorMain.pas' {MainForm},
  ExtractorPassword in 'ExtractorPassword.pas' {PasswordDlg},
  ExtractorError in 'ExtractorError.pas' {ErrorForm},
  ExtractorComment in 'ExtractorComment.pas' {CommentForm},
  Functions in 'Functions.pas',
  SFXAutoRun in 'SFXAutoRun.pas',
  SFXBehavior in 'SFXBehavior.pas',
  BrowseFolder in 'BrowseFolder.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'ViaThinkSoft AutoSFX Extractor';
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TPasswordDlg, PasswordDlg);
  Application.CreateForm(TErrorForm, ErrorForm);
  Application.CreateForm(TCommentForm, CommentForm);
  Application.Run;
end.
