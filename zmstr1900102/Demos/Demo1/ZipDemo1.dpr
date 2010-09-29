Program zipdemo1;
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


Uses
  Forms,
  msgunit In 'msgunit.pas' { Msgform } ,
  extrunit In 'extrunit.pas' { Extract } ,
  Addunit In 'Addunit.pas' { AddForm } ,
  sfxunit In 'sfxunit.pas' { MakeSFX } ,
  mainunit In 'mainunit.pas' { Mainform } ,
  renunit In 'renunit.pas' { RenForm } ;
{$R *.RES}
{.$R '..\..\Res\ZMRes19_str.res'}
{$R '..\..\Res\ZMRes19_sfx.res'}

Begin
  Application.Initialize;
  Application.Title := 'Zip Demo 1';
  Application.CreateForm(TMainform, Mainform);
  Application.CreateForm(TMsgform, Msgform);
  Application.CreateForm(TExtract, Extract);
  Application.CreateForm(TAddForm, AddForm);
  Application.CreateForm(TMakeSFX, MakeSFX);
  Application.CreateForm(TRenForm, RenForm);
  Application.Run;
End.
