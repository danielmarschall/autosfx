Unit extrunit;
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

{$I '..\..\zipvers19.inc'}
{$IFDEF VERD6up}
{$WARN UNIT_PLATFORM OFF}
{$WARN SYMBOL_PLATFORM OFF}
{$ENDIF}

Interface

Uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, FileCtrl, ShlObj;

Type
  TExtract = Class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    OKBut: TButton;
    CancelBut: TButton;
    RadioGroup1: TRadioGroup;
    RadioGroup2: TRadioGroup;
    RadioGroup3: TRadioGroup;
    DriveComboBox1: TDriveComboBox;
    DirectoryListBox1: TDirectoryListBox;

    Procedure OKButClick(Sender: TObject);
    Procedure CancelButClick(Sender: TObject);
    Procedure FormActivate(Sender: TObject);
    Procedure FormCreate(Sender: TObject);
  End;

Var
  Extract: TExtract;

Implementation

Uses MainUnit;
{$R *.DFM}

Procedure TExtract.OKButClick(Sender: TObject);
Begin
  MainUnit.Canceled := False;
  MainUnit.ExtractDir := DirectoryListBox1.Directory;
  If RadioGroup1.ItemIndex = 0 Then
    MainUnit.ExpandDirs := False
  Else
    MainUnit.ExpandDirs := True;
  If RadioGroup2.ItemIndex = 0 Then
    MainUnit.Overwr := False
  Else
    MainUnit.Overwr := True;
  If RadioGroup3.ItemIndex = 0 Then
    MainUnit.AllFiles := True
  Else
    MainUnit.AllFiles := False;
  Close;
End;

Procedure TExtract.CancelButClick(Sender: TObject);
Begin
  MainUnit.ExtractDir := '';
  Close;
End;

Procedure TExtract.FormActivate(Sender: TObject);
Begin
  MainUnit.Canceled := True; { default }
End;

Procedure TExtract.FormCreate(Sender: TObject);
Var
  SpecFolder: String;
Begin
  SpecFolder := '';

  MainForm.GetSpecialFolder(CSIDL_DESKTOPDIRECTORY, SpecFolder);
  DriveComboBox1.Drive := ExtractFileDrive(SpecFolder)[1];
  DirectoryListBox1.Directory := ExtractFilePath(SpecFolder);
End;

End.
