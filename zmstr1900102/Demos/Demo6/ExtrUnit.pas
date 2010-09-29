unit ExtrUnit;
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


interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, FileCtrl;

type
  TExtract = class( TForm )
    Panel1:            TPanel;
    Panel2:            TPanel;
    Panel3:            TPanel;
    DirectoryListBox1: TDirectoryListBox;
    DriveComboBox1:    TDriveComboBox;
    OKBut:             TButton;
    CancelBut:         TButton;
    RadioGroup1:       TRadioGroup;
    RadioGroup2:       TRadioGroup;

    procedure OKButClick( Sender: TObject );
    procedure FormActivate( Sender: TObject );
    procedure CancelButClick( Sender: TObject );
  end;

var
  Extract: TExtract;

implementation

uses Main;

{$R *.DFM}

procedure TExtract.OKButClick( Sender: TObject );
begin
   Main.Canceled   := False;
   Main.ExtractDir := DirectoryListBox1.Directory;
   if RadioGroup1.ItemIndex = 0 then
      Main.ExpandDirs := False
   else
      Main.ExpandDirs := True;
   if RadioGroup2.ItemIndex = 0 then
      Main.Overwr     := False
   else
      Main.Overwr     := True;
   Main.AllFiles   := True;
   Close;
end;

procedure TExtract.CancelButClick( Sender: TObject );
begin
   Main.ExtractDir := '';
   Close;
end;

procedure TExtract.FormActivate( Sender: TObject );
begin
   Main.Canceled := True; { default }
end;

end.
