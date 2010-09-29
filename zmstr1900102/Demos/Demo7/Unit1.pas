unit Unit1;
// Demo for reading from Zip Stream by Nikolaj Olsson (nikse@e-mail.dk)
// amended April 11, 2005 R.Peters
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
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, StdCtrls, Buttons, ZipMstr19;

type
  TForm1 = class(TForm)
    Image1: TImage;
    StaticText1: TStaticText;
    BtnPic1: TButton;
    BtnPic2: TButton;
    BtnPic3: TButton;
    procedure UnzipToImage(filename : string);
    procedure BtnPic3Click(Sender: TObject);
    procedure BtnPic1Click(Sender: TObject);
    procedure BtnPic2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    ZipMaster1: TZipMaster19;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
//  Stream1 : TZipstream;

implementation

{$R *.DFM}

procedure TForm1.UnzipToImage(filename : string);
var
  Stream1: TMemoryStream;
begin
  if not ZipMaster1.{Unz}Busy then
  begin
    ZipMaster1.ZipFileName:= 'resource.zip';
    if ZipMaster1.Count > 0 then
    begin
      ZipMaster1.Password:='password';
      Stream1 := ZipMaster1.ExtractFileToStream(filename);
      if Stream1 <> nil then
      begin
        Stream1.Position := 0;      // reset to the beginning of the stream
        StaticText1.Caption:='File Size: '+ IntToStr(Stream1.Size);
        Image1.Picture.Bitmap.LoadFromStream(Stream1);
      end
      else
        StaticText1.Caption:='extraction error';
    end
    else
      StaticText1.Caption:='resource.zip not found or empty';
  end;
end;

procedure TForm1.BtnPic3Click(Sender: TObject);
begin
  UnzipToImage('eye.bmp');
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  ZipMaster1 := TZipMaster19.Create(self);
  ZipMaster1.DLLDirectory := '..\..\DLL\';
end;

procedure TForm1.BtnPic1Click(Sender: TObject);
begin
  UnzipToImage('paintbrush.bmp');
end;

procedure TForm1.BtnPic2Click(Sender: TObject);
begin
  UnzipToImage('Spectrum.bmp');
end;

end.
