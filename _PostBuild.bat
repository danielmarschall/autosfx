@echo off

rem Here we sign our applications
rem Also, we pack Extractor.exe (which includes DelZip190.dll as resource),
rem so the overhead becomes smaller
rem THIS IS IMPORTANT! If the ZIP-offset is too far away from file start
rem WinRAR will not notice that it is a SFX. Also, the ZIP must be
rem at the end of file, otherwise Linux' UnZip won't find the
rem End-Of-Central-Directory!

call Tools\StripReloc.exe Extractor.exe
call Tools\upx.exe -9 Extractor.exe
call Tools\VTSSign.bat Extractor.exe

call Tools\VTSSign.bat Tools\RemoveSignature.exe

call Tools\VTSSign.bat MakeSFX.exe

rem Remove backup files created by StripReloc
del *.exe.bak

pause.
