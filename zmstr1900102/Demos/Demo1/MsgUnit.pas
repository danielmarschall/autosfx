Unit msgunit;
(************************************************************************
 Copyright (C) 2009, 2010  by Russell J. Peters, Roger Aelbrecht,
      Eric W. Engler and Chris Vleghert.

   This file is part of TZipMaster Version 1.9.

    TZipMaster is free software: you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    TZipMaster is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public License
    along with TZipMaster.  If not, see <http://www.gnu.org/licenses/>.

    contact: problems@delphizip.org (include ZipMaster in the subject).
    updates: http://www.delphizip.org
    DelphiZip maillist subscribe at http://www.freelists.org/list/delphizip 
************************************************************************)

{$INCLUDE '..\..\ZipVers19.inc'}

Interface

Uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, ComCtrls;

Type
  TMsgform = Class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    ProgressBar1: TProgressBar;
    FileBeingZipped: TLabel;
    StatusBar1: TStatusBar;
    Button1: TButton;
    Button2: TButton;
    Memo1: TMemo;

    Procedure DismissButClick(Sender: TObject);
    Procedure CancelButClick(Sender: TObject);
    Procedure FormCreate(Sender: TObject);
    Procedure FormResize(Sender: TObject);

  PUBLIC
    { Public declarations }
    FormInitialWidth: Integer;

    ProgressBar2: TProgressBar;
  End;

Var
  Msgform: TMsgform;

Implementation

Uses mainunit;
{$R *.DFM}

Procedure TMsgform.DismissButClick(Sender: TObject);
Begin
  Hide;
End;

Procedure TMsgform.CancelButClick(Sender: TObject);
Begin
  If (MainForm.ZipMaster1.Busy) Then
    MainForm.ZipMaster1.Cancel := True
  Else
    Hide; { nothing to cancel - assume user wants to close msg window }
End;

Procedure TMsgform.FormCreate(Sender: TObject);
Begin
  ProgressBar2 := TProgressBar.Create(StatusBar1); // Parent will delete it.
  ProgressBar1.Smooth := True;
  With ProgressBar2 Do
  Begin
    Parent := StatusBar1;
    Top := 2;
    Left := StatusBar1.Left + StatusBar1.Panels.Items[0]
      .Width + StatusBar1.Panels.Items[1].Width + 2;
    Height := StatusBar1.Height - 2;
    Min := 1;
    Max := 100;
    Smooth := True;
  End;
  FormInitialWidth := Msgform.Width;
End;

Procedure TMsgform.FormResize(Sender: TObject);
Begin
  ProgressBar2.Width := StatusBar1.Width - StatusBar1.Panels.Items[0]
    .Width - StatusBar1.Panels.Items[1].Width - 18;
  ProgressBar1.Width := 177 + (Msgform.Width - FormInitialWidth);
End;

End.
