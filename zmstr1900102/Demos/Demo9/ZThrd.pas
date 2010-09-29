unit ZThrd;
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
  Classes, {ZipWrkr,} ZipMstr19, StdCtrls, SysUtils, Messages, Main9_1;


type
  TZipThread = class(TThread)
  private
	{ Private declarations }
	zip: TZipMaster19;
	ftext: string;
	fSpecs: TStrings;
	fName: String;
	fMemo: TMemo;
  err: integer;
  protected
	procedure Execute; override;
	procedure ShowText;
  procedure ZipMessage(Sender: TObject; ErrCode: integer; const Message:
      TZMString);
	procedure CheckTerminate(Sender: TObject; var stop: boolean);
	procedure Finished(Sender: TObject);
  public
	constructor Create(Filename: string; Specs: TStrings; Memo: TMemo; suspended: boolean);
	destructor Destroy; override;      
	procedure AfterConstruction; override;
  end;

implementation

uses
  ZMMsg19;

{ Important: Methods and properties of objects in VCL or CLX can only be used
  in a method called using Synchronize, for example,

      Synchronize(UpdateCaption);

  and UpdateCaption could look like,

    procedure TZipThread.UpdateCaption;
    begin
      Form1.Caption := 'Updated in a thread';
    end; }

{ TZipThread }

// runs own thread
procedure TZipThread.Execute;
begin
  zip.Active := true;
	zip.Add;
  err := zip.ErrCode;
end;

// must run main thread ie via Synchronize
procedure TZipThread.ShowText;
begin
	fMemo.Lines.Add(fText);
end;

procedure TZipThread.ZipMessage(Sender: TObject; ErrCode: integer; const
    Message: TZMString);
begin
	if (ErrCode <> 0) and (ErrCode <> DZ_RES_MISS{767}) then   // ignore missing
	begin
		fText := '('+IntToStr(ErrCode)+') '+Message;
		Synchronize(ShowText);		// in main thread add string to memo
	end  {
	else 	// showing all messages will slow it down
	begin
		fText := Message;
		Synchronize(ShowText);		// in main thread add string to memo
	end }
	;
end;

destructor TZipThread.Destroy;
begin
	zip.Free;
  inherited Destroy;
end;

// stops calls to ProcessMessages & checks for Terminated
procedure TZipThread.CheckTerminate(Sender: TObject; var stop: boolean);
begin
	if Terminated then
		stop := true;
end;

constructor TZipThread.Create(Filename: string; Specs: TStrings; Memo: TMemo; suspended: boolean);
begin
	inherited Create(suspended);
	fName := Filename;
	fSpecs := Specs;
	fMemo := Memo;
	zip := TZipMaster19.Create(nil);	// no owner, so must free
  zip.Active := false;
  zip.NotMainThread := true;
	OnTerminate := Finished;
end;

procedure TZipThread.AfterConstruction;
begin
	zip.OnCheckTerminate := CheckTerminate;
	zip.OnMessage := ZipMessage;
	zip.Unattended := true;  
	zip.ZipFileName := fName;
	zip.FSpecArgs.Assign(fSpecs);
  zip.DLLDirectory := '..\..\dll';
	inherited; 					   
end;

// runs main thread
procedure TZipThread.Finished(Sender: TObject);
begin
	Form1.ZipThread := nil;			// don't allow Cancel
	fMemo.Lines.Add( 'Added '+IntToStr(zip.SuccessCnt)+' files');
	if zip.ErrCode <> 0 then
		fMemo.Lines.Add( 'Error '+IntToStr(zip.ErrCode and $FFFF)+'  '+zip.ErrMessage);
end;


end.

