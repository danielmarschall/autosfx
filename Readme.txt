VIATHINKSOFT AUTOSFX
====================

Benefits
--------

* Compatible with WinRAR and other software (Stub is small enough)
* Compatible with Linux' UnZip (No Warnings!)
* Compatible with AuthentiCode
* Compatible with Windows 7
* Compatible with Windows 95

Current overhead
----------------

458 KB (Delphi 2006)

Cancel
------

Press ESC to cancel.

The program waits 1 second before starting extraction (Prevention of malicious
AutoRun's, which call the creator SFX in an infinite loop)

Structure of a ViaThinkSoft AutoSFX Archive
-------------------------------------------

1. Extractor [UPX'ed]
   includes DelZip190.dll (B4) as Resource
2. ZIP (Offset adjusted)
   File comment includes "ViaThinkSoft AutoSFX Archive"
3. Optional: Authenticode Certificate

Process
-------

1. Extract DelZip DLL into TempDir
2. Extract contents directly
3. Open the extracted data and/or execute special AutoRun.inf (see below)
4. Delete the DLL from TempDir

Behavior
--------

ZIP has 1 file
	=> Extract in the same directory as the SFX
	Is it a directory?
		=> Open the new directory in Windows Explorer
	is it a file?
		=> Open Windows Explorer and select the new file.
ZIP has 2+ files
	=> Create a directory with the name of the SFX and extract into it
	=> Open the new created directory in Windows Explorer

Semantic archive comment
------------------------

The extractor looks into the file comment to determinate the behavior
while unzipping. YOU can influence the behavior when creating your
ZIP files.

Following switches are possible:

  C_ASFX_CB_OVR = 'AutoSFX Conflict Behavior: Overwrite all';
  C_ASFX_CB_NEW = 'AutoSFX Conflict Behavior: Overwrite older';
  C_ASFX_CB_ASK = 'AutoSFX Conflict Behavior: Ask';
  C_ASFX_CB_AVO = 'AutoSFX Conflict Behavior: Avoid';

  C_ASFX_CP_BEF = 'AutoSFX Comment Presentation: Before extracting';
  C_ASFX_CP_AFT = 'AutoSFX Comment Presentation: After extracting';
  C_ASFX_CP_NON = 'AutoSFX Comment Presentation: None';

  C_ASFX_FC_THS = 'AutoSFX Extraction Target: Extract here';
  C_ASFX_FC_DSK = 'AutoSFX Extraction Target: Extract to Desktop';
  C_ASFX_FC_ASK = 'AutoSFX Extraction Target: Choose directory';

Special AutoRun.inf
-------------------

[AutoSFX]
Operation=open			; Part of ShellExecute. Usually 'open' or 'runass' (e.g. for admin privilegies)
FileName=AutoRun.exe		; The filename to be executed
Parameters=			; Optional parameters
Directory=			; Optional Working directory
ShowCmd=			; (See MSDN Reference) Usually WS_NORMAL or WS_HIDE
OpenUnzippedContent=true	; After we have opened the application, should we still show the extracted data in Windows Explorer? (Default behavior if not AutoRun is set)

More information about the first 5 values:
http://msdn.microsoft.com/en-us/library/bb762153(VS.85).aspx


(C) 2010 ViaThinkSoft
