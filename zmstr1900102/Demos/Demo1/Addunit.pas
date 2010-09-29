Unit Addunit;
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
{$IFDEF VERD6up}
{$WARN UNIT_PLATFORM OFF}
{$WARN SYMBOL_PLATFORM OFF}
{$ENDIF}

Interface

Uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, FileCtrl, ExtCtrls, Menus, ShlObj;

Type
  TAddForm = Class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    Panel6: TPanel;
    Panel7: TPanel;
    Panel8: TPanel;
    DriveComboBox1: TDriveComboBox;
    FileListBox1: TFileListBox;
    DirectoryListBox1: TDirectoryListBox;
    OKBut: TButton;
    AddBtn: TButton;
    SortBut: TButton;
    RemoveBut: TButton;
    CancelBut: TButton;
    AddDirBut: TButton;
    VolSizeBut: TButton;
    AddFileBut: TButton;
    FreeDisk1But: TButton;
    SelectAllBut: TButton;
    SelectedList: TListBox;
    Label1: TLabel;
    Label2: TLabel;
    DirNameCB: TCheckBox;
    RecurseCB: TCheckBox;
    EncryptCB: TCheckBox;
    DiskSpanCB: TCheckBox;
    Bevel1: TBevel;
    PopupMenu1: TPopupMenu;
    Add1: TMenuItem;
    Update1: TMenuItem;
    Freshen1: TMenuItem;
    Move1: TMenuItem;
    AtribOnlyCB: TCheckBox;
    AtribResetCB: TCheckBox;
    FreeDiskAllBut: TButton;

    Procedure OKButClick(Sender: TObject);
    Procedure CancelButClick(Sender: TObject);
    Procedure AddFileButClick(Sender: TObject);
    Procedure SortButClick(Sender: TObject);
    Procedure RemoveButClick(Sender: TObject);
    Procedure SelectAllButClick(Sender: TObject);
    Procedure FormCreate(Sender: TObject);
    Procedure AddDirButClick(Sender: TObject);
    Procedure AddBtnClick(Sender: TObject);
    Procedure Add1Click(Sender: TObject);
    Procedure VolSizeButClick(Sender: TObject);
    Procedure FreeDiskAllButClick(Sender: TObject);
    Procedure DiskSpanCBClick(Sender: TObject);

  PUBLIC
    { Public declarations }
    ZipAction: Integer;
  End;

Var
  AddForm: TAddForm;
  InMouseClick: Boolean;

Implementation

Uses mainunit;
{$R *.DFM}

Procedure TAddForm.OKButClick(Sender: TObject);
Begin
  mainunit.Canceled := False;
  Close;
End;

Procedure TAddForm.CancelButClick(Sender: TObject);
Begin
  mainunit.Canceled := True;
  Close;
End;

Procedure TAddForm.SortButClick(Sender: TObject);
Begin
  SelectedList.Sorted := True;
  SortBut.Enabled := False; { list will remain sorted }
End;

Procedure TAddForm.RemoveButClick(Sender: TObject);
Var
  i: Integer;
Begin
  For i := SelectedList.Items.Count - 1 Downto 0 Do
  Begin
    If SelectedList.Selected[i] Then
      SelectedList.Items.Delete(i);
  End;
End;

Procedure TAddForm.SelectAllButClick(Sender: TObject);
Var
  i: Integer;
Begin
  For i := 0 To FileListBox1.Items.Count - 1 Do
    FileListBox1.Selected[i] := True;
End;

Procedure TAddForm.FormCreate(Sender: TObject);
Var
  SpecFolder: String;
Begin
  SpecFolder := '';

  MainForm.GetSpecialFolder(CSIDL_DESKTOPDIRECTORY, SpecFolder);
  DriveComboBox1.Drive := ExtractFileDrive(SpecFolder)[1];
  DirectoryListBox1.Directory := ExtractFilePath(SpecFolder);
  InMouseClick := False;
End;

Procedure TAddForm.AddDirButClick(Sender: TObject);
Var
  i: Integer;
  FullName: String;
Begin
  mainunit.Canceled := True; // default
  For i := 0 To DirectoryListBox1.Items.Count - 1 Do
  Begin
    If DirectoryListBox1.Selected[i] Then
    Begin
      // Add this file if it isn't already in listbox
      FullName := MainForm.ZipMaster1.AppendSlash(DirectoryListBox1.Directory)
        + '*.*';

      If SelectedList.Items.IndexOf(FullName) < 0 Then
        SelectedList.Items.Add(FullName);
      { Never de-select dirnames from the DirectoryList! }
      { DirectoryListBox1.Selected[i]:=False; }
    End;
  End;
  { Position the "SelectedList" listbox at the bottom }
  With SelectedList Do
  Begin
    Selected[Items.Count - 1] := True;
    Selected[Items.Count - 1] := False;
  End;
End;

Procedure TAddForm.AddFileButClick(Sender: TObject);
Var
  i: Integer;
  FullName: String;
Begin
  mainunit.Canceled := True; // default
  For i := 0 To FileListBox1.Items.Count - 1 Do
  Begin
    If FileListBox1.Selected[i] Then
    Begin
      // Add this file if it isn't already in listbox
      FullName := MainForm.ZipMaster1.AppendSlash(DirectoryListBox1.Directory)
        + FileListBox1.Items[i];
      If SelectedList.Items.IndexOf(FullName) < 0 Then
        SelectedList.Items.Add(FullName);
      FileListBox1.Selected[i] := False;
    End;
  End;
  { Position the "SelectedList" listbox at the bottom }
  With SelectedList Do
  Begin
    Selected[Items.Count - 1] := True;
    Selected[Items.Count - 1] := False;
  End;
End;

Procedure TAddForm.AddBtnClick(Sender: TObject);
Var
  pt: TPoint;
Begin
  pt.x := 4;
  pt.y := 4;
  pt := AddBtn.ClientToScreen(pt);
  PopupMenu1.Popup(pt.x, pt.y);
End;

Procedure TAddForm.Add1Click(Sender: TObject);
Begin
  ZipAction := TMenuItem(Sender).Tag;
  TMenuItem(Sender).Checked := True;
  TMenuItem(Sender).Default := True;
  AddBtn.Caption := 'Action: ' + TMenuItem(Sender).Caption;
End;

Procedure TAddForm.VolSizeButClick(Sender: TObject);
Begin
  MainForm.ZipMaster1.MaxVolumeSize := StrToIntDef(InputBox('Max Vol size',
      'Maximum size of an archive part', IntToStr
        (MainForm.ZipMaster1.MaxVolumeSize)), 0);
End;

Procedure TAddForm.FreeDiskAllButClick(Sender: TObject);
Begin
  MainForm.ZipMaster1.KeepFreeOnAllDisks := StrToIntDef
    (InputBox('Keep free on All Disks', 'Unused bytes on all disks', IntToStr
        (MainForm.ZipMaster1.KeepFreeOnAllDisks)), 0);
End;

Procedure TAddForm.DiskSpanCBClick(Sender: TObject);
Begin
  VolSizeBut.Enabled := DiskSpanCB.Checked;
  FreeDisk1But.Enabled := DiskSpanCB.Checked;
End;

End.
