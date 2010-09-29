unit Main9_1;
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


interface

uses
  Windows, Messages, SysUtils, {Variants,} Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  TForm1 = class(TForm)
	Memo1: TMemo;
    Panel1: TPanel;
    Button1: TButton;
    Button2: TButton;
    procedure FormCreate(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
	{ Private declarations }
	fzip: TThread;
  public
	{ Public declarations }
	property ZipThread: TThread read fzip write fzip;
  end;

var
  Form1: TForm1;

implementation
Uses
	ZThrd;

{$R *.dfm}


procedure TForm1.FormCreate(Sender: TObject);
begin
	fzip := nil;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
	if assigned(fzip) then
		fzip.Terminate
	else
		Memo1.Lines.Add('**** Not Running ****');
end;

procedure TForm1.Button1Click(Sender: TObject);
var sl: TStringList;
begin
	if not assigned(fzip) then
	begin
		sl := TStringList.Create;
		try
			sl.Add('*.pas');
			sl.Add('*.dfm');
			sl.Add('*.bpr');
			fzip := TZipThread.Create('test.zip',sl,Memo1,false);
		finally
			sl.Free;
		end;
	end;
end;

end.

