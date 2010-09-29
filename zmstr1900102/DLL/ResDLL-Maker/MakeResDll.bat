@echo off

REM by ViaThinkSoft

IF EXIST ZMRes19_dll.res del ZMRes19_dll.res
IF EXIST DelZip190_upx.dll del DelZip190_upx.dll
call ..\..\..\Tools\upx -9 -o DelZip190_upx.dll ..\DelZip190.dll
type dllverprefix.bin > DZRESDLL19.bin
type DelZip190_upx.dll >> DZRESDLL19.bin
del DelZip190_upx.dll
brcc32 ZMRes19_dll.rc
del DZRESDLL19.bin
